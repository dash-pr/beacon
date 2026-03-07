import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/ai/image_analysis_service.dart';
import 'widgets/triage_result_card.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final ImageAnalysisService _analysisService = ImageAnalysisService();
  TriageResult? _triageResult;
  bool _isAnalyzing = false;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(cameras.first, ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {}
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      final image = await _controller!.takePicture();
      final result = await _analysisService.analyzeImage(image.path);
      setState(() {
        _triageResult = result;
        _isAnalyzing = false;
      });
    } catch (_) {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _analysisService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera preview
        if (_cameraReady && _controller != null)
          Positioned.fill(
            child: CameraPreview(_controller!),
          )
        else
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text(
                  'Initializing camera...',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),

        // Triage result overlay
        if (_triageResult != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: TriageResultCard(result: _triageResult!),
          ),

        // Capture button
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _captureAndAnalyze,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _isAnalyzing ? AppColors.urgentOrange : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 4),
                ),
                child: _isAnalyzing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Icon(Icons.camera, size: 32, color: AppColors.surface),
              ),
            ),
          ),
        ),

        // Back / close triage
        if (_triageResult != null)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => setState(() => _triageResult = null),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
      ],
    );
  }
}
