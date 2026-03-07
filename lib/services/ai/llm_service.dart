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
    buffer.writeln('Image analysis detected: $hazardType (severity: $severity)');
    if (labels.isNotEmpty) {
      buffer.writeln('Detected: ${labels.take(5).join(', ')}');
    }
    if (extractedText.isNotEmpty) {
      buffer.writeln('Text in image: $extractedText');
    }
    buffer.writeln('Recommended action: $actionEn');
    return buffer.toString();
  }

  String _getOfflineResponse(String prompt) {
    final lower = prompt.toLowerCase();
    final hasJa = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(prompt);

    // Image analysis context
    if (lower.contains('image analysis detected') || lower.contains('detected:')) {
      if (lower.contains('fire') || lower.contains('smoke')) {
        return hasJa
            ? '画像から火災の兆候が確認されました。直ちにその場所から離れてください。鼻と口を布で覆い、低い姿勢で避難してください。119番に通報できる場合は通報してください。'
            : 'The image shows signs of fire. Evacuate the area immediately. Cover your nose and mouth with cloth and stay low to avoid smoke inhalation. Call emergency services (119) if possible.';
      }
      if (lower.contains('medical') || lower.contains('wound') || lower.contains('blood')) {
        return hasJa
            ? '画像から負傷が確認されました。清潔な布で傷口を直接圧迫してください。可能であれば患部を心臓より高くしてください。出血が止まらない場合は直ちに医療機関を受診してください。'
            : 'The image indicates an injury. Apply direct pressure with a clean cloth. Elevate the wounded area above heart level if possible. If bleeding persists, seek emergency medical help immediately.';
      }
      if (lower.contains('flood') || lower.contains('water')) {
        return hasJa
            ? '画像から浸水が確認されました。直ちに高台へ避難してください。流水の中を歩かないでください。水に触れた食品は食べないでください。'
            : 'The image shows flooding. Move to higher ground immediately. Do not walk through moving water. Avoid food that has contacted floodwater.';
      }
      return hasJa
          ? '画像分析の結果を確認しました。安全な場所に移動し、状況が悪化した場合は直ちに避難してください。追加の質問があればお聞きください。'
          : 'I\'ve reviewed the image analysis. Move to a safe location and evacuate immediately if the situation worsens. Feel free to ask me any follow-up questions about the situation.';
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
