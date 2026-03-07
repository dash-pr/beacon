class AlertModel {
  final String id;
  final String type;
  final String severity;
  final String originalText;
  final String translatedText;
  final String affectedArea;
  final DateTime issuedAt;
  bool isRead;

  AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.originalText,
    required this.translatedText,
    required this.affectedArea,
    required this.issuedAt,
    this.isRead = false,
  });

  static List<AlertModel> getSampleAlerts() {
    return [
      AlertModel(
        id: 'alert_1',
        type: 'earthquake',
        severity: 'severe',
        originalText: '緊急地震速報：東京都23区で震度5強の地震が発生しました。余震に注意してください。安全な場所に避難し、落ち着いて行動してください。',
        translatedText: 'Emergency Earthquake Warning: A magnitude 5+ earthquake has occurred in Tokyo 23 wards. Watch for aftershocks. Evacuate to a safe place and act calmly.',
        affectedArea: 'Tokyo 23 Wards',
        issuedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AlertModel(
        id: 'alert_2',
        type: 'tsunami',
        severity: 'extreme',
        originalText: '大津波警報：東京湾沿岸に大津波警報が発令されました。直ちに高台に避難してください。海岸や河口付近には絶対に近づかないでください。',
        translatedText: 'Major Tsunami Warning: A major tsunami warning has been issued for Tokyo Bay coast. Evacuate to higher ground immediately. Stay away from coastlines and river mouths.',
        affectedArea: 'Tokyo Bay Coast',
        issuedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      AlertModel(
        id: 'alert_3',
        type: 'flood',
        severity: 'moderate',
        originalText: '洪水注意報：荒川流域で水位が上昇しています。低地にお住まいの方は避難の準備をしてください。',
        translatedText: 'Flood Advisory: Water levels are rising in the Arakawa River basin. Residents in low-lying areas should prepare to evacuate.',
        affectedArea: 'Arakawa River Basin',
        issuedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }
}
