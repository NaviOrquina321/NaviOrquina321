import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  static const String supportEmail = 'support@doctorappointment.app';
  static const String supportPhone = '+18005550199';

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFaqs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFaqs() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUser?.role ?? 'patient';
    Provider.of<SupportProvider>(context, listen: false).fetchFaqs(
      role: role,
      query: _searchController.text,
    );
  }

  Future<void> _handleEmailUs() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final role = user?.role ?? 'patient';
    final name = user?.fullName ?? 'User';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: HelpSupportScreen.supportEmail,
      queryParameters: {
        'subject': 'Support request - ${role.toUpperCase()}',
        'body': 'Hi Support Team,\n\nUser: $name\nRole: $role\nApp Version: 1.0.0\n\nIssue:\n',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      await Clipboard.setData(const ClipboardData(text: HelpSupportScreen.supportEmail));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email address copied to clipboard.')),
        );
      }
    }
  }

  Future<void> _handleCallUs() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: HelpSupportScreen.supportPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Calling isn't available on this device.")),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Calling isn't available on this device.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final supportProvider = Provider.of<SupportProvider>(context);
    final userId = authProvider.currentUser?.id ?? 0;
    final faqs = supportProvider.faqs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _searchController,
                      label: 'Search for help',
                      hint: 'Search questions or keywords...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                      onChanged: (_) => _loadFaqs(),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Common questions',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (faqs.isEmpty) ...[
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted),
                              const SizedBox(height: 12),
                              const Text(
                                'No matching questions found',
                                style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try a different search term or talk with our support team.',
                                style: TextStyle(color: AppColors.muted, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                text: 'Chat with support',
                                onPressed: () {
                                  Navigator.pushNamed(context, RouteNames.supportChat);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: faqs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final faq = faqs[index];
                          return _FaqTile(
                            faq: faq,
                            userId: userId,
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Report a Problem Row
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.tint,
                          child: Icon(Icons.bug_report_outlined, color: AppColors.blue),
                        ),
                        title: const Text(
                          'Report a problem',
                          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Submit a ticket if something isn\'t working right',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                        onTap: () {
                          Navigator.pushNamed(context, RouteNames.reportProblem);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contact Us Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.access_time_rounded, color: AppColors.blue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Support Hours',
                                  style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Mon - Sat, 8:00 AM - 6:00 PM',
                              style: TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                            const Divider(height: 24),
                            InkWell(
                              onTap: _handleCallUs,
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: const [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.tint,
                                    child: Icon(Icons.phone_outlined, color: AppColors.blue, size: 18),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Call us directly',
                                          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        Text(
                                          HelpSupportScreen.supportPhone,
                                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    text: 'Chat with support',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.supportChat);
                    },
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Email us',
                    isSecondary: true,
                    icon: Icons.email_outlined,
                    onPressed: _handleEmailUs,
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

class _FaqTile extends StatefulWidget {
  final FaqItem faq;
  final int userId;

  const _FaqTile({required this.faq, required this.userId});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _checkVote();
  }

  Future<void> _checkVote() async {
    final provider = Provider.of<SupportProvider>(context, listen: false);
    await provider.checkFaqVoteStatus(widget.faq.id, widget.userId);
    if (mounted && provider.votedFaqs[widget.faq.id] == true) {
      setState(() {
        _hasVoted = true;
      });
    }
  }

  Future<void> _vote(bool helpful) async {
    final provider = Provider.of<SupportProvider>(context, listen: false);
    final success = await provider.voteFaq(
      faqId: widget.faq.id,
      userId: widget.userId,
      helpful: helpful,
    );
    if (success && mounted) {
      setState(() {
        _hasVoted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          title: Text(
            widget.faq.question,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            widget.faq.category,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.faq.answer,
                style: const TextStyle(color: AppColors.navy, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.line, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Was this helpful?',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const Spacer(),
                if (_hasVoted) ...[
                  const Text(
                    'Thanks for your feedback!',
                    style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 32),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    onPressed: () => _vote(true),
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.blue),
                    label: const Text('Yes', style: TextStyle(fontSize: 12, color: AppColors.navy)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 32),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    onPressed: () => _vote(false),
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 14, color: AppColors.muted),
                    label: const Text('No', style: TextStyle(fontSize: 12, color: AppColors.navy)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
