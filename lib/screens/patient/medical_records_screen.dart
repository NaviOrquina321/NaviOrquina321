import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_record_provider.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Visits', 'Prescriptions', 'Results'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
    });
  }

  void _loadRecords() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      Provider.of<MedicalRecordProvider>(context, listen: false).fetchMedicalRecords(
        userId,
        typeFilter: _selectedFilter,
      );
    }
  }

  Future<void> _handleUploadRecord() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null && mounted) {
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      final titleController = TextEditingController(text: fileName);
      String recordType = 'Results';

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Upload Medical Record', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Record Title',
                controller: titleController,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: recordType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'Visits', child: Text('Visits')),
                  DropdownMenuItem(value: 'Prescriptions', child: Text('Prescriptions')),
                  DropdownMenuItem(value: 'Results', child: Text('Results')),
                ],
                onChanged: (val) {
                  if (val != null) recordType = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.id;
        if (userId != null) {
          final recProvider = Provider.of<MedicalRecordProvider>(context, listen: false);
          final success = await recProvider.addMedicalRecord(
            patientId: userId,
            title: titleController.text.trim(),
            type: recordType,
            filePath: filePath,
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Medical record uploaded successfully.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recProvider = Provider.of<MedicalRecordProvider>(context);
    final records = recProvider.records;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Records'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: filter,
                      isSelected: _selectedFilter == filter,
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _loadRecords();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1, color: AppColors.line),

            // Records List
            Expanded(
              child: recProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.folder_open_outlined, size: 56, color: AppColors.muted),
                              SizedBox(height: 12),
                              Text(
                                'No records yet',
                                style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your uploaded files and visit records will appear here.',
                                style: TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: records.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final rec = records[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.tint,
                                  child: Icon(
                                    rec.type == 'prescription'
                                        ? Icons.medication_outlined
                                        : rec.type == 'visit'
                                            ? Icons.calendar_today_outlined
                                            : Icons.description_outlined,
                                    color: AppColors.blue,
                                  ),
                                ),
                                title: Text(
                                  rec.title,
                                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${rec.type.toUpperCase()} • ${_formatDate(rec.createdAt)}',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opening record: ${rec.title}')),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),

            // Upload Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: AppButton(
                text: 'Upload a record',
                icon: Icons.upload_file_outlined,
                onPressed: _handleUploadRecord,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
