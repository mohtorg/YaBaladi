// lib/core/location/browsing_location_controller.dart
//
// [v1.2.1 — 2026-10-25] — FIX: Removed unused import + improved notify logic
//   - REMOVED: unused import '../../services/location_service.dart'
//   - FIXED: notifyListeners() now triggers if placeName or source changes
//   - KEPT: all logic, getters, and metadata handling identical

import 'package:flutter/foundation.dart';

import '../../models/address_info.dart';
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
    final govChanged = _physicalId != gov.id;
    _physicalId = gov.id;

    if (_isUsingPhysical || _browsingId == null) {
      _browsingId = gov.id;
      _isUsingPhysical = true;
    }

    // [v1.2.1 FIX] تتبع تغيير البيانات الوصفية
    bool metadataChanged = false;

    if (source != null && source != _lastSource) {
      _lastSource = source;
      metadataChanged = true;
    }

    if (placeName != null && placeName != _physicalPlaceName) {
      _physicalPlaceName = placeName;
      metadataChanged = true;
    }

    _lastUpdatedAt = DateTime.now();

    // نُحدّث الواجهة إذا تغيرت المحافظة أو تغيرت البيانات الوصفية
    if (govChanged || metadataChanged) {
      _safeNotify();
    }

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
