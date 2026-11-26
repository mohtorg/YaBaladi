// lib/core/services/qr_verification_service.dart
// 
// خدمة التحقق وتوليد حمولة رمز الاستجابة السريعة (QR Code) للمكان
// لا تتطلب أي تخزين لملفات صور في السيرفر — الرسم والتحقق يتمان برمجياً ومحلياً.

abstract final class QrVerificationService {
  QrVerificationService._();

  static const String _qrPrefix = 'YB-QR:v1';

  /// توليد النص المشفر المعياري الخاص برمز المكان
  /// هذا النص هو الذي ترسمه مكتبة QR على شاشة التاجر/المسؤول كرمز استجابة سريعة
  static String generatePlaceQrPayload({
    required String placeId,
    required String governorate,
  }) {
    final cleanPlaceId = placeId.trim();
    final cleanGov = governorate.trim();
    return '$_qrPrefix:$cleanGov:$cleanPlaceId';
  }

  /// التحقق من مطابقة وصحة كود QR الممسوح مع المكان المستهدف
  static bool verifyQrPayload({
    required String scannedPayload,
    required String expectedPlaceId,
  }) {
    if (scannedPayload.isEmpty || expectedPlaceId.isEmpty) {
      return false;
    }

    final trimmed = scannedPayload.trim();
    if (!trimmed.startsWith('$_qrPrefix:')) {
      return false;
    }

    final parts = trimmed.split(':');
    // الشكل المتوقع: ['YB-QR', 'v1', 'governorate', 'placeId']
    if (parts.length >= 4) {
      final actualPlaceId = parts[3];
      return actualPlaceId == expectedPlaceId.trim();
    }

    return false;
  }
}
