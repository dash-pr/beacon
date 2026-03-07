import '../../core/constants/app_config.dart';
import '../../models/message_model.dart';

class SosDetector {
  static Priority detectPriority(String content) {
    int score = 0;
    final lower = content.toLowerCase();

    // Disaster SOS
    for (final kw in AppConfig.japaneseSosKeywords) {
      if (content.contains(kw)) score += 3;
    }
    for (final kw in AppConfig.englishSosKeywords) {
      if (lower.contains(kw)) score += 3;
    }

    // Mountain / hiking SOS
    for (final kw in AppConfig.mountainSosKeywordsJa) {
      if (content.contains(kw)) score += 3;
    }
    for (final kw in AppConfig.mountainSosKeywordsEn) {
      if (lower.contains(kw)) score += 3;
    }

    // Urgent
    for (final kw in AppConfig.urgentKeywords) {
      if (lower.contains(kw)) score += 1;
    }

    if (score >= 5) return Priority.sos;
    if (score >= 2) return Priority.urgent;
    return Priority.normal;
  }
}
