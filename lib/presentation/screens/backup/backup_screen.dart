import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/backup_service.dart';
import '../../../domain/entities/card_entry.dart';
import '../../providers/app_providers.dart';
import '../../providers/card_providers.dart';

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
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/octet-stream', name: filename)],
          subject: 'OfflinePocket Backup',
        );
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
    try {
      final service = ref.read(backupServiceProvider);
      final result = await Future(() => service.restore(bytes, password));

      // Write and re-encrypt any images included in the backup.
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

      for (final card in updatedCards) {
        if (existingIds.contains(card.id)) {
          await notifier.updateCard(card);
        } else {
          await notifier.save(card);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Restored ${updatedCards.length} card${updatedCards.length == 1 ? '' : 's'}'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showError(e.toString());
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
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
