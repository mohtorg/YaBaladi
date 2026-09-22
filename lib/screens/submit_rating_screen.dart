// screens/submit_rating_screen.dart
// شاشة كتابة التقييم - تظهر بس للزيارات الموثّقة (بعد مسح التاجر للكود)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visit_model.dart';
import '../models/coupon_model.dart';
import '../services/rating_service.dart';
import '../services/coupon_service.dart';
import '../widgets/rating_stars.dart';

class SubmitRatingScreen extends StatefulWidget {
  final Visit visit;

  const SubmitRatingScreen({super.key, required this.visit});

  @override
  State<SubmitRatingScreen> createState() => _SubmitRatingScreenState();
}

class _SubmitRatingScreenState extends State<SubmitRatingScreen> {
  double _stars = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _placeName;

  @override
  void initState() {
    super.initState();
    _loadPlaceName();
  }

  Future<void> _loadPlaceName() async {
    final doc = await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.visit.placeId)
        .get();
    if (mounted) {
      setState(() {
        _placeName = doc.data()?['name_ar'] ?? 'المكان';
      });
    }
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك اختر عدد النجوم أولاً')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ratingId = await RatingService().submitRating(
        visitId: widget.visit.id,
        placeId: widget.visit.placeId,
        userId: widget.visit.userId,
        stars: _stars.toInt(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      // الكوبون مرتبط بهذا التقييم بعينه؛ لا نسمح بإصدار مكافأة ثانية لنفس التقييم.
      final coupon = await CouponService().generateRewardCoupon(
        userId: widget.visit.userId,
        placeId: widget.visit.placeId,
        ratingId: ratingId,
      );

      if (mounted) {
        await _showCouponDialog(coupon);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إتمام التقييم والمكافأة: $e')),
      );
    }
  }

  // ------------------------------------------------------------
  // الفكرة: نافذة بسيطة توضح الكود بخط كبير وواضح، عشان المستخدم
  // يقدر يقول الكود للتاجر أو يوريهوله على الشاشة بسهولة
  // ------------------------------------------------------------
  Future<void> _showCouponDialog(Coupon coupon) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 شكرًا لتقييمك!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(coupon.discountLabel, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                coupon.code,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'وريّ الكود ده للتاجر عند زيارتك القادمة\nصالح لمدة 7 أيام',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قيّم زيارتك'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _placeName ?? '...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'زيارتك موثّقة ✅ - رأيك هيساعد زوار تانيين',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 32),
            Center(
              child: RatingStars(
                rating: _stars,
                interactive: true,
                onRatingChanged: (value) => setState(() => _stars = value),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك (اختياري)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إرسال التقييم', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
