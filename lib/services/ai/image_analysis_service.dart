import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ImageAnalysisService {
  final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );
  final TextRecognizer _textRecognizer = TextRecognizer();

  static const _hazardMapping = {
    'Fire': 'fire',
    'Flame': 'fire',
    'Smoke': 'fire',
    'Flood': 'flood',
    'Water': 'flood',
    'Wound': 'medical',
    'Blood': 'medical',
    'Person': 'medical',
    'Rubble': 'structural',
    'Debris': 'structural',
    'Building': 'structural',
  };

  static const _actionText = {
    'fire': {
      'en': 'Evacuate immediately. Cover nose and mouth. Stay low to avoid smoke.',
      'ja': '直ちに避難してください。鼻と口を覆い、煙を避けるため低い姿勢で移動してください。',
    },
    'medical': {
      'en': 'Apply pressure to any wounds. Elevate injured area. Seek medical help.',
      'ja': '傷口を圧迫してください。負傷部位を高くし、医療支援を求めてください。',
    },
    'flood': {
      'en': 'Move to higher ground immediately. Avoid walking in moving water.',
      'ja': '直ちに高台に移動してください。流水の中を歩かないでください。',
    },
    'structural': {
      'en': 'Do not enter damaged buildings. Watch for aftershocks and falling debris.',
      'ja': '損傷した建物に入らないでください。余震と落下物に注意してください。',
    },
  };

  Future<TriageResult> analyzeImage(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));

    // Run labeling and text recognition in parallel
    final results = await Future.wait([
      _labeler.processImage(inputImage),
      _textRecognizer.processImage(inputImage),
    ]);

    final labels = results[0] as List<ImageLabel>;
    final recognizedText = results[1] as RecognizedText;

    // Map labels to hazard types
    String? hazardType;
    double maxConfidence = 0;
    final detectedLabels = <String>[];

    for (final label in labels) {
      detectedLabels.add('${label.label} (${(label.confidence * 100).toInt()}%)');
      final mapped = _hazardMapping[label.label];
      if (mapped != null && label.confidence > maxConfidence) {
        hazardType = mapped;
        maxConfidence = label.confidence;
      }
    }

    // Determine severity from confidence
    String severity;
    if (maxConfidence >= 0.8) {
      severity = 'critical';
    } else if (maxConfidence >= 0.6) {
      severity = 'high';
    } else if (maxConfidence >= 0.4) {
      severity = 'medium';
    } else {
      severity = 'low';
    }

    final actions = _actionText[hazardType ?? 'structural']!;

    return TriageResult(
      hazardType: hazardType ?? 'unknown',
      severity: severity,
      labels: detectedLabels,
      extractedText: recognizedText.text,
      actionEn: actions['en']!,
      actionJa: actions['ja']!,
      confidence: maxConfidence,
    );
  }

  void dispose() {
    _labeler.close();
    _textRecognizer.close();
  }
}

class TriageResult {
  final String hazardType;
  final String severity;
  final List<String> labels;
  final String extractedText;
  final String actionEn;
  final String actionJa;
  final double confidence;

  const TriageResult({
    required this.hazardType,
    required this.severity,
    required this.labels,
    required this.extractedText,
    required this.actionEn,
    required this.actionJa,
    required this.confidence,
  });
}
