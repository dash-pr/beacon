import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ImageAnalysisService {
  final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.3),
  );
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Broader hazard mapping — ML Kit returns generic labels
  static const _hazardMapping = {
    // Fire/smoke
    'Fire': 'fire', 'Flame': 'fire', 'Smoke': 'fire', 'Bonfire': 'fire',
    'Explosion': 'fire', 'Wildfire': 'fire',
    // Water/flood
    'Flood': 'flood', 'Water': 'flood', 'River': 'flood', 'Lake': 'flood',
    'Rain': 'flood', 'Storm': 'flood', 'Puddle': 'flood',
    // Medical/injury
    'Wound': 'medical', 'Blood': 'medical', 'Bandage': 'medical',
    'Hospital': 'medical', 'Ambulance': 'medical', 'Medicine': 'medical',
    'First aid': 'medical',
    // Structural/damage
    'Rubble': 'structural', 'Debris': 'structural', 'Building': 'structural',
    'Ruin': 'structural', 'Damage': 'structural', 'Concrete': 'structural',
    'Brick': 'structural', 'Construction': 'structural', 'Wall': 'structural',
    // People (may need help)
    'Person': 'people', 'Crowd': 'people', 'Human': 'people', 'Face': 'people',
    // Vehicles/roads
    'Car': 'vehicle', 'Vehicle': 'vehicle', 'Road': 'vehicle', 'Truck': 'vehicle',
    'Traffic': 'vehicle',
    // Nature/outdoor
    'Mountain': 'outdoor', 'Snow': 'outdoor', 'Tree': 'outdoor', 'Forest': 'outdoor',
    'Rock': 'outdoor', 'Cliff': 'outdoor', 'Trail': 'outdoor', 'Sky': 'outdoor',
    'Landscape': 'outdoor', 'Grass': 'outdoor', 'Plant': 'outdoor',
    // Food/supplies
    'Food': 'supplies', 'Bottle': 'supplies', 'Can': 'supplies',
    // Indoor
    'Room': 'indoor', 'Furniture': 'indoor', 'Table': 'indoor', 'Chair': 'indoor',
  };

  static const _actionText = {
    'fire': {
      'en': 'Fire/smoke detected. Evacuate immediately. Cover nose and mouth. Stay low to avoid smoke inhalation.',
      'ja': '火災/煙を検出しました。直ちに避難してください。鼻と口を覆い、低い姿勢で移動してください。',
    },
    'medical': {
      'en': 'Medical situation detected. Apply pressure to wounds. Elevate injured area. Call for help.',
      'ja': '医療状況を検出しました。傷口を圧迫し、負傷部位を高くしてください。',
    },
    'flood': {
      'en': 'Water/flooding detected. Move to higher ground immediately. Avoid walking in moving water.',
      'ja': '浸水を検出しました。直ちに高台に移動してください。流水の中を歩かないでください。',
    },
    'structural': {
      'en': 'Building/structural damage detected. Do not enter damaged buildings. Watch for aftershocks.',
      'ja': '建物/構造物の損傷を検出しました。損傷した建物に入らないでください。',
    },
    'people': {
      'en': 'People detected in the image. Check if anyone needs assistance.',
      'ja': '画像に人が検出されました。助けが必要な人がいないか確認してください。',
    },
    'vehicle': {
      'en': 'Vehicle/road scene detected. Check for road obstructions or vehicle damage.',
      'ja': '車両/道路の状況を検出しました。道路の障害物や車両の損傷を確認してください。',
    },
    'outdoor': {
      'en': 'Outdoor/mountain scene detected. Be aware of weather conditions, terrain hazards, and your location.',
      'ja': '屋外/山岳の場面を検出しました。天候、地形の危険、現在地に注意してください。',
    },
    'supplies': {
      'en': 'Supplies/food detected. Ensure food safety — discard anything that contacted floodwater or was unrefrigerated over 4 hours.',
      'ja': '食料/物資を検出しました。食品の安全を確認してください。',
    },
    'indoor': {
      'en': 'Indoor scene detected. Check building structure integrity. Identify exits and safe spots under sturdy furniture.',
      'ja': '屋内の場面を検出しました。建物の構造の安全性を確認してください。',
    },
    'unknown': {
      'en': 'Scene analyzed. Describe what you see for more specific guidance.',
      'ja': '場面を分析しました。より具体的なアドバイスのために、見えているものを説明してください。',
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

    // Collect all detected labels
    final detectedLabels = <String>[];
    final hazardCounts = <String, double>{};

    for (final label in labels) {
      detectedLabels.add('${label.label} (${(label.confidence * 100).toInt()}%)');
      final mapped = _hazardMapping[label.label];
      if (mapped != null) {
        hazardCounts[mapped] = (hazardCounts[mapped] ?? 0) + label.confidence;
      }
    }

    // Pick the highest-scoring hazard category
    String hazardType = 'unknown';
    double maxScore = 0;
    for (final entry in hazardCounts.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        hazardType = entry.key;
      }
    }

    // Priority hazards override if present at all
    for (final priority in ['fire', 'medical', 'flood', 'structural']) {
      if (hazardCounts.containsKey(priority)) {
        hazardType = priority;
        maxScore = hazardCounts[priority]!;
        break;
      }
    }

    // Determine severity
    String severity;
    if (hazardType == 'fire' || hazardType == 'medical' || hazardType == 'flood') {
      severity = maxScore >= 0.7 ? 'critical' : 'high';
    } else if (hazardType == 'structural') {
      severity = 'high';
    } else if (maxScore >= 0.5) {
      severity = 'medium';
    } else {
      severity = 'low';
    }

    final actions = _actionText[hazardType] ?? _actionText['unknown']!;

    return TriageResult(
      hazardType: hazardType,
      severity: severity,
      labels: detectedLabels,
      extractedText: recognizedText.text,
      actionEn: actions['en']!,
      actionJa: actions['ja']!,
      confidence: maxScore,
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
