import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    final supportProvider = Provider.of<SupportProvider>(context, listen: false);
    await supportProvider.fetchSupportMessages(userId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? textToSend]) async {
    final text = textToSend ?? _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    final supportProvider = Provider.of<SupportProvider>(context, listen: false);

    await supportProvider.sendMessage(userId: userId, text: text);
    _scrollToBottom();
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Clear support chat?', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
          content: const Text('This will delete your message history with support.', style: TextStyle(color: AppColors.muted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final userId = authProvider.currentUser?.id;
                final supportProvider = Provider.of<SupportProvider>(context, listen: false);
                await supportProvider.clearSupportMessages(userId);
                _scrollToBottom();
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final supportProvider = Provider.of<SupportProvider>(context);
    final messages = supportProvider.messages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Support Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear chat',
            onPressed: _showClearChatDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick reply chips bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _QuickReplyChip(label: 'Booking help', onTap: () => _handleSendMessage('Booking help')),
                  _QuickReplyChip(label: 'Payment', onTap: () => _handleSendMessage('Payment help')),
                  _QuickReplyChip(label: 'Cancel a visit', onTap: () => _handleSendMessage('Cancel or reschedule visit')),
                  _QuickReplyChip(label: 'Account', onTap: () => _handleSendMessage('Password or account issue')),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),

            // Messages List
            Expanded(
              child: supportProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet. Send a message below!',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isUser = msg.sender == 'user';
                            return _ChatBubble(
                              text: msg.text,
                              isUser: isUser,
                              createdAt: msg.createdAt,
                            );
                          },
                        ),
            ),

            // Demo notice footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: AppColors.tint,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: AppColors.blue),
                  SizedBox(width: 6),
                  Text(
                    'Demo support chat: replies are automatic.',
                    style: TextStyle(color: AppColors.navy, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Text Field Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.white, size: 18),
                      onPressed: () => _handleSendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(color: AppColors.navy, fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.tint,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: onTap,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String createdAt;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.blue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? AppColors.white : AppColors.navy,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(createdAt),
              style: TextStyle(
                color: isUser ? AppColors.white.withValues(alpha: 0.8) : AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
