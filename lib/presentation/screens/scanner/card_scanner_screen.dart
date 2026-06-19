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

class _CardScannerScreenState extends ConsumerState<CardScannerScreen> {
  CameraController? _ctrl;
  int _side = 0; // 0 = front, 1 = back
  String? _frontPath;
  String? _backPath;
  bool _cameraReady = false;
  bool _capturing = false;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_side == 0 ? 'Scan Front' : 'Scan Back'),
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
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_ctrl!),
        // Card-shaped guide overlay
        Center(
          child: Container(
            width: 300,
            height: 190,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                _side == 0
                    ? 'Position the FRONT of the card inside the frame'
                    : 'Position the BACK of the card inside the frame',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _capturing ? null : _capture,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: _capturing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white),
                          ),
                  ),
                ),
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
