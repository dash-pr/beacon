import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/llm_provider.dart';
import 'widgets/assistant_bubble.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final llm = context.watch<LlmProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        // Offline AI badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.surfaceLight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.offline_bolt, size: 16, color: AppColors.safeGreen),
              const SizedBox(width: 6),
              const Text(
                'Offline AI - Works without internet',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
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
                  itemCount: llm.messages.length +
                      (llm.isGenerating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < llm.messages.length) {
                      final msg = llm.messages[index];
                      return AssistantBubble(
                        text: msg.text,
                        isUser: msg.isUser,
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

        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.surfaceLight)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: const InputDecoration(
                      hintText: 'Ask about first aid, safety...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed:
                      llm.isGenerating ? null : () => _ask(_controller.text),
                  icon: Icon(
                    Icons.send,
                    color:
                        llm.isGenerating ? AppColors.textMuted : AppColors.accent,
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
            Icon(Icons.smart_toy, size: 48, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text(
              'Beacon AI Assistant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'First aid & disaster guidance - fully offline',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.surfaceLight,
                  side: BorderSide(color: AppColors.accent.withAlpha(80)),
                  onPressed: () => _ask(s),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
