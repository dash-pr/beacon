import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/ai/llm_service.dart';

class LlmProvider extends ChangeNotifier {
  final LlmService _service = LlmService();
  final List<ChatMessage> _messages = [];
  String _currentResponse = '';
  bool _isGenerating = false;
  bool _isInitialized = false;
  StreamSubscription? _responseSubscription;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String get currentResponse => _currentResponse;
  bool get isGenerating => _isGenerating;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    await _service.initialize();
    _isInitialized = _service.isInitialized;
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    if (_isGenerating) return;

    _messages.add(ChatMessage(text: question, isUser: true));
    _currentResponse = '';
    _isGenerating = true;
    notifyListeners();

    _responseSubscription = _service.generateResponse(question).listen(
      (token) {
        _currentResponse += token;
        notifyListeners();
      },
      onDone: () {
        _messages.add(ChatMessage(text: _currentResponse.trim(), isUser: false));
        _currentResponse = '';
        _isGenerating = false;

        // Keep only last 6 turns (12 messages)
        if (_messages.length > 12) {
          _messages.removeRange(0, _messages.length - 12);
        }

        notifyListeners();
      },
      onError: (_) {
        _isGenerating = false;
        notifyListeners();
      },
    );
  }

  void clearConversation() {
    _messages.clear();
    _currentResponse = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _responseSubscription?.cancel();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}
