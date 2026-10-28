import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'Booking';

  final List<String> _categories = [
    'Booking',
    'Payment',
    'Chat',
    'Video call',
    'Account',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _loadTickets() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      Provider.of<SupportProvider>(context, listen: false).fetchUserTickets(userId);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final supportProvider = Provider.of<SupportProvider>(context, listen: false);
    final ticket = await supportProvider.createSupportTicket(
      userId: userId,
      category: _selectedCategory,
      description: _descController.text,
    );

    if (ticket != null && mounted) {
      _descController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report submitted successfully. Ticket #${ticket.id}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportProvider = Provider.of<SupportProvider>(context);
    final tickets = supportProvider.tickets;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report a Problem'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submit a problem report',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Dropdown
                        const Text(
                          'Category',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: const TextStyle(color: AppColors.navy)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description TextField
                        AppTextField(
                          controller: _descController,
                          label: 'Problem Description',
                          hint: 'Describe the issue you encountered (minimum 10 characters)...',
                          maxLines: 4,
                          validator: (val) {
                            if (val == null || val.trim().length < 10) {
                              return 'Please enter at least 10 characters describing the issue.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        AppButton(
                          text: 'Submit Report',
                          isLoading: supportProvider.isLoading,
                          onPressed: _handleSubmit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'My Reports',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (tickets.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.assignment_turned_in_outlined, size: 40, color: AppColors.muted),
                          SizedBox(height: 8),
                          Text(
                            'No reports yet',
                            style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Any submitted problem reports will appear here.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              '#${ticket.id} • ${ticket.category}',
                              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: ticket.status == 'open' ? AppColors.tint : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ticket.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: ticket.status == 'open' ? AppColors.blue : Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              ticket.description,
                              style: const TextStyle(color: AppColors.navy, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(ticket.createdAt),
                              style: const TextStyle(color: AppColors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
