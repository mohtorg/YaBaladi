// lib/core/location/browsing_location_controller.dart
//
// [v1.2 — 2026-10-19] — Wave 5.5c: On-Demand metadata (ADR-4)
//   - ADD: _physicalPlaceName (اسم GPS الدقيق)
//   - ADD: _lastSource (من أين جاء الموقع)
//   - ADD: _lastUpdatedAt (متى تم التحديث)
//   - CHANGE: setPhysicalLocation يقبل {placeName, source}
//   - KEPT: _resolvePhysicalAddress (fallback إذا لم يُمرَّر placeName)

import 'package:flutter/foundation.dart';

import '../../models/address_info.dart';
import '../../services/location_service.dart';
import 'egypt_governorates.dart';
import 'location_source.dart';
import 'reverse_geocoding_service.dart';

class BrowsingLocationController extends ChangeNotifier {
  String? _browsingId;
  String? _physicalId;
  bool _isUsingPhysical = true;

  AddressInfo? _physicalAddress;
  bool _disposed = false;

  // ─── [v1.2] Wave 5.5c ───
  String? _physicalPlaceName;
  LocationSource? _lastSource;
  DateTime? _lastUpdatedAt;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  EgyptGovernorate get browsing {
    return governorateById(_browsingId) ??
        governorateById(_physicalId) ??
        kDefaultGovernorate;
  }

  EgyptGovernorate? get physical => governorateById(_physicalId);
  bool get isUsingPhysical => _isUsingPhysical;
  bool get hasPhysicalLocation => _physicalId != null;

  bool get isBrowsingOtherGovernorate {
    if (_physicalId == null) return false;
    return _browsingId != null && _browsingId != _physicalId;
  }

  AddressInfo? get physicalAddress => _physicalAddress;
  String? get physicalDistrictName => _physicalAddress?.district;

  /// [v1.2] اسم المكان الدقيق (GPS/بحث/يدوي)
  String? get physicalPlaceName => _physicalPlaceName;

  /// [v1.2] المصدر الأخير
  LocationSource? get lastSource => _lastSource;

  /// [v1.2] آخر تحديث
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  String get browsingShortLabel {
    if (isUsingPhysical) {
      if (_physicalPlaceName != null && _physicalPlaceName!.isNotEmpty) {
        return _physicalPlaceName!;
      }
      if (_physicalAddress != null) {
        return _physicalAddress!.shortLabel;
      }
    }
    return browsing.nameAr;
  }

  // ═══════════════════════════════════════════════════════════════
  // MUTATIONS
  // ═══════════════════════════════════════════════════════════════

  /// [v1.2] يقبل الآن placeName + source (اختياري)
  void setPhysicalLocation(
    double lat,
    double lng, {
    String? placeName,
    LocationSource? source,
  }) {
    final gov = nearestGovernorate(lat, lng);
    final changed = _physicalId != gov.id;
    _physicalId = gov.id;

    if (_isUsingPhysical || _browsingId == null) {
      _browsingId = gov.id;
      _isUsingPhysical = true;
    }

    // [v1.2] تحديث metadata
    _lastSource = source;
    _lastUpdatedAt = DateTime.now();
    if (placeName != null) _physicalPlaceName = placeName;

    if (changed) _safeNotify();

    // Reverse geocode فقط إذا لم يأتِ placeName من الخارج
    if (placeName == null) {
      _resolvePhysicalAddress(lat, lng);
    }
  }

  Future<void> _resolvePhysicalAddress(double lat, double lng) async {
    final info = await ReverseGeocodingService.resolve(lat, lng);
    if (_disposed) return;
    if (info == null || !info.hasData) return;

    _physicalAddress = info;
    _safeNotify();
  }

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

  void resetToPhysical() {
    if (_physicalId == null) return;
    final changed = _browsingId != _physicalId || !_isUsingPhysical;
    _browsingId = _physicalId;
    _isUsingPhysical = true;
    if (changed) _safeNotify();
  }

  void clear() {
    _browsingId = null;
    _physicalId = null;
    _isUsingPhysical = true;
    _physicalAddress = null;
    _physicalPlaceName = null;
    _lastSource = null;
    _lastUpdatedAt = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
