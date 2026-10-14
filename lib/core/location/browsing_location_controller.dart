// lib/core/location/browsing_location_controller.dart
//
// [v1.0 — 2026-10-14] — G4.2-b: BrowsingLocationController
//   - يفصل "الموقع الفعلي" (GPS) عن "الموقع المُتصفَّح" (اختيار المستخدم).
//   - يُستخدَم في HomeScreen لفلترة الأماكن حسب المحافظة.
//   - يستهلك egypt_governorates.dart + LocationService.

import 'package:flutter/foundation.dart';

import 'egypt_governorates.dart';

/// يدير "المحافظة المُتصفَّحة حالياً" — منفصلة عن موقع المستخدم الفعلي.
///
/// - الفعلي: من GPS (physicalLocation).
/// - المُتصفَّح: من اختيار المستخدم أو مطابق للفعلي افتراضياً.
class BrowsingLocationController extends ChangeNotifier {
  /// مُعرّف المحافظة المُتصفَّحة حالياً. `null` = لم تُحدَّد بعد.
  String? _browsingId;

  /// المُعرّف الفعلي (من GPS). `null` = لم يُحدَّد بعد أو مرفوض.
  String? _physicalId;

  bool _isUsingPhysical = true;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  /// المحافظة المُتصفَّحة حالياً.
  ///
  /// الأولوية:
  ///   1) المُتصفَّح (إن مُحدَّد)
  ///   2) الفعلي (من GPS)
  ///   3) الافتراضي (القاهرة)
  EgyptGovernorate get browsing {
    return governorateById(_browsingId) ??
        governorateById(_physicalId) ??
        kDefaultGovernorate;
  }

  /// المحافظة الفعلية (من GPS).
  /// `null` = لا GPS فعلي — عندها [browsing] هو المصدر الوحيد.
  EgyptGovernorate? get physical {
    return governorateById(_physicalId);
  }

  /// هل المُتصفَّح = الفعلي؟
  bool get isUsingPhysical => _isUsingPhysical;

  /// هل يوجد موقع فعلي (GPS)؟
  bool get hasPhysicalLocation => _physicalId != null;

  /// هل هناك فرق بين المُتصفَّح والفعلي؟
  bool get isBrowsingOtherGovernorate {
    if (_physicalId == null) return false;
    return _browsingId != null && _browsingId != _physicalId;
  }

  // ═══════════════════════════════════════════════════════════════
  // MUTATIONS
  // ═══════════════════════════════════════════════════════════════

  /// يُحدِّث الموقع الفعلي (من GPS).
  ///
  /// - إذا كان المستخدم يستعرض الفعلي → يتبعه تلقائياً.
  /// - إذا كان المستخدم يستعرض محافظة أخرى → لا يتغيّر المُتصفَّح.
  void setPhysicalLocation(double lat, double lng) {
    final gov = nearestGovernorate(lat, lng);
    final changed = _physicalId != gov.id;
    _physicalId = gov.id;

    // إذا كان المستخدم على "الفعلي" → تابع التحديث
    if (_isUsingPhysical || _browsingId == null) {
      _browsingId = gov.id;
      _isUsingPhysical = true;
    }

    if (changed) notifyListeners();
  }

  /// يُحدِّد المحافظة المُتصفَّحة يدوياً.
  ///
  /// - إن كان [governorateId] = الفعلي → يُفعِّل `isUsingPhysical`.
  /// - وإلا → يُلغي `isUsingPhysical`.
  /// - `null` أو نص فارغ → يعود للفعلي.
  void setBrowsingGovernorate(String? governorateId) {
    if (governorateId == null || governorateId.isEmpty) {
      resetToPhysical();
      return;
    }

    if (!isEgyptGovernorateId(governorateId)) {
      debugPrint(
        'BrowsingLocationController: unknown governorate "$governorateId"',
      );
      return;
    }

    final changed = _browsingId != governorateId;
    _browsingId = governorateId;
    _isUsingPhysical = (_physicalId == governorateId);

    if (changed) notifyListeners();
  }

  /// يعود لاستخدام الموقع الفعلي.
  void resetToPhysical() {
    if (_physicalId == null) return;
    final changed = _browsingId != _physicalId || !_isUsingPhysical;
    _browsingId = _physicalId;
    _isUsingPhysical = true;
    if (changed) notifyListeners();
  }

  /// يُصفِّر الحالة بالكامل — يُستخدَم عند signOut أو مسح البيانات.
  void clear() {
    _browsingId = null;
    _physicalId = null;
    _isUsingPhysical = true;
    notifyListeners();
  }
}
