import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/clipboard_service.dart';

class MaskedField extends StatefulWidget {
  final String label;
  final String value;
  final bool isSensitive;

  const MaskedField({
    super.key,
    required this.label,
    required this.value,
    this.isSensitive = false,
  });

  @override
  State<MaskedField> createState() => _MaskedFieldState();
}

class _MaskedFieldState extends State<MaskedField> {
  bool _revealed = false;

  String get _displayValue {
    if (!widget.isSensitive || _revealed) return widget.value;
    final digits = widget.value.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.length >= 12) {
      final last4 = digits.substring(digits.length - 4);
      return '•••• •••• •••• $last4';
    }
    if (widget.value.length <= 4) return '•' * widget.value.length;
    return '${'•' * (widget.value.length - 4)}${widget.value.substring(widget.value.length - 4)}';
  }

  void _copy() {
    if (widget.isSensitive) {
      ClipboardService.copySensitive(widget.value);
    } else {
      Clipboard.setData(ClipboardData(text: widget.value));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isSensitive
              ? '${widget.label} copied — auto-clears after ${ClipboardService.clearDelaySeconds} s'
              : '${widget.label} copied',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displayValue,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        letterSpacing: widget.isSensitive && !_revealed ? 2 : 0,
                      ),
                ),
              ],
            ),
          ),
          if (widget.isSensitive)
            IconButton(
              icon: Icon(_revealed ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _revealed = !_revealed),
              tooltip: _revealed ? 'Hide' : 'Reveal',
            ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: _copy,
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}
