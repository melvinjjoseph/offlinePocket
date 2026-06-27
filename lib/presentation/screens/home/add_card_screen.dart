import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/entities/card_entry.dart';
import '../../../domain/entities/document_field.dart';
import '../../providers/app_providers.dart';
import '../../providers/card_providers.dart';
import '../scanner/card_scanner_screen.dart';
import '../../widgets/encrypted_image.dart';
import '../../widgets/fullscreen_gallery.dart';

const _uuid = Uuid();

typedef _Field = ({
  TextEditingController key,
  TextEditingController value,
  bool sensitive,
  bool readOnlyKey,
  FieldType type,
  String? regex,
});

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key, this.initialCard});

  /// When set, the screen operates in edit mode pre-populated from this card.
  final CardEntry? initialCard;

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  String _category = 'creditCard';
  final List<_Field> _fields = [];
  String? _frontPath;
  String? _backPath;
  List<String> _rawOcrLines = [];

  bool _isEditing = false;
  String? _cardId;
  // Paths to delete from disk after a successful save (replaced / removed images).
  final List<String> _pathsToDelete = [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCard;
    if (initial != null) {
      _isEditing = true;
      _cardId = initial.id;
      _category = initial.category;
      _labelController.text = initial.label;
      _frontPath = initial.frontImagePath;
      _backPath = initial.backImagePath;
      for (final f in initial.fields) {
        _fields.add((
          key: TextEditingController(text: f.key),
          value: TextEditingController(text: f.value),
          sensitive: f.isSensitive,
          readOnlyKey: false,
          type: f.type,
          regex: null,
        ));
      }
    } else {
      _populateDefaultFields(AppConfig.fallback);
    }
  }

  void _populateDefaultFields(AppConfig config) {
    for (final f in _fields) {
      f.key.dispose();
      f.value.dispose();
    }
    _fields.clear();
    final catConfig = config.categoryById(_category);
    for (final fc in catConfig?.fields ?? <FieldConfig>[]) {
      _fields.add((
        key: TextEditingController(text: fc.name),
        value: TextEditingController(),
        sensitive: fc.sensitive,
        readOnlyKey: true,
        type: fc.type,
        regex: fc.regex,
      ));
    }
    setState(() {});
  }

  void _addField() {
    setState(() {
      _fields.add((
        key: TextEditingController(),
        value: TextEditingController(),
        sensitive: false,
        readOnlyKey: false,
        type: FieldType.text,
        regex: null,
      ));
    });
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute(builder: (_) => const CardScannerScreen()),
    );
    if (result == null) return;

    setState(() {
      // Schedule any paths being replaced for cleanup after save.
      if (_frontPath != null && _frontPath != result.frontImagePath) {
        _pathsToDelete.add(_frontPath!);
      }
      if (result.backImagePath != null &&
          _backPath != null &&
          _backPath != result.backImagePath) {
        _pathsToDelete.add(_backPath!);
      }

      _frontPath = result.frontImagePath;
      // In edit mode keep the existing back image if the user skipped re-scanning it.
      _backPath = result.backImagePath ?? (_isEditing ? _backPath : null);
      _rawOcrLines = result.extraction.rawLines;

      for (final extracted in result.extraction.fields) {
        final keyLower = extracted.key.toLowerCase();
        final existing =
            _fields.where((f) => f.key.text.toLowerCase() == keyLower);
        if (existing.isNotEmpty) {
          existing.first.value.text = extracted.value;
        } else {
          _fields.add((
            key: TextEditingController(text: extracted.key),
            value: TextEditingController(text: extracted.value),
            sensitive: extracted.isSensitive,
            readOnlyKey: false,
            type: extracted.type,
            regex: null,
          ));
        }
      }
    });
  }

  void _removeImage(String path) {
    setState(() {
      _pathsToDelete.add(path);
      if (_frontPath == path) _frontPath = null;
      if (_backPath == path) _backPath = null;
    });
  }

  void _addRawLine(String text) {
    setState(() {
      _fields.add((
        key: TextEditingController(),
        value: TextEditingController(text: text),
        sensitive: false,
        readOnlyKey: false,
        type: FieldType.text,
        regex: null,
      ));
      _rawOcrLines.remove(text);
    });
  }

  void _showRawLineOptions(String text) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('"$text"',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Use as card label'),
              onTap: () {
                _labelController.text = text;
                setState(() => _rawOcrLines.remove(text));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Add as field value'),
              onTap: () {
                Navigator.pop(context);
                _addRawLine(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(_Field f) async {
    final isMonthYear = f.key.text.toLowerCase().contains('expiry');
    if (isMonthYear) {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: DateTime(now.year + 20),
        helpText: 'Select expiry month',
        fieldLabelText: 'Expiry',
      );
      if (picked != null) {
        f.value.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.year.toString().substring(2)}';
        setState(() {});
      }
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
      );
      if (picked != null) {
        f.value.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        setState(() {});
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fields = _fields
        .where((f) => f.key.text.isNotEmpty && f.value.text.isNotEmpty)
        .mapIndexed(
          (i, f) => DocumentField(
            key: f.key.text.trim(),
            value: f.value.text.trim(),
            type: f.type,
            isSensitive: f.sensitive,
          ),
        )
        .toList();

    final card = CardEntry(
      id: _isEditing ? _cardId! : _uuid.v4(),
      category: _category,
      label: _labelController.text.trim(),
      fields: fields,
      createdAt: _isEditing ? widget.initialCard!.createdAt : DateTime.now(),
      frontImagePath: _frontPath,
      backImagePath: _backPath,
    );

    if (_isEditing) {
      await ref.read(cardsNotifierProvider.notifier).updateCard(card);
    } else {
      await ref.read(cardsNotifierProvider.notifier).save(card);
    }

    // Clean up replaced / removed image files after successful DB write.
    for (final path in _pathsToDelete) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _labelController.dispose();
    for (final f in _fields) {
      f.key.dispose();
      f.value.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config =
        ref.watch(appConfigProvider).valueOrNull ?? AppConfig.fallback;
    final categories = config.categories;

    if (!categories.any((c) => c.id == _category)) {
      _category = categories.isNotEmpty ? categories.first.id : 'creditCard';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Card' : 'Add Card'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Scan button ───────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(_isEditing ? 'Re-scan Card' : 'Scan Card'),
            ),
            // ── Scanned images ───────────────────────────────────────────
            if (_frontPath != null || _backPath != null) ...[
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final pages = <(String, String)>[
                  if (_frontPath != null) ('Front', _frontPath!),
                  if (_backPath != null) ('Back', _backPath!),
                ];
                return Row(
                  children: [
                    for (var i = 0; i < pages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _SideThumb(
                        label: pages[i].$1,
                        path: pages[i].$2,
                        onTap: () => openFullscreenGallery(context, pages, i),
                        onRemove: () => _removeImage(pages[i].$2),
                      ),
                    ],
                  ],
                );
              }),
            ],
            const SizedBox(height: 16),
            // ── Category & label ─────────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(c.iconData, size: 18),
                            const SizedBox(width: 8),
                            Text(c.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _category = v);
                // Only reset to defaults if the form is still pristine — no scan
                // data and no manually entered values.
                final hasData = _frontPath != null ||
                    _backPath != null ||
                    _fields.any((f) => f.value.text.isNotEmpty);
                if (!_isEditing && !hasData) _populateDefaultFields(config);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _labelController,
              decoration:
                  const InputDecoration(labelText: 'Label (e.g. My Visa Card)'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Text('Fields', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._fields.asMap().entries.map((e) {
              final i = e.key;
              final f = e.value;
              return _FieldRow(
                field: f,
                index: i,
                onPickDate: () => _pickDate(f),
                onRemove: () => setState(() {
                  f.key.dispose();
                  f.value.dispose();
                  _fields.removeAt(i);
                }),
              );
            }),
            TextButton.icon(
              onPressed: _addField,
              icon: const Icon(Icons.add),
              label: const Text('Add Field'),
            ),
            // ── Unmatched OCR text ────────────────────────────────────────
            if (_rawOcrLines.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.text_snippet_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Detected Text',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(width: 6),
                  Text('(tap to copy to a field)',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _rawOcrLines.map((line) {
                  return ActionChip(
                    label: Text(line,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onPressed: () => _showRawLineOptions(line),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.index,
    required this.onPickDate,
    required this.onRemove,
  });

  final _Field field;
  final int index;
  final VoidCallback onPickDate;
  final VoidCallback onRemove;

  String? _validate(String? v) {
    if (v == null || v.isEmpty) return null;
    final pattern = field.regex;
    if (pattern == null) return null;
    if (!RegExp(pattern).hasMatch(v)) return 'Invalid format';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDate = field.type == FieldType.date;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: field.readOnlyKey
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      field.key.text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : TextFormField(
                    controller: field.key,
                    decoration: const InputDecoration(
                      labelText: 'Field Name',
                      isDense: true,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: field.value,
              readOnly: isDate,
              maxLines: 2,
              minLines: 1,
              onTap: isDate ? onPickDate : null,
              validator: _validate,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Value',
                isDense: true,
                suffixIcon: isDate
                    ? const Icon(Icons.calendar_today, size: 16)
                    : field.sensitive
                        ? const Icon(Icons.lock_outline, size: 16)
                        : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _SideThumb extends StatelessWidget {
  const _SideThumb({
    required this.label,
    required this.path,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final String path;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: EncryptedImage(
                    path: path,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

extension _IndexedMap<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i++, e);
    }
  }
}
