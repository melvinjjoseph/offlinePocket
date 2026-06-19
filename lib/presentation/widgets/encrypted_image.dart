import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_providers.dart';

/// Displays an AES-encrypted image file stored on disk.
/// Decryption happens once per path and is cached for the widget's lifetime.
class EncryptedImage extends ConsumerStatefulWidget {
  const EncryptedImage({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  ConsumerState<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends ConsumerState<EncryptedImage> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(imageServiceProvider).decryptToBytes(widget.path);
  }

  @override
  void didUpdateWidget(EncryptedImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _future = ref.read(imageServiceProvider).decryptToBytes(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) {
          return Image.memory(
            snap.data!,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
          );
        }
        if (snap.hasError) {
          return SizedBox(
            height: widget.height,
            width: widget.width,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
