import '../../models/alert_model.dart';

class JAlertService {
  List<AlertModel> _alerts = [];

  List<AlertModel> get alerts => _alerts;

  Future<List<AlertModel>> fetchAlerts() async {
    // In production, this would fetch from JMA XML endpoint:
    // https://www.data.jma.go.jp/developer/xml/feed/eqvol.xml
    // and translate via TranslationService
    // For hackathon, return hardcoded sample alerts
    _alerts = AlertModel.getSampleAlerts();
    return _alerts;
  }
}
