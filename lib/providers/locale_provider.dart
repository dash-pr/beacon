import 'package:flutter/foundation.dart';

enum AppLanguage {
  english('en', 'English', 'EN'),
  japanese('ja', '日本語', 'JA'),
  chinese('zh', '中文', 'ZH'),
  korean('ko', '한국어', 'KO');

  final String code;
  final String nativeName;
  final String shortCode;

  const AppLanguage(this.code, this.nativeName, this.shortCode);
}

class LocaleProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  String get code => _language.code;

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  // Simple translation map for UI strings
  String t(String key) {
    return (_strings[_language.code]?[key]) ?? (_strings['en']?[key]) ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'chat': 'Chat',
      'assistant': 'Assistant',
      'map': 'Map',
      'alerts': 'Alerts',
      'forum': 'Forum',
      'responder': 'Responder',
      'community': 'Community',
      'direct_messages': 'Direct Messages',
      'send_sos': 'SOS',
      'sos_confirm': 'Send SOS Alert?',
      'sos_confirm_body': 'This will broadcast an emergency SOS to all nearby devices.',
      'cancel': 'Cancel',
      'send': 'Send',
      'type_message': 'Type a message...',
      'no_messages': 'No messages yet',
      'ble_messages_here': 'Messages sent via BLE mesh will appear here',
      'food_water': 'Food & Water',
      'shelter': 'Shelter',
      'medical': 'Medical',
      'hazard': 'Hazard',
      'report_resource': 'Report Resource',
      'pending': 'Pending',
      'verified': 'Verified',
      'reported_by': 'Reported by',
      'approved_by': 'Approved by',
      'approve': 'Approve',
      'safety_check': 'Safety Check',
      'no_alerts': 'No alerts',
      'disaster_alerts': 'Disaster Alerts',
      'language': 'Language',
    },
    'ja': {
      'chat': 'チャット',
      'assistant': 'アシスタント',
      'map': '地図',
      'alerts': '警報',
      'forum': 'フォーラム',
      'responder': '対応者',
      'community': 'コミュニティ',
      'direct_messages': 'ダイレクトメッセージ',
      'send_sos': 'SOS',
      'sos_confirm': 'SOS警報を送信しますか？',
      'sos_confirm_body': '近くのすべてのデバイスに緊急SOSをブロードキャストします。',
      'cancel': 'キャンセル',
      'send': '送信',
      'type_message': 'メッセージを入力...',
      'no_messages': 'メッセージはまだありません',
      'ble_messages_here': 'BLEメッシュ経由のメッセージがここに表示されます',
      'food_water': '食料・水',
      'shelter': '避難所',
      'medical': '医療',
      'hazard': '危険',
      'report_resource': 'リソースを報告',
      'pending': '保留中',
      'verified': '確認済み',
      'reported_by': '報告者',
      'approved_by': '承認者',
      'approve': '承認',
      'safety_check': '安否確認',
      'no_alerts': '警報なし',
      'disaster_alerts': '災害警報',
      'language': '言語',
    },
    'zh': {
      'chat': '聊天',
      'assistant': '助手',
      'map': '地图',
      'alerts': '警报',
      'forum': '论坛',
      'responder': '响应者',
      'community': '社区',
      'direct_messages': '私信',
      'send_sos': 'SOS',
      'sos_confirm': '发送SOS警报？',
      'sos_confirm_body': '这将向附近所有设备广播紧急SOS。',
      'cancel': '取消',
      'send': '发送',
      'type_message': '输入消息...',
      'no_messages': '暂无消息',
      'ble_messages_here': '通过BLE网格发送的消息将显示在这里',
      'food_water': '食物和水',
      'shelter': '避难所',
      'medical': '医疗',
      'hazard': '危险',
      'report_resource': '报告资源',
      'pending': '待审核',
      'verified': '已验证',
      'reported_by': '报告者',
      'approved_by': '批准者',
      'approve': '批准',
      'safety_check': '安全确认',
      'no_alerts': '没有警报',
      'disaster_alerts': '灾害警报',
      'language': '语言',
    },
    'ko': {
      'chat': '채팅',
      'assistant': '어시스턴트',
      'map': '지도',
      'alerts': '경보',
      'forum': '포럼',
      'responder': '대응자',
      'community': '커뮤니티',
      'direct_messages': '다이렉트 메시지',
      'send_sos': 'SOS',
      'sos_confirm': 'SOS 경보를 보내시겠습니까?',
      'sos_confirm_body': '근처 모든 기기에 긴급 SOS를 방송합니다.',
      'cancel': '취소',
      'send': '전송',
      'type_message': '메시지 입력...',
      'no_messages': '메시지가 없습니다',
      'ble_messages_here': 'BLE 메시를 통해 보낸 메시지가 여기에 표시됩니다',
      'food_water': '식량 및 물',
      'shelter': '대피소',
      'medical': '의료',
      'hazard': '위험',
      'report_resource': '자원 보고',
      'pending': '대기 중',
      'verified': '확인됨',
      'reported_by': '보고자',
      'approved_by': '승인자',
      'approve': '승인',
      'safety_check': '안전 확인',
      'no_alerts': '경보 없음',
      'disaster_alerts': '재난 경보',
      'language': '언어',
    },
  };
}
