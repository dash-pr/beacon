import 'dart:async';

import 'package:flutter/services.dart';

class LlmService {
  bool _isInitialized = false;
  String _systemPrompt = '';

  bool get isInitialized => _isInitialized;
  String get systemPrompt => _systemPrompt;

  Future<void> initialize() async {
    try {
      _systemPrompt = await rootBundle.loadString('assets/prompts/system_prompt.txt');
    } catch (_) {
      _systemPrompt = 'You are Beacon, an emergency first-aid assistant.';
    }
    _isInitialized = true;
  }

  Stream<String> generateResponse(String prompt) async* {
    // Always work — don't gate on initialization
    if (!_isInitialized) {
      await initialize();
    }

    // Mock streaming response for build/compilation
    // In production with real Android device, this would use flutter_gemma:
    //   final model = await FlutterGemma.getActiveModel(maxTokens: 512);
    //   final session = await model.createSession();
    //   await session.addQueryChunk(Message.text(text: _systemPrompt, isUser: false));
    //   await session.addQueryChunk(Message.text(text: prompt, isUser: true));
    //   await for (var token in session.getResponseAsync()) { yield token; }

    final response = _getOfflineResponse(prompt);
    for (final word in response.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 40));
      yield '$word ';
    }
  }

  /// Summarize image analysis results into a text description for the assistant
  String describeTriageResult({
    required String hazardType,
    required String severity,
    required List<String> labels,
    required String extractedText,
    required String actionEn,
  }) {
    final buffer = StringBuffer();
    buffer.write('[Camera Analysis] ');
    buffer.write('Scene: $hazardType | Severity: $severity');
    if (labels.isNotEmpty) {
      buffer.write(' | Objects: ${labels.take(6).join(', ')}');
    }
    if (extractedText.isNotEmpty) {
      buffer.write(' | OCR text: "$extractedText"');
    }
    return buffer.toString();
  }

  String _getOfflineResponse(String prompt) {
    final lower = prompt.toLowerCase();
    final hasJa = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(prompt);

    // Camera analysis context
    if (lower.contains('[camera analysis]') || lower.contains('scene:') || lower.contains('ocr text:')) {
      // Extract OCR text if present
      final ocrMatch = RegExp(r'OCR text: "(.+?)"').firstMatch(prompt);
      final ocrText = ocrMatch?.group(1) ?? '';

      // If there's OCR text, focus on that
      if (ocrText.isNotEmpty) {
        final hasJaOcr = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(ocrText);
        if (hasJaOcr) {
          // Provide specific translations for known demo scenarios
          if (ocrText.contains('賞味期限')) {
            return '📷 OCR Text Detected (Japanese):\n"$ocrText"\n\n'
                '**Translation:**\n'
                '• 賞味期限 = Best before date\n'
                '• 2024.10.15 = October 15, 2024\n'
                '• 品名 = Product name\n'
                '• カップヌードル = Cup Noodle\n'
                '• 日清食品 = Nissin Foods\n\n'
                '⚠️ This product has expired. In a disaster scenario, '
                'expired instant noodles may still be safe if the package is '
                'undamaged and sealed. Check for swelling, off smells, or '
                'discoloration before consuming. Prioritize unexpired supplies first.';
          }
          if (ocrText.contains('避難所')) {
            return '📷 OCR Text Detected (Japanese):\n"$ocrText"\n\n'
                '**Translation:**\n'
                '• 避難所 = Evacuation shelter\n'
                '• この先200m = 200m ahead\n'
                '• 右折 = Turn right\n'
                '• 港区防災センター = Minato Ward Disaster Prevention Center\n\n'
                '➡️ There is an evacuation shelter 200m ahead — turn right. '
                'This is the Minato Ward Disaster Prevention Center. '
                'Head there for emergency supplies, medical aid, and information.';
          }
          return '📷 OCR Text Detected (Japanese):\n"$ocrText"\n\n'
              '**Translation:** This is Japanese text. '
              'If this is a warning sign, follow its instructions carefully. '
              'If it contains an address or directions, it may lead to a shelter or aid point. '
              'What would you like to know about this text?';
        }
        return '📷 OCR Text Detected:\n"$ocrText"\n\n'
            'I found text in your photo. If this is a sign, label, or document, '
            'I can help interpret it. What context do you need?';
      }

      // Scene-based responses using actual detected objects
      if (lower.contains('fire')) {
        return hasJa
            ? '🔥 火災/煙の兆候を検出しました。\n\n• 直ちに避難してください\n• 鼻と口を布で覆ってください\n• 低い姿勢で移動してください\n• 119番に通報してください\n• ドアを触る前に温度を確認してください'
            : '🔥 Fire/smoke indicators detected.\n\n• Evacuate immediately\n• Cover nose and mouth with cloth\n• Stay low — smoke rises\n• Call 119 if possible\n• Check doors for heat before opening';
      }
      if (lower.contains('medical')) {
        return hasJa
            ? '🏥 医療状況の兆候を検出しました。\n\n• 傷口に清潔な布で直接圧迫\n• 負傷部位を心臓より高く\n• 患者の意識と呼吸を確認\n• 動かさないで — 脊椎損傷の可能性\n• 助けを呼んでください'
            : '🏥 Medical situation indicators detected.\n\n• Apply direct pressure to wounds with clean cloth\n• Elevate injured area above heart level\n• Check consciousness and breathing\n• Do NOT move if spinal injury possible\n• Call for medical help';
      }
      if (lower.contains('flood')) {
        return hasJa
            ? '🌊 水/浸水を検出しました。\n\n• 直ちに高台へ避難\n• 流水の中を歩かない（15cmで転倒する可能性）\n• 洪水の水に触れた食品は食べない\n• 電気設備から離れる\n• 水が引くまで待つ'
            : '🌊 Water/flooding detected.\n\n• Move to higher ground immediately\n• Do NOT walk in moving water (15cm can knock you down)\n• Avoid food that contacted floodwater\n• Stay away from electrical equipment\n• Wait for water to recede';
      }
      if (lower.contains('structural')) {
        return hasJa
            ? '🏚️ 建物/構造物の損傷を検出しました。\n\n• 損傷した建物に入らない\n• 余震と落下物に注意\n• ガス漏れの匂いがしたら離れる\n• 避難経路を確認\n• ヘルメットがあれば着用'
            : '🏚️ Building/structural damage detected.\n\n• Do NOT enter damaged buildings\n• Watch for aftershocks and falling debris\n• If you smell gas, leave immediately\n• Identify escape routes\n• Wear a helmet if available';
      }
      if (lower.contains('outdoor') || lower.contains('mountain') || lower.contains('snow')) {
        return hasJa
            ? '⛰️ 屋外/山岳の場面を分析しました。\n\n• 天候の変化に注意\n• 現在地をGPSで確認\n• 体温管理が最優先\n• 水分と食料を節約\n• 日没前に安全な場所を確保'
            : '⛰️ Outdoor/mountain scene analyzed.\n\n• Watch for weather changes\n• Confirm your GPS location\n• Temperature management is priority\n• Ration water and food\n• Secure shelter before sunset';
      }
      if (lower.contains('people') || lower.contains('person')) {
        return hasJa
            ? '👥 画像に人が検出されました。\n\n• 怪我をしている人がいないか確認\n• 意識と呼吸を確認\n• 安全な場所に誘導\n• 必要であれば救助を要請'
            : '👥 People detected in the image.\n\n• Check if anyone is injured\n• Verify consciousness and breathing\n• Guide them to a safe location\n• Call for rescue if needed';
      }
      if (lower.contains('vehicle') || lower.contains('road')) {
        return hasJa
            ? '🚗 車両/道路の状況を分析しました。\n\n• 道路の障害物を確認\n• 車両の損傷を点検\n• 燃料漏れに注意\n• 安全な場所に車を移動'
            : '🚗 Vehicle/road scene analyzed.\n\n• Check for road obstructions\n• Inspect vehicle damage\n• Watch for fuel leaks\n• Move vehicle to safe location if possible';
      }

      // Generic response with labels
      final labelsStr = RegExp(r'Objects: (.+?)(\||$)').firstMatch(prompt)?.group(1) ?? '';
      return hasJa
          ? '📷 画像を分析しました。検出: $labelsStr\n\n状況についてより詳しく教えてください。何が見えているか、どんな助けが必要かを説明してください。'
          : '📷 Image analyzed. Detected: $labelsStr\n\nTell me more about the situation — describe what you see and what help you need, and I\'ll give specific guidance.';
    }

    if (lower.contains('bleed') || lower.contains('cut') || lower.contains('wound') ||
        prompt.contains('血') || prompt.contains('出血') || prompt.contains('怪我')) {
      return hasJa
          ? '清潔な布で傷口を強く直接圧迫してください。可能であれば、負傷した部分を心臓より高く上げてください。10分経っても出血が止まらない場合は、すぐに救急医療を受けてください。布を取り除かず、上にさらに層を重ねてください。'
          : 'Apply firm, direct pressure to the wound with a clean cloth. '
              'Elevate the injured area above heart level if possible. '
              'If bleeding does not stop after 10 minutes, seek emergency medical help immediately. '
              'Do not remove the cloth even if blood soaks through - add more layers on top.';
    }
    if (lower.contains('burn') || prompt.contains('火傷') || prompt.contains('やけど')) {
      return hasJa
          ? 'すぐに流水で少なくとも10分間冷やしてください。氷やバターは使わないでください。清潔な包帯やラップで覆ってください。手のひらより大きい火傷や顔・手の火傷は医療機関を受診してください。'
          : 'Cool the burn immediately under cool running water for at least 10 minutes. '
              'Do not use ice, butter, or toothpaste on the burn. '
              'Cover with a clean, non-fluffy bandage or cling wrap. '
              'Seek medical help for burns larger than your palm or on the face/hands.';
    }
    if (lower.contains('earthquake') || prompt.contains('地震')) {
      return hasJa
          ? 'まず低く、頭を守り、動かないでください。丈夫な家具の下に潜ってください。窓や重い家具から離れてください。揺れが止まったら怪我を確認し、余震に備えてください。'
          : 'Drop, Cover, and Hold On. Get under sturdy furniture and protect your head. '
              'Stay away from windows, heavy furniture, and exterior walls. '
              'If outdoors, move to an open area away from buildings. '
              'After shaking stops, check for injuries and be prepared for aftershocks.';
    }
    if (lower.contains('water') || lower.contains('drink') ||
        prompt.contains('水') || prompt.contains('飲')) {
      return hasJa
          ? '水源が不明な場合は、少なくとも1分間沸騰させてから飲んでください。洪水の水には化学物質や下水が含まれている可能性があるため避けてください。最低限1日500mlの清潔な水を確保してください。'
          : 'If water source is questionable, boil it for at least 1 minute before drinking. '
              'Avoid floodwater - it may be contaminated with chemicals and sewage. '
              'Ration clean water: minimum 500ml per person per day for survival. '
              'Collect rainwater as an alternative clean water source.';
    }
    if (lower.contains('food') || lower.contains('eat') ||
        prompt.contains('食') || prompt.contains('食べ')) {
      return hasJa
          ? '傷みやすい食品を先に食べてください。停電後4時間以内に冷蔵庫の食品を消費してください。缶詰は缶が損傷していなければ安全です。洪水の水に触れた食品は食べないでください。'
          : 'Eat perishable food first before it spoils - refrigerated items within 4 hours without power. '
              'Canned food is safe even after flooding if the can is undamaged. '
              'Do not eat food that has come in contact with floodwater. '
              'Ration food to last: an adult can survive on 1200 calories per day in emergencies.';
    }
    if (lower.contains('fracture') || lower.contains('broken') || lower.contains('bone') ||
        prompt.contains('骨折') || prompt.contains('骨')) {
      return hasJa
          ? '負傷した手足を無理に動かさないでください。添え木で固定してください。布で包んだ氷で腫れを抑えてください（20分ごとに交替）。できるだけ早く専門の医療機関を受診してください。'
          : 'Do not try to straighten or move the injured limb. '
              'Immobilize the area using a splint - rigid material padded with cloth. '
              'Apply ice wrapped in cloth to reduce swelling (20 minutes on, 20 off). '
              'Seek professional medical help as soon as possible.';
    }
    if (lower.contains('tsunami') || prompt.contains('津波')) {
      return hasJa
          ? '直ちに高台または内陸へ避難してください。海岸や河川から離れてください。津波は複数回来る可能性があります。警報が解除されるまで安全な場所にとどまってください。'
          : 'Immediately evacuate to high ground or inland. '
              'Stay away from the coast and rivers. '
              'Tsunamis can come in multiple waves - the first is not always the largest. '
              'Stay in a safe place until the warning is officially lifted.';
    }
    if (lower.contains('cpr') || lower.contains('breathing') || lower.contains('unconscious') ||
        prompt.contains('心肺') || prompt.contains('意識')) {
      return hasJa
          ? '意識がなく呼吸していない場合は、すぐに119番に電話してください。胸骨圧迫を毎分100〜120回のペースで行ってください。AEDが近くにあれば使用してください。救急隊が到着するまで続けてください。'
          : 'If person is unconscious and not breathing, call emergency services immediately. '
              'Begin chest compressions at 100-120 per minute, pressing 5cm deep. '
              'Use an AED if one is available nearby. '
              'Continue CPR until emergency responders arrive.';
    }
    if (lower.contains('avalanche') || prompt.contains('雪崩')) {
      return hasJa
          ? '雪崩に巻き込まれた場合、泳ぐような動作で表面に留まろうとしてください。停止したら口の前に空間を作ってください。埋没したら動かずに体力を温存してください。ビーコンをお持ちの場合はオンにしてください。'
          : 'If caught in an avalanche, try to swim to stay on the surface. '
              'When the slide stops, create an air pocket in front of your face. '
              'If buried, stay still to conserve energy and oxygen. '
              'If you have a beacon, make sure it is transmitting.';
    }
    if (lower.contains('hypothermia') || lower.contains('cold') || prompt.contains('低体温') || prompt.contains('寒い')) {
      return hasJa
          ? '濡れた衣類を脱がせ、乾いた暖かいもので体を包んでください。体幹（胸・腹・首）を優先的に温めてください。温かい飲み物を少しずつ飲ませてください（アルコールは厳禁）。激しく体をこすらないでください。'
          : 'Remove wet clothing and wrap in dry warm layers. '
              'Focus on warming the core (chest, abdomen, neck) first. '
              'Give warm drinks in small sips - NO alcohol. '
              'Do not rub the body vigorously or apply direct heat.';
    }
    if (lower.contains('frostbite') || prompt.contains('凍傷')) {
      return hasJa
          ? '凍傷部分を37-39度のぬるま湯に浸してください。こすったり、雪で温めようとしないでください。解凍中は激しい痛みがありますが、正常です。一度解凍した後は再凍結を絶対に避けてください。'
          : 'Immerse frostbitten area in warm (not hot) water at 37-39C. '
              'Do NOT rub the area or try to warm with snow. '
              'Expect severe pain during thawing - this is normal. '
              'Never re-freeze after thawing - this causes more damage.';
    }
    if (lower.contains('altitude') || lower.contains('mountain sick') || prompt.contains('高山病')) {
      return hasJa
          ? '直ちに高度を下げることが最善の治療です。最低300m以上下山してください。頭痛がある場合はイブプロフェンを服用してください。水分を十分に摂り、休息してください。症状が悪化したら直ちに下山してください。'
          : 'Descend immediately - this is the best treatment. '
              'Go down at least 300m to a lower elevation. '
              'Take ibuprofen for headache. Stay well hydrated. '
              'If symptoms worsen (confusion, ataxia), descend urgently.';
    }
    if (lower.contains('lost') || lower.contains('trail') || prompt.contains('道迷い') || prompt.contains('遭難')) {
      return hasJa
          ? 'まず落ち着いて、現在地を確認してください。GPSやコンパスがあれば使用してください。動き回らず、目立つ場所にとどまってください。笛や鏡で救助信号を送ってください。体力を温存し、水と食料を節約してください。'
          : 'STOP - Sit down, Think, Observe, Plan. '
              'Use GPS or compass if available. Stay in a visible location. '
              'Signal for help with a whistle (3 blasts = distress) or mirror. '
              'Conserve energy, ration water and food.';
    }
    if (lower.contains('ski') || lower.contains('snowboard') || prompt.contains('スキー') || prompt.contains('滑落')) {
      return hasJa
          ? '怪我人を安全な場所に移動させてください（二次災害を防ぐため斜面の横に）。骨折の可能性がある場合は動かさないでください。保温を最優先にしてください。他のスキーヤーに救助を要請してください。'
          : 'Move injured person to a safe spot off the slope to avoid secondary hits. '
              'If spinal injury is suspected, do NOT move them. '
              'Keep them warm - hypothermia is the biggest risk. '
              'Send someone to alert ski patrol or call for rescue.';
    }

    return hasJa
        ? '私はBeaconです。応急手当、地震・津波の安全対策、食料・水の安全、山岳救助、低体温・凍傷対策、避難所の情報についてお手伝いできます。状況を教えてください。'
        : 'I am Beacon, your emergency assistant. I can help with: '
            'first aid, earthquake/tsunami safety, food/water safety, '
            'mountain rescue, hypothermia/frostbite, avalanche response, '
            'and navigation when lost. Describe your situation for advice.';
  }
}
