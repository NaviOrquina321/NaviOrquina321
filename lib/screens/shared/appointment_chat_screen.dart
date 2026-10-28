import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class AppointmentChatScreen extends StatefulWidget {
  final int appointmentId;

  const AppointmentChatScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentChatScreen> createState() => _AppointmentChatScreenState();
}

class _AppointmentChatScreenState extends State<AppointmentChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChat();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadChat() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    await apptProvider.fetchAppointmentDetails(widget.appointmentId);
    if (!mounted) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.fetchMessages(widget.appointmentId);
    if (!mounted) return;

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

  Future<void> _handleSendMessage([String? presetText]) async {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(
      appointmentId: widget.appointmentId,
      senderId: userId,
      text: text,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    final appt = apptProvider.selectedAppointment;
    final messages = chatProvider.messages;
    final currentUser = authProvider.currentUser;

    final isDoctor = currentUser?.role == 'doctor';
    final otherName = isDoctor
        ? (appt?.patientUser?.fullName ?? 'Patient')
        : (appt?.doctor?.user?.fullName ?? 'Doctor');

    final isClosed = appt?.status == 'completed' || appt?.status == 'cancelled' || appt?.status == 'declined';

    final quickReplies = isDoctor
        ? ['Arrive 10 min early', 'Join video call', 'Please prepare test results']
        : ['I am on my way', 'Running 5 mins late', 'Where is the room?'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              isClosed ? 'Chat closed' : 'Chat open',
              style: TextStyle(fontSize: 11, color: isClosed ? AppColors.muted : AppColors.blue),
            ),
          ],
        ),
      ),
      body: apptProvider.isLoading || appt == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Quick reply chips
                  if (!isClosed)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: quickReplies.map((reply) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(reply, style: const TextStyle(color: AppColors.navy, fontSize: 12, fontWeight: FontWeight.w600)),
                              backgroundColor: AppColors.tint,
                              side: const BorderSide(color: AppColors.line),
                              onPressed: () => _handleSendMessage(reply),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const Divider(height: 1, color: AppColors.line),

                  // Messages list
                  Expanded(
                    child: chatProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet. Send a message to start chatting!',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final msg = messages[index];
                                  final isMe = msg.senderId == currentUser?.id;
                                  return _MessageBubble(
                                    text: msg.text,
                                    isMe: isMe,
                                    createdAt: msg.createdAt,
                                  );
                                },
                              ),
                  ),

                  // Read-only or Input footer
                  if (isClosed)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppColors.tint,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'This appointment has been completed or cancelled. Chat is read-only.',
                            style: TextStyle(color: AppColors.navy, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          if (!isDoctor) ...[
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: AppColors.white),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.bookAppointment,
                                  arguments: appt.doctorId,
                                );
                              },
                              child: const Text('Book again'),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
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

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String createdAt;

  const _MessageBubble({
    required this.text,
    required this.isMe,
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
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.blue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? AppColors.white : AppColors.navy,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(createdAt),
              style: TextStyle(
                color: isMe ? AppColors.white.withValues(alpha: 0.8) : AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
