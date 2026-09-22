// screens/place_reviews_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// شاشة واحدة بتخدم حالتين حسب "isMerchantView":
// - لو أي مستخدم عادي فاتحها: بيشوف التقييمات والردود بس (بدون تعديل)
// - لو التاجر صاحب المكان فاتحها: بيقدر يكتب رد تحت أي تقييم مالوش رد لسه
// استخدام Widget واحد للحالتين بيوفر تكرار كود كبير جدًا
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

class PlaceReviewsScreen extends StatelessWidget {
  final String placeId;
  final bool isMerchantView;

  const PlaceReviewsScreen({
    super.key,
    required this.placeId,
    this.isMerchantView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقييمات والتعليقات'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ratings')
            .where('placeId', isEqualTo: placeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final ratings = snapshot.data!.docs
              .map((doc) => Rating.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // الأحدث أولًا

          if (ratings.isEmpty) {
            return const Center(child: Text('لا توجد تقييمات بعد'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ratings.length,
            itemBuilder: (context, index) => _ReviewCard(
              rating: ratings[index],
              isMerchantView: isMerchantView,
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// الفكرة: بطاقة تقييم واحدة، بتتحول لـ StatefulWidget مستقل
// عشان تقدر تدير حالة "فتح صندوق الرد" لنفسها بدون التأثير على باقي البطاقات
// ------------------------------------------------------------
class _ReviewCard extends StatefulWidget {
  final Rating rating;
  final bool isMerchantView;

  const _ReviewCard({required this.rating, required this.isMerchantView});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isReplying = false;
  final _replyController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    await FirebaseFirestore.instance
        .collection('ratings')
        .doc(widget.rating.id)
        .update({'merchantReply': _replyController.text.trim()});

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final rating = widget.rating;
    final hasReply = rating.merchantReply != null && rating.merchantReply!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < rating.stars ? Icons.star : Icons.star_border,
                  color: const Color(0xFFD4AF37),
                  size: 18,
                );
              }),
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rating.comment!),
            ],

            // ------------------------------------------------------------
            // الفكرة: لو فيه رد بالفعل، نعرضه في صندوق مميز بلون مختلف
            // عشان يبقى واضح إنه "صوت التاجر" مش تعليق مستخدم تاني
            // ------------------------------------------------------------
            if (hasReply) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(right: BorderSide(color: Color(0xFF1A237E), width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('رد صاحب المكان:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(rating.merchantReply!),
                  ],
                ),
              ),
            ],

            // ------------------------------------------------------------
            // الفكرة: زرار "رد" بيظهر بس للتاجر، وبس لو مفيش رد موجود بالفعل
            // (منمنعش التعديل، بس منعرضش زرار "رد" لتقييم اتردّ عليه قبل كده)
            // ------------------------------------------------------------
            if (widget.isMerchantView && !hasReply) ...[
              const SizedBox(height: 8),
              if (!_isReplying)
                TextButton.icon(
                  onPressed: () => setState(() => _isReplying = true),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('رد على التقييم'),
                )
              else ...[
                TextField(
                  controller: _replyController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'اكتب ردك هنا...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveReply,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('نشر الرد', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
