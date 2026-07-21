import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/ocr/field_extractor.dart';
import '../../../core/ocr/ocr_service.dart';
import '../../providers/card_providers.dart';
import '../../theme/app_theme.dart';

/// Returned to AddCardScreen after both sides are captured + OCR'd.
class ScanResult {
  final String? frontImagePath;
  final String? backImagePath;
  final ExtractionResult extraction;

  const ScanResult({
    this.frontImagePath,
    this.backImagePath,
    required this.extraction,
  });
}

class CardScannerScreen extends ConsumerStatefulWidget {
  const CardScannerScreen({super.key});

  @override
  ConsumerState<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends ConsumerState<CardScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _ctrl;
  int _side = 0; // 0 = front, 1 = back
  String? _frontPath;
  String? _backPath;
  bool _cameraReady = false;
  bool _capturing = false;
  bool _processing = false;
  String? _error;
  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
          ..repeat(reverse: true);
    _initCamera();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _error = 'Camera permission denied.');
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _error = 'No camera found.');
      return;
    }
    final ctrl = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await ctrl.initialize();
    if (!mounted) return;
    setState(() {
      _ctrl = ctrl;
      _cameraReady = true;
    });
  }

  Future<void> _capture() async {
    if (_ctrl == null || !_cameraReady || _capturing) return;
    setState(() => _capturing = true);
    try {
      final img = await _ctrl!.takePicture();
      // Move from camera cache to app private documents (never visible to gallery)
      final docsDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(docsDir.path, 'card_images'));
      await destDir.create(recursive: true);
      final fileName =
          '${_side == 0 ? 'front' : 'back'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dest = p.join(destDir.path, fileName);
      await File(img.path).copy(dest);
      await File(img.path).delete(); // remove camera cache copy
      setState(() {
        if (_side == 0) {
          _frontPath = dest;
        } else {
          _backPath = dest;
        }
        _capturing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Capture failed: $e';
        _capturing = false;
      });
    }
  }

  Future<void> _finish() async {
    setState(() => _processing = true);
    try {
      final ocr = OcrService();
      final buffer = StringBuffer();
      if (_frontPath != null) buffer.writeln(await ocr.extractText(_frontPath!));
      if (_backPath != null) buffer.writeln(await ocr.extractText(_backPath!));
      final extraction = FieldExtractor.extract(buffer.toString());

      // Encrypt image files in-place after OCR (OCR needs plain bytes)
      final imageService = ref.read(imageServiceProvider);
      if (_frontPath != null) await imageService.encryptFile(_frontPath!);
      if (_backPath != null) await imageService.encryptFile(_backPath!);

      if (mounted) {
        Navigator.of(context).pop(ScanResult(
          frontImagePath: _frontPath,
          backImagePath: _backPath,
          extraction: extraction,
        ));
      }
    } catch (e) {
      setState(() {
        _error = 'OCR failed: $e';
        _processing = false;
      });
    }
  }

  void _retake() => setState(() {
        if (_side == 0) {
          _frontPath = null;
        } else {
          _backPath = null;
        }
      });

  void _goToBack() => setState(() {
        _side = 1;
        _backPath = null;
      });

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text('OfflinePocket ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: neon.accent, fontWeight: FontWeight.w700)),
            Text('Scanner',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (_side == 1)
            TextButton(
              onPressed: _finish,
              child:
                  const Text('Skip Back', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: _processing
          ? _buildProcessing()
          : _error != null
              ? _buildError()
              : _side == 0 && _frontPath != null
                  ? _buildPreview(_frontPath!, isFront: true)
                  : _side == 1 && _backPath != null
                      ? _buildPreview(_backPath!, isFront: false)
                      : _buildCamera(),
    );
  }

  Widget _buildCamera() {
    if (!_cameraReady || _ctrl == null) {
      return Center(
          child: CircularProgressIndicator(color: context.neon.accent));
    }
    final neon = context.neon;
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_ctrl!),
        // Neon card-shaped guide with corner brackets + scan line
        Center(
          child: SizedBox(
            width: 320,
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _ScanFramePainter(neon.accent)),
                ),
                AnimatedBuilder(
                  animation: _scanCtrl,
                  builder: (context, _) => Positioned(
                    left: 8,
                    right: 8,
                    top: 8 + (200 - 16) * _scanCtrl.value,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: neon.accent,
                        boxShadow: [
                          BoxShadow(color: neon.accent, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _side == 0
                    ? 'ALIGN THE FRONT OF THE CARD WITHIN THE FRAME'
                    : 'ALIGN THE BACK OF THE CARD WITHIN THE FRAME',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: neon.glowShadow(),
                  ),
                  child: FilledButton.icon(
                    onPressed: _capturing ? null : _capture,
                    icon: _capturing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.document_scanner_outlined),
                    label: Text(_capturing ? 'Capturing…' : 'Scan Card'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.edit_note, color: neon.accent, size: 20),
                label: Text('Enter Details Manually',
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: neon.accent)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Text('ON-DEVICE ENCRYPTED SESSION',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: Colors.white38)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(String path, {required bool isFront}) {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            child: Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54)),
                  onPressed: _retake,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isFront ? _goToBack : _finish,
                  icon: Icon(isFront ? Icons.arrow_forward : Icons.check),
                  label: Text(isFront ? 'Scan Back' : 'Done'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text('Reading card…', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() => _error = null);
              _initCamera();
            },
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Draws four neon L-shaped corner brackets around the scan frame.
class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 28.0;
    const inset = 2.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width, h = size.height;
    // Top-left
    canvas.drawPath(
        Path()
          ..moveTo(inset, inset + arm)
          ..lineTo(inset, inset)
          ..lineTo(inset + arm, inset),
        paint);
    // Top-right
    canvas.drawPath(
        Path()
          ..moveTo(w - inset - arm, inset)
          ..lineTo(w - inset, inset)
          ..lineTo(w - inset, inset + arm),
        paint);
    // Bottom-left
    canvas.drawPath(
        Path()
          ..moveTo(inset, h - inset - arm)
          ..lineTo(inset, h - inset)
          ..lineTo(inset + arm, h - inset),
        paint);
    // Bottom-right
    canvas.drawPath(
        Path()
          ..moveTo(w - inset - arm, h - inset)
          ..lineTo(w - inset, h - inset)
          ..lineTo(w - inset, h - inset - arm),
        paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) => oldDelegate.color != color;
}
