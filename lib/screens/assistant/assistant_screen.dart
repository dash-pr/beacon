import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/llm_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/ai/image_analysis_service.dart';
import '../../services/ai/llm_service.dart';
import '../../services/ai/voice_service.dart';
import '../../services/translation/translation_service.dart';
import 'widgets/assistant_bubble.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  final TranslationService _translationService = TranslationService();
  final ImageAnalysisService _imageAnalysisService = ImageAnalysisService();

  bool _voiceReady = false;
  bool _isListening = false;
  bool _translationReady = false;

  static const _suggestions = [
    'How to stop bleeding?',
    'How to treat a burn?',
    'Earthquake safety tips',
    'What to do with a fracture?',
    'Hypothermia treatment',
    'Caught in avalanche',
    'Lost on hiking trail',
    'Altitude sickness help',
  ];

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      await _voiceService.initialize();
      if (mounted) setState(() => _voiceReady = _voiceService.isAvailable);
    } catch (_) {}
    try {
      await _translationService.initialize();
      if (mounted) setState(() => _translationReady = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _imageAnalysisService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _ask(String question) {
    if (question.trim().isEmpty) return;
    context.read<LlmProvider>().askQuestion(question.trim());
    _controller.clear();
    _scrollToBottom();
  }

  void _startListening() async {
    if (!_voiceReady) return;
    setState(() => _isListening = true);
    await _voiceService.startListening(
      onResult: (text) {
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      },
    );
  }

  void _stopListening() async {
    await _voiceService.stopListening();
    setState(() => _isListening = false);
  }

  Future<void> _translateInput() async {
    if (!_translationReady || _controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    final translated = await _translationService.translate(text);
    _controller.text = '$text\n---\n$translated';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future<void> _openCameraAndAnalyze() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      if (!mounted) return;
      final imagePath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => _CaptureScreen(cameras: cameras),
        ),
      );

      if (imagePath == null || !mounted) return;

      // Show analyzing state
      context.read<LlmProvider>().askQuestion('[Analyzing captured image...]');
      _scrollToBottom();

      final result = await _imageAnalysisService.analyzeImage(imagePath);

      // Translate OCR text if present and translation is available
      String ocrText = result.extractedText;
      if (ocrText.isNotEmpty && _translationReady) {
        try {
          final translated = await _translationService.translate(ocrText);
          if (translated != ocrText) {
            ocrText = '$ocrText\n[Translation: $translated]';
          }
        } catch (_) {}
      }

      // Feed the triage result into the LLM as context
      final description = LlmService().describeTriageResult(
        hazardType: result.hazardType,
        severity: result.severity,
        labels: result.labels,
        extractedText: ocrText,
        actionEn: result.actionEn,
      );

      if (!mounted) return;
      // Replace the "analyzing" message with real analysis
      final llm = context.read<LlmProvider>();
      llm.replaceLastUserMessage('📷 $description');
      llm.askQuestion(description);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  void _sendToChat(String text) {
    final meshProvider = context.read<MeshProvider>();
    final messageProvider = context.read<MessageProvider>();
    final locale = context.read<LocaleProvider>();
    messageProvider.sendTextMessage(text, meshProvider.service);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(locale.t('send_to_chat')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final llm = context.watch<LlmProvider>();
    final locale = context.watch<LocaleProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        // Offline AI badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            border: Border(
              bottom: BorderSide(color: AppColors.outline.withAlpha(60)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.safeGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.offline_bolt, size: 14, color: AppColors.safeGreen),
              ),
              const SizedBox(width: 8),
              Text(
                locale.t('ai_assistant'),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (_translationReady)
                const Icon(Icons.translate, size: 14, color: AppColors.textMuted),
              if (_voiceReady) ...[
                const SizedBox(width: 8),
                const Icon(Icons.mic, size: 14, color: AppColors.textMuted),
              ],
            ],
          ),
        ),

        // Messages
        Expanded(
          child: llm.messages.isEmpty && !llm.isGenerating
              ? _buildSuggestions()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: llm.messages.length + (llm.isGenerating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < llm.messages.length) {
                      final msg = llm.messages[index];
                      return Column(
                        children: [
                          AssistantBubble(
                            text: msg.text,
                            isUser: msg.isUser,
                          ),
                          // "Send to chat" button for AI responses
                          if (!msg.isUser)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: TextButton.icon(
                                  onPressed: () => _sendToChat(msg.text),
                                  icon: const Icon(Icons.send, size: 14),
                                  label: Text(locale.t('send_to_chat'), style: const TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textMuted,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }
                    // Streaming response
                    return AssistantBubble(
                      text: llm.currentResponse,
                      isUser: false,
                      isStreaming: true,
                    );
                  },
                ),
        ),

        // Listening indicator
        if (_isListening)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppColors.primary.withAlpha(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  locale.t('listening'),
                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ],
            ),
          ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.outline.withAlpha(60)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Camera button
                IconButton(
                  onPressed: _openCameraAndAnalyze,
                  icon: const Icon(Icons.camera_alt_outlined, size: 22),
                  color: AppColors.primary,
                  tooltip: locale.t('take_photo'),
                ),
                // Voice input
                GestureDetector(
                  onLongPressStart: _voiceReady ? (_) => _startListening() : null,
                  onLongPressEnd: _voiceReady ? (_) => _stopListening() : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? AppColors.primary.withAlpha(40)
                          : AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening
                          ? AppColors.primary
                          : (_voiceReady ? AppColors.textSecondary : AppColors.textMuted),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Translate button
                if (_translationReady)
                  IconButton(
                    onPressed: _translateInput,
                    icon: const Icon(Icons.translate, size: 20),
                    color: AppColors.textSecondary,
                    tooltip: 'Translate input text',
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: InputDecoration(
                      hintText: locale.t('ask_anything'),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: llm.isGenerating ? null : () => _ask(_controller.text),
                  icon: Icon(
                    Icons.send,
                    color: llm.isGenerating ? AppColors.textMuted : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              context.read<LocaleProvider>().t('ai_assistant'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.read<LocaleProvider>().t('ask_anything'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _capabilityChip(Icons.camera_alt, context.read<LocaleProvider>().t('photo')),
                const SizedBox(width: 8),
                _capabilityChip(Icons.mic, context.read<LocaleProvider>().t('voice')),
                const SizedBox(width: 8),
                _capabilityChip(Icons.translate, context.read<LocaleProvider>().t('translate')),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _ask(s),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _capabilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Simple camera capture screen that returns image path
class _CaptureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const _CaptureScreen({required this.cameras});

  @override
  State<_CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<_CaptureScreen> {
  CameraController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.cameras.first, ResolutionPreset.medium);
    _controller!.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_ready) return;
    final file = await _controller!.takePicture();
    if (mounted) Navigator.of(context).pop(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture for AI Analysis'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          if (_ready && _controller != null)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 4),
                  ),
                  child: const Icon(Icons.camera, size: 32, color: AppColors.surface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
