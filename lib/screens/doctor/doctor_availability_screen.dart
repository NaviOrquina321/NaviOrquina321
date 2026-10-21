import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/switch_row.dart';
import '../../data/models/models.dart';
import '../../providers/availability_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final List<String> _weekdaysStr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late List<Availability> _localAvailabilities;
  int _slotLengthMinutes = 30;
  bool _isLoading = true;
  int? _doctorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailability();
    });
  }

  void _loadAvailability() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      final docProvider = Provider.of<DoctorProvider>(context, listen: false);
      await docProvider.fetchDoctorProfileForUser(userId);
      final doc = docProvider.currentDoctorProfile;

      if (doc != null && doc.id != null && mounted) {
        _doctorId = doc.id;
        final availProvider = Provider.of<AvailabilityProvider>(context, listen: false);
        await availProvider.fetchDoctorAvailability(doc.id!);

        if (mounted) {
          setState(() {
            _localAvailabilities = List.from(availProvider.availabilities);
            if (_localAvailabilities.isEmpty) {
              _localAvailabilities = List.generate(
                7,
                (i) => Availability(
                  doctorId: doc.id!,
                  weekday: i + 1,
                  startTime: '09:00',
                  endTime: i == 5 ? '12:00' : '17:00',
                  isEnabled: i <= 5 ? 1 : 0,
                  slotMinutes: 30,
                ),
              );
            } else {
              _slotLengthMinutes = _localAvailabilities.first.slotMinutes;
            }
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final avail = _localAvailabilities[index];
    final currentTimeStr = isStart ? avail.startTime : avail.endTime;
    final parts = currentTimeStr.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _localAvailabilities[index] = avail.copyWith(startTime: formatted);
        } else {
          _localAvailabilities[index] = avail.copyWith(endTime: formatted);
        }
      });
    }
  }

  Future<void> _handleSaveChanges() async {
    if (_doctorId == null) return;

    final updated = _localAvailabilities
        .map((a) => a.copyWith(slotMinutes: _slotLengthMinutes))
        .toList();

    final availProvider = Provider.of<AvailabilityProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final success = await availProvider.saveAvailability(_doctorId!, updated);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Availability changes saved!')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to save changes.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availProvider = Provider.of<AvailabilityProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Working Hours & Availability'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Slot Duration',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              AppChip(
                                label: '15 Minutes',
                                isSelected: _slotLengthMinutes == 15,
                                onTap: () {
                                  setState(() {
                                    _slotLengthMinutes = 15;
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              AppChip(
                                label: '30 Minutes',
                                isSelected: _slotLengthMinutes == 30,
                                onTap: () {
                                  setState(() {
                                    _slotLengthMinutes = 30;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Weekly Schedule',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _localAvailabilities.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final avail = _localAvailabilities[index];
                              final dayName = _weekdaysStr[index];

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      SwitchRow(
                                        title: dayName,
                                        value: avail.isEnabled == 1,
                                        onChanged: (val) {
                                          setState(() {
                                            _localAvailabilities[index] = avail.copyWith(
                                              isEnabled: val ? 1 : 0,
                                            );
                                          });
                                        },
                                      ),
                                      if (avail.isEnabled == 1) ...[
                                        const Divider(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Hours', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                                            Row(
                                              children: [
                                                InkWell(
                                                  onTap: () => _pickTime(index, true),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.tint,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      avail.startTime,
                                                      style: const TextStyle(
                                                        color: AppColors.navy,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text('-'),
                                                ),
                                                InkWell(
                                                  onTap: () => _pickTime(index, false),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.tint,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      avail.endTime,
                                                      style: const TextStyle(
                                                        color: AppColors.navy,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: AppButton(
                      text: 'Save changes',
                      isLoading: availProvider.isLoading,
                      onPressed: _handleSaveChanges,
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: DoctorBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorDashboard);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorPatients);
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, RouteNames.doctorProfileAccount);
          }
        },
      ),
    );
  }
}
