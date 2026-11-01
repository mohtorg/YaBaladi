// lib/features/merchant/screens/merchant_reviews_screen.dart
//
// [v2.0 — 2026-10-28] — ENHANCEMENT: Rating Summary, Filters, Merchant Reply Feature

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';

class MerchantReviewsScreen extends StatefulWidget {
  const MerchantReviewsScreen({super.key});

  @override
  State<MerchantReviewsScreen> createState() => _MerchantReviewsScreenState();
}

class _MerchantReviewsScreenState extends State<MerchantReviewsScreen> {
  String _filter = 'all'; // 'all', 'positive', 'negative'

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقييمات'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('ownerId', isEqualTo: auth.uid)
            .limit(1)
            .snapshots(),
        builder: (context, placeSnap) {
          if (placeSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!placeSnap.hasData || placeSnap.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد مكان مرتبط بحسابك'));
          }

          final placeId = placeSnap.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('placeId', isEqualTo: placeId)
                .where('status', isEqualTo: 'published')
                .snapshots(),
            builder: (context, reviewSnap) {
              if (reviewSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!reviewSnap.hasData) {
                return const Center(child: Text('خطأ في تحميل التقييمات'));
              }

              final allDocs = reviewSnap.data!.docs.toList()
                ..sort((a, b) {
                  final aT = a.data()['createdAt'] as Timestamp?;
                  final bT = b.data()['createdAt'] as Timestamp?;
                  if (aT == null) return 1;
                  if (bT == null) return -1;
                  return bT.compareTo(aT);
                });

              if (allDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 80, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text('لا توجد تقييمات بعد',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                );
              }

              // تصفية التقييمات حسب الفلتر المختار
              final filteredDocs = allDocs.where((doc) {
                final rating = (doc.data()['rating'] as num?)?.toInt() ?? 0;
                if (_filter == 'positive') return rating >= 4;
                if (_filter == 'negative') return rating <= 2;
                return true;
              }).toList();

              return Column(
                children: [
                  // ─── ملخص التقييمات ───
                  _RatingSummaryHeader(reviews: allDocs),

                  // ─── فلاتر التقييم ───
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'الكل', theme),
                        const SizedBox(width: 8),
                        _buildFilterChip('positive', 'إيجابي (4-5)', theme),
                        const SizedBox(width: 8),
                        _buildFilterChip('negative', 'سلبي (1-2)', theme),
                      ],
                    ),
                  ),

                  // ─── قائمة التقييمات ───
                  Expanded(
                    child: filteredDocs.isEmpty
                        ? Center(
                            child: Text('لا توجد تقييمات تطابق الفلتر المحدد',
                                style: theme.textTheme.bodyMedium),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              return _ReviewCard(
                                reviewId: doc.id,
                                data: doc.data(),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, ThemeData theme) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.onPrimaryContainer : null,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Rating Summary Header
// ─────────────────────────────────────────────────────────────
class _RatingSummaryHeader extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> reviews;

  const _RatingSummaryHeader({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double totalRating = 0;
    int count5 = 0, count4 = 0, count3 = 0, count2 = 0, count1 = 0;

    for (var doc in reviews) {
      final rating = (doc.data()['rating'] as num?)?.toInt() ?? 0;
      totalRating += rating;
      if (rating == 5)
        count5++;
      else if (rating == 4)
        count4++;
      else if (rating == 3)
        count3++;
      else if (rating == 2)
        count2++;
      else if (rating == 1) count1++;
    }

    final avg = reviews.isEmpty ? 0.0 : totalRating / reviews.length;
    final total = reviews.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < avg.round() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        )),
              ),
              const SizedBox(height: 4),
              Text('$total تقييم', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildBar(5, count5, total, theme),
                _buildBar(4, count4, total, theme),
                _buildBar(3, count3, total, theme),
                _buildBar(2, count2, total, theme),
                _buildBar(1, count1, total, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(int star, int count, int total, ThemeData theme) {
    final progress = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: theme.textTheme.labelSmall),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Review Card with Reply Feature
// ─────────────────────────────────────────────────────────────
class _ReviewCard extends StatefulWidget {
  final String reviewId;
  final Map<String, dynamic> data;

  const _ReviewCard({required this.reviewId, required this.data});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isReplying = false;

  Future<void> _showReplyDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الرد على التقييم'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب ردك هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('إرسال الرد'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isReplying = true);
      try {
        await FirebaseFirestore.instance
            .collection('reviews')
            .doc(widget.reviewId)
            .update({
          'merchantReply': result,
          'merchantReplyAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إرسال الرد بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ فشل إرسال الرد: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isReplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = widget.data['userName']?.toString() ?? 'مستخدم';
    final rating = (widget.data['rating'] as num?)?.toInt() ?? 0;
    final comment = widget.data['comment']?.toString() ?? '';
    final createdAt = (widget.data['createdAt'] as Timestamp?)?.toDate();
    final merchantReply = widget.data['merchantReply']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    userName.isNotEmpty ? userName[0] : '؟',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(comment, style: theme.textTheme.bodyMedium),
            ],
            if (merchantReply != null && merchantReply.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('ردّك:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(merchantReply, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isReplying ? null : _showReplyDialog,
                  icon: _isReplying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.reply, size: 18),
                  label: const Text('رد على التقييم'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
