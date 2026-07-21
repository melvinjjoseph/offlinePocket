import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../domain/entities/activity_event.dart';
import '../../../domain/entities/card_entry.dart';
import '../../providers/activity_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/card_providers.dart';

// Top-level so compute() can send it to a background isolate.
// Runs PBKDF2 key derivation + AES-GCM decryption off the main thread.
RestoredBackup _isolateRestore(({Uint8List bytes, String password}) args) =>
    BackupService(CryptoService()).restore(args.bytes, args.password);

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _exportLoading = false;
  bool _restoreLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-start restore if the screen was opened via a .opbackup intent.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(pendingBackupProvider);
      if (pending != null && mounted) {
        _restoreFromBytes(Uint8List.fromList(pending));
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty) {
      _showError('Enter a backup password.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _exportLoading = true);
    try {
      final repo = await ref.read(cardRepositoryProvider.future);
      final cards = await repo.getAll();
      if (cards.isEmpty) {
        _showError('No cards to back up.');
        return;
      }

      // Decrypt any scanned images so they can travel to a new device.
      final imageService = ref.read(imageServiceProvider);
      final images = <String, (Uint8List?, Uint8List?)>{};
      for (final card in cards) {
        Uint8List? front;
        Uint8List? back;
        try {
          if (card.frontImagePath != null) {
            front = await imageService.decryptToBytes(card.frontImagePath!);
          }
        } catch (_) {}
        try {
          if (card.backImagePath != null) {
            back = await imageService.decryptToBytes(card.backImagePath!);
          }
        } catch (_) {}
        if (front != null || back != null) images[card.id] = (front, back);
      }

      final service = ref.read(backupServiceProvider);
      final bytes =
          await Future(() => service.export(cards, password, images: images));

      final now = DateTime.now();
      final filename =
          'offlinepocket_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.opbackup';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      try {
        final result = await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/octet-stream', name: filename)],
          subject: 'OfflinePocket Backup',
        );
        // Backup export is an egress event — the vault left the device.
        if (result.status == ShareResultStatus.success) {
          await ref.read(activityLoggerProvider).log(
                ActivityType.backupExported,
                sensitive: true,
                target: result.raw.isEmpty ? null : result.raw,
              );
        }
      } finally {
        if (await file.exists()) await file.delete();
      }

      if (!mounted) return;
      _passwordController.clear();
      _confirmController.clear();
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  Future<void> _restoreFromBytes(Uint8List bytes) async {
    ref.read(pendingBackupProvider.notifier).state = null;

    final password = await _showPasswordDialog();
    if (password == null || !mounted) return;

    setState(() => _restoreLoading = true);

    // Show a full-screen blocking overlay — the decrypt + image re-encryption
    // can take several seconds and the dialog makes the wait feel intentional.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Restoring backup…'),
              const SizedBox(height: 4),
              Text(
                'Decrypting cards and images',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // PBKDF2 + AES-GCM runs in a background isolate so the spinner animates.
      final result = await compute(
        _isolateRestore,
        (bytes: bytes, password: password),
      );

      final imageService = ref.read(imageServiceProvider);
      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${docsDir.path}/card_images');
      await imagesDir.create(recursive: true);
      const uuid = Uuid();

      final updatedCards = <CardEntry>[];
      for (final card in result.cards) {
        String? frontPath;
        String? backPath;

        final img = result.images[card.id];
        if (img != null) {
          if (img.$1 != null) {
            frontPath = '${imagesDir.path}/${uuid.v4()}.jpg';
            await File(frontPath).writeAsBytes(img.$1!);
            await imageService.encryptFile(frontPath);
          }
          if (img.$2 != null) {
            backPath = '${imagesDir.path}/${uuid.v4()}.jpg';
            await File(backPath).writeAsBytes(img.$2!);
            await imageService.encryptFile(backPath);
          }
        }

        updatedCards.add(CardEntry(
          id: card.id,
          category: card.category,
          label: card.label,
          fields: card.fields,
          createdAt: card.createdAt,
          frontImagePath: frontPath,
          backImagePath: backPath,
        ));
      }

      final repo = await ref.read(cardRepositoryProvider.future);
      final existingIds = (await repo.getAll()).map((c) => c.id).toSet();
      final notifier = ref.read(cardsNotifierProvider.notifier);

      int added = 0;
      int skipped = 0;
      for (final card in updatedCards) {
        if (existingIds.contains(card.id)) {
          skipped++;
        } else {
          await notifier.save(card);
          added++;
        }
      }

      await ref
          .read(activityLoggerProvider)
          .log(ActivityType.backupRestored);

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading dialog

      final msg = skipped == 0
          ? 'Restored $added card${added == 1 ? '' : 's'}'
          : 'Restored $added card${added == 1 ? '' : 's'} · $skipped already on device (skipped)';
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop(); // pop BackupScreen
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _restoreLoading = false);
    }
  }

  Future<String?> _showPasswordDialog() {
    final controller = TextEditingController();
    bool obscure = true;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Enter backup password'),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            autofocus: true,
            onSubmitted: (_) => Navigator.pop(ctx, controller.text),
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setS(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    // Repeated taps must replace the current toast, not queue behind it —
    // otherwise 8 clicks means 8 sequential snackbars.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        // The global snackBarTheme styles content in the cyan accent, which
        // clashes badly on an error surface — override text and border here.
        content: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onErrorContainer),
        ),
        backgroundColor: scheme.errorContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            icon: Icons.shield_outlined,
            title: 'Export Backup',
            body:
                'Save an encrypted copy of all your cards and scanned images. You can restore from this file on any device.',
            child: Column(
              children: [
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Backup password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _exportLoading ? null : _export,
                    icon: _exportLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share),
                    label: const Text('Share backup file'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.restore,
            title: 'Restore Backup',
            body:
                'Open a .opbackup file from Drive, your file manager, or any app — OfflinePocket will detect it automatically and prompt for your password.',
            child: _restoreLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? note;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
    this.note,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: tt.titleMedium?.copyWith(color: cs.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(body,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note!, style: tt.bodySmall?.copyWith(color: cs.outline)),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
