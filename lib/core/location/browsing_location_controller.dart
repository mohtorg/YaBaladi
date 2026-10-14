// lib/core/location/browsing_location_controller.dart
//
// [v1.1 — 2026-10-14] — G4.2-c-4: Nominatim integration
//   - NEW: reverse geocoding عند setPhysicalLocation
//   - NEW: physicalAddress — AddressInfo من Nominatim
//   - NEW: browsingShortLabel — "بورسعيد - الشرق"
//   - CHANGE: _resolvePhysicalAddress fire-and-forget
//   - CHANGE: _safeNotify — حماية من notifyListeners بعد dispose
//
// [v1.0 — 2026-10-14] — G4.2-b: BrowsingLocationController

import 'package:flutter/foundation.dart';

import '../../models/address_info.dart';
import 'egypt_governorates.dart';
import 'reverse_geocoding_service.dart';

/// يدير "المحافظة المُتصفَّحة حالياً" — منفصلة عن موقع المستخدم الفعلي.
///
/// - الفعلي: من GPS (physicalLocation).
/// - المُتصفَّح: من اختيار المستخدم أو مطابق للفعلي افتراضياً.
class BrowsingLocationController extends ChangeNotifier {
  String? _browsingId;
  String? _physicalId;
  bool _isUsingPhysical = true;

  /// [v1.1] العنوان الفعلي المُستخرَج من Nominatim.
  AddressInfo? _physicalAddress;

  /// [v1.1] هل تم التدمير؟
  bool _disposed = false;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS — الأساسية
  // ═══════════════════════════════════════════════════════════════

  /// المحافظة المُتصفَّحة حالياً.
  EgyptGovernorate get browsing {
    return governorateById(_browsingId) ??
        governorateById(_physicalId) ??
        kDefaultGovernorate;
  }

  /// المحافظة الفعلية (من GPS).
  EgyptGovernorate? get physical => governorateById(_physicalId);

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
  // GETTERS — [v1.1] العنوان
  // ═══════════════════════════════════════════════════════════════

  /// العنوان الفعلي — من Nominatim (قد يكون null إذا فشل).
  AddressInfo? get physicalAddress => _physicalAddress;

  /// اسم الحي الفعلي — مثلاً "الشرق".
  String? get physicalDistrictName => _physicalAddress?.district;

  /// تسمية مختصرة للمحافظة المُتصفَّحة:
  /// - إذا نستعرض الفعلي → "بورسعيد - الشرق"
  /// - إذا نستعرض محافظة أخرى → "الإسكندرية"
  String get browsingShortLabel {
    if (isUsingPhysical && _physicalAddress != null) {
      return _physicalAddress!.shortLabel;
    }
    return browsing.nameAr;
  }

  // ═══════════════════════════════════════════════════════════════
  // MUTATIONS
  // ═══════════════════════════════════════════════════════════════

  /// يُحدِّث الموقع الفعلي (من GPS) + يبدأ reverse geocoding.
  void setPhysicalLocation(double lat, double lng) {
    final gov = nearestGovernorate(lat, lng);
    final changed = _physicalId != gov.id;
    _physicalId = gov.id;

    if (_isUsingPhysical || _browsingId == null) {
      _browsingId = gov.id;
      _isUsingPhysical = true;
    }

    if (changed) _safeNotify();

    // ابدأ Reverse Geocoding — fire-and-forget
    _resolvePhysicalAddress(lat, lng);
  }

  Future<void> _resolvePhysicalAddress(double lat, double lng) async {
    final info = await ReverseGeocodingService.resolve(lat, lng);
    if (_disposed) return;
    if (info == null || !info.hasData) return;

    _physicalAddress = info;
    _safeNotify();
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

    if (changed) _safeNotify();
  }

  /// يعود لاستخدام الموقع الفعلي.
  void resetToPhysical() {
    if (_physicalId == null) return;
    final changed = _browsingId != _physicalId || !_isUsingPhysical;
    _browsingId = _physicalId;
    _isUsingPhysical = true;
    if (changed) _safeNotify();
  }

  /// يُصفِّر الحالة بالكامل — يُستخدَم عند signOut أو مسح البيانات.
  void clear() {
    _browsingId = null;
    _physicalId = null;
    _isUsingPhysical = true;
    _physicalAddress = null;
    _safeNotify();
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
