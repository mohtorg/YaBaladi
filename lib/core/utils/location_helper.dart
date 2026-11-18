// lib/core/utils/location_helper.dart
// [v1.3 — 2026-11-11] — ULTRA SMART: Enhanced deduplication to handle combined words (e.g., "الشرق بورسعيد" vs "حي الشرق").

enum LocationDisplayMode {
  full, // للمحافظة والحي والمنطقة (للتفاصيل)
  medium, // للحي والمنطقة (للبطاقات)
  short, // للمنطقة فقط (للقوائم المزدحمة)
}

class LocationHelper {
  LocationHelper._();

  /// دالة ذكية لتنظيف النصوص من المسافات الزائدة
  static String _cleanText(String? text) {
    if (text == null) return '';
    return text.trim().split(' ').where((word) => word.isNotEmpty).join(' ');
  }

  /// دالة ذكية مركزية لتنسيق العناوين وإزالة التكرار
  static String format({
    String? governorate,
    String? district,
    String? zone,
    String? address,
    LocationDisplayMode mode = LocationDisplayMode.medium,
    String separator = ' • ',
  }) {
    // 1. تنظيف النصوص من الفراغات والمسافات الزائدة
    final cleanGov = _cleanText(governorate);
    final cleanDist = _cleanText(district);
    final cleanZone = _cleanText(zone);
    final cleanAddr = _cleanText(address);

    // ✅ إضافة final لأن المتغير لا يُعاد إسناده
    final parts = <String>[];

    // 2. اختيار الأجزاء بناءً على السياق (Mode)
    switch (mode) {
      case LocationDisplayMode.full:
        if (cleanGov.isNotEmpty) parts.add(cleanGov);
        if (cleanDist.isNotEmpty) parts.add(cleanDist);
        if (cleanZone.isNotEmpty) parts.add(cleanZone);
        if (cleanAddr.isNotEmpty) parts.add(cleanAddr);
        break;
      case LocationDisplayMode.medium:
        if (cleanDist.isNotEmpty) parts.add(cleanDist);
        if (cleanZone.isNotEmpty) parts.add(cleanZone);
        break;
      case LocationDisplayMode.short:
        if (cleanZone.isNotEmpty) {
          parts.add(cleanZone);
        } else if (cleanDist.isNotEmpty) {
          parts.add(cleanDist); // احتياطي: إذا لم توجد منطقة، نعرض الحي
        }
        break;
    }

    if (parts.isEmpty) return '';

    // 3. الخوارزمية الذكية جداً لإزالة التكرار
    final finalParts = <String>[];
    for (var part in parts) {
      bool isRedundant = false;

      // تقسيم النص الحالي إلى كلمات منفصلة
      final partWords = part.split(' ').toSet();

      for (var other in parts) {
        if (part == other) continue;

        // تقسيم النص الآخر إلى كلمات منفصلة
        final otherWords = other.split(' ').toSet();

        // إذا كانت جميع كلمات النص الحالي موجودة داخل النص الآخر، فهو مكرر
        if (partWords.isNotEmpty &&
            partWords.every((w) => otherWords.contains(w))) {
          isRedundant = true;
          break;
        }

        // أو إذا كان النص الحالي مجرد جزء نصي من النص الآخر
        if (part != other && other.contains(part)) {
          isRedundant = true;
          break;
        }
      }

      // نضيف الكلمة فقط إذا لم تكن مكررة أو جزءاً من كلمة أخرى
      if (!isRedundant && !finalParts.contains(part)) {
        finalParts.add(part);
      }
    }

    return finalParts.join(separator);
  }
}
