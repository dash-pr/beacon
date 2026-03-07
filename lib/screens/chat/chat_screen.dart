import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/ai/voice_service.dart';
import '../camera/camera_screen.dart';
import 'dm_screen.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  bool _voiceReady = false;
  bool _isListening = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      await _voiceService.initialize();
      if (mounted) setState(() => _voiceReady = _voiceService.isAvailable);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _tabController.dispose();
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

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final meshProvider = context.read<MeshProvider>();
    final messageProvider = context.read<MessageProvider>();
    messageProvider.sendTextMessage(text, meshProvider.service);
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

  void _sendSos() {
    final locale = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.t('sos_confirm')),
        content: Text(locale.t('sos_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final meshProvider = context.read<MeshProvider>();
              final messageProvider = context.read<MessageProvider>();
              messageProvider.sendTextMessage(
                'SOS — EMERGENCY — I need help at my current location',
                meshProvider.service,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.sosRed),
            child: Text(locale.t('send_sos')),
          ),
        ],
      ),
    );
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Camera Triage')),
          body: const CameraScreen(),
        ),
      ),
    );
  }

  void _openDm(String userId, String userName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DmScreen(userId: userId, userName: userName),
      ),
    );
  }

  void _showNewDmDialog() {
    final messageProvider = context.read<MessageProvider>();
    final users = messageProvider.knownUsers;

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users discovered yet. Send messages in community chat first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start a direct message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ...users.entries.map((entry) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(30),
                child: Text(
                  entry.value.isNotEmpty ? entry.value[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(entry.value, style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(
                'ID: ${entry.key.substring(0, 8)}...',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openDm(entry.key, entry.value);
              },
            )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: 'Community'),
              Tab(text: 'Direct Messages'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCommunityTab(),
              _buildDmTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityTab() {
    final messageProvider = context.watch<MessageProvider>();
    final messages = messageProvider.communityMessages;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_searching, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('No messages yet', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                      SizedBox(height: 4),
                      Text(
                        'Messages sent via BLE mesh will appear here',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: messages[index]);
                  },
                ),
        ),
        // Listening indicator
        if (_isListening)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppColors.primary.withAlpha(20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Listening...', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.outline.withAlpha(60))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // SOS button
                GestureDetector(
                  onTap: _sendSos,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _openCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 22),
                  color: AppColors.primary,
                  tooltip: 'Camera Triage',
                ),
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
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDmTab() {
    final messageProvider = context.watch<MessageProvider>();
    final knownUsers = messageProvider.knownUsers;
    final dmUserIds = messageProvider.dmUserIds;

    // Merge: users with DM history first, then other known users
    final allUserIds = <String>{...dmUserIds, ...knownUsers.keys};

    return Column(
      children: [
        Expanded(
          child: allUserIds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('No users discovered yet', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      const Text(
                        'Users will appear when they send messages\nvia BLE mesh',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: allUserIds.length,
                  itemBuilder: (context, index) {
                    final userId = allUserIds.elementAt(index);
                    final userName = knownUsers[userId] ?? 'Unknown';
                    final dms = messageProvider.dmsWith(userId);
                    final lastMessage = dms.isNotEmpty ? dms.last : null;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withAlpha(30),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage?.content ?? 'Tap to start a conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      trailing: lastMessage != null
                          ? Text(
                              _formatTime(lastMessage.timestamp),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            )
                          : null,
                      onTap: () => _openDm(userId, userName),
                    );
                  },
                ),
        ),
        // New DM button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showNewDmDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Direct Message'),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
