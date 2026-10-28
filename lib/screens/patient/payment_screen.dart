import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../providers/appointment_provider.dart';

class PaymentScreen extends StatefulWidget {
  final int appointmentId;

  const PaymentScreen({super.key, required this.appointmentId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'GCash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).fetchAppointmentDetails(widget.appointmentId);
    });
  }

  Future<void> _handleConfirmPayment() async {
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final appt = apptProvider.selectedAppointment;
    if (appt == null) return;

    final isCash = _selectedPaymentMethod == 'Cash at clinic';
    final paymentStatus = isCash ? 'pay at clinic' : 'paid';

    final success = await apptProvider.savePaymentInfo(
      appointmentId: widget.appointmentId,
      paymentMethod: _selectedPaymentMethod,
      paymentStatus: paymentStatus,
      amount: appt.amount,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(
        context,
        RouteNames.bookingConfirmed,
        arguments: widget.appointmentId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final appt = apptProvider.selectedAppointment;
    final currencyFmt = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    final isInPerson = appt?.visitType == 'In person';
    final consultationFee = appt?.amount ?? 500.0;
    final total = consultationFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: apptProvider.isLoading || appt == null
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
                          // Progress Bar
                          Row(
                            children: [
                              Expanded(child: Container(height: 4, color: AppColors.blue)),
                              const SizedBox(width: 4),
                              Expanded(child: Container(height: 4, color: AppColors.blue)),
                              const SizedBox(width: 4),
                              Expanded(child: Container(height: 4, color: AppColors.blue)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Doctor & Date Summary
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  AvatarInitials(name: appt.doctor?.user?.fullName ?? 'Doctor', radius: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appt.doctor?.user?.fullName ?? 'Dr. Medical',
                                          style: const TextStyle(
                                            color: AppColors.navy,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${appt.visitType} • ${appt.date} at ${appt.time}',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Fee Breakdown Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Consultation fee', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                                      Text(currencyFmt.format(consultationFee), style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text('Booking fee', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                                      Text('₱0', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Amount', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(currencyFmt.format(total), style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Pay with',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Payment Option: GCash
                          _buildPaymentTile('GCash', Icons.account_balance_wallet_outlined),

                          // Payment Option: Cash at clinic (In person only)
                          if (isInPerson)
                            _buildPaymentTile('Cash at clinic', Icons.payments_outlined)
                          else
                            Opacity(
                              opacity: 0.5,
                              child: Card(
                                child: ListTile(
                                  leading: const Icon(Icons.payments_outlined, color: AppColors.muted),
                                  title: const Text('Cash at clinic', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                                  subtitle: const Text('Only available for in-person visits', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                  trailing: const Icon(Icons.radio_button_off, color: AppColors.line),
                                ),
                              ),
                            ),

                          // Payment Option: Debit or credit card
                          _buildPaymentTile('Debit or credit card', Icons.credit_card_outlined),

                          const SizedBox(height: 16),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                                SizedBox(width: 6),
                                Text(
                                  'Demo payment, no real charge',
                                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fixed Bottom Payment Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: AppButton(
                      text: 'Pay ${currencyFmt.format(total)} & confirm',
                      isLoading: apptProvider.isLoading,
                      onPressed: _handleConfirmPayment,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentTile(String method, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.blue : AppColors.muted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.blue : AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
