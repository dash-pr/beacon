class AppConfig {
  static const String appName = 'Beacon';
  static const String appTagline = 'When infrastructure fails, people shouldn\'t.';

  // BLE UUIDs
  static const String serviceUuid = '00001234-0000-1000-8000-00805f9b34fb';
  static const String characteristicUuid =
      '00005678-0000-1000-8000-00805f9b34fb';

  // BLE constraints
  static const int maxBlePacketSize = 512;
  static const int maxHopCount = 1;
  static const int maxImageSizeBytes = 50 * 1024; // 50KB

  // Satellite / Starlink
  static const int maxSatellitePayloadBytes = 256;
  static const Duration satelliteSyncInterval = Duration(minutes: 2);
  static const Duration satelliteRetryDelay = Duration(seconds: 30);

  // Safety check
  static const Duration safetyCheckDefaultDuration = Duration(minutes: 30);
  static const Duration safetyCheckDemoDuration = Duration(minutes: 2);

  // LLM
  static const int llmMaxTokens = 512;
  static const int llmMaxConversationTurns = 6;

  // SOS keywords — disaster
  static const List<String> japaneseSosKeywords = [
    '助けて',
    '救助',
    '怪我',
    '火事',
    '危険',
    '死',
    '血',
  ];

  static const List<String> englishSosKeywords = [
    'help',
    'sos',
    'trapped',
    'injured',
    'fire',
    'dying',
    'emergency',
  ];

  // SOS keywords — mountain / hiking / backcountry
  static const List<String> mountainSosKeywordsJa = [
    '遭難',
    '滑落',
    '雪崩',
    '低体温',
    '凍傷',
    '高山病',
    '動けない',
    '道迷い',
  ];

  static const List<String> mountainSosKeywordsEn = [
    'avalanche',
    'hypothermia',
    'frostbite',
    'altitude sickness',
    'lost trail',
    'fallen',
    'stranded',
    'snowstorm',
    'whiteout',
    'crevasse',
  ];

  static const List<String> urgentKeywords = [
    '痛い',
    '病院',
    '水ない',
    'no water',
    'no food',
    'hurt',
    'bleeding',
    'cold',
    '寒い',
    'exhausted',
    '疲労',
  ];

  // Firebase
  static const Duration syncInterval = Duration(seconds: 30);
  static const Duration messagePullWindow = Duration(hours: 2);
}
