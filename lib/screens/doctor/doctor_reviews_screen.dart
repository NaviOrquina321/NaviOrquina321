import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../providers/doctor_provider.dart';

class DoctorReviewsScreen extends StatefulWidget {
  final int doctorId;

  const DoctorReviewsScreen({super.key, required this.doctorId});

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docProvider = Provider.of<DoctorProvider>(context, listen: false);
      docProvider.fetchDoctorDetails(widget.doctorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DoctorProvider>(context);
    final doctor = docProvider.selectedDoctor;
    final reviews = docProvider.doctorReviews;

    final totalReviews = reviews.length;
    final avgRating = doctor?.rating ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Reviews'),
      ),
      body: docProvider.isLoading || doctor == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header rating summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < avgRating.floor()
                                    ? Icons.star_rounded
                                    : (index < avgRating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                color: AppColors.star,
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalReviews ratings',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      const VerticalDivider(width: 1, color: AppColors.line),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: List.generate(5, (index) {
                            final star = 5 - index;
                            final count = reviews.where((r) => r.rating == star).length;
                            final ratio = totalReviews == 0 ? 0.0 : count / totalReviews;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text('$star', style: const TextStyle(fontSize: 12, color: AppColors.navy)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        backgroundColor: AppColors.tint,
                                        color: AppColors.blue,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(ratio * 100).toInt()}%',
                                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'All Reviews',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                const SizedBox(height: 12),

                if (reviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Center(
                      child: Text(
                        'No reviews available yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  ...reviews.map((rev) {
                    final dateStr = rev.createdAt.length >= 10
                        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(rev.createdAt))
                        : rev.createdAt;

                    final tags = rev.tags ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AvatarInitials(name: 'Patient', radius: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Patient Review',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 14),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (idx) {
                                  return Icon(
                                    idx < rev.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: AppColors.star,
                                    size: 16,
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: tags.split(',').map((tag) {
                                final cleanTag = tag.trim();
                                if (cleanTag.isEmpty) return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.tint,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    cleanTag,
                                    style: const TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (rev.comment != null && rev.comment!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              rev.comment!,
                              style: const TextStyle(color: AppColors.navy, fontSize: 13, height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
