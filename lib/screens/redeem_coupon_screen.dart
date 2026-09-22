// screens/redeem_coupon_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// التاجر بيدخل كود الكوبون اللي الزبون قاله له وقت الحساب.
// الشاشة بتستخدم CouponService.redeemCoupon اللي بيتحقق من كل حاجة
// (الكود صحيح، لسه صالح، ولمكان التاجر ده تحديدًا) قبل ما يوافق
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/coupon_service.dart';

class RedeemCouponScreen extends StatefulWidget {
  const RedeemCouponScreen({super.key});

  @override
  State<RedeemCouponScreen> createState() => _RedeemCouponScreenState();
}

class _RedeemCouponScreenState extends State<RedeemCouponScreen> {
  final _codeController = TextEditingController();
  bool _isChecking = false;

  Future<void> _redeem() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() => _isChecking = true);

    final merchantId = AuthService().currentUser?.uid ?? '';
    final result = await CouponService().redeemCoupon(
      code: _codeController.text.trim(),
      merchantId: merchantId,
    );

    setState(() => _isChecking = false);

    if (!mounted) return;

    // ------------------------------------------------------------
    // الفكرة: نافذة نتيجة واضحة (نجاح بالأخضر، فشل بالأحمر) -
    // نفس أسلوب شاشة مسح كود الزيارة (scan_qr_screen.dart) عشان
    // يبقى شكل موحّد للتاجر في كل شاشات "التحقق" بالتطبيق
    // ------------------------------------------------------------
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.success ? 'تم القبول ✅' : 'مرفوض ❌'),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (result.success) _codeController.clear();
            },
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
        title: const Text('استبدال كوبون'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'اطلب من الزبون قول كود الكوبون واكتبه هنا',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'YB-XXXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isChecking ? null : _redeem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isChecking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('تحقق من الكود'),
            ),
          ],
        ),
      ),
    );
  }
}
