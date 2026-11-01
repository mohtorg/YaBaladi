// lib/features/admin/screens/add_place_screen.dart
//
// [v5.5 — 2026-11-01] — GPS AUTO-FILL & ZONE INTEGRATION
//   - ADDED: Button to fetch current GPS location.
//   - ADDED: ZoneService integration to auto-detect geoZoneName (e.g., "الزهور").
//   - ADDED: geoZoneName field to save in Firestore.
//   - KEPT: All v5.4 logic (Global Edit Mode, fields, etc.).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart'; // ✅ Added for GPS

import '../../../core/helpers/location_url_helper.dart';
import '../../../core/services/zone_service.dart'; // ✅ Added for Auto-Zone
import '../../../models/category.dart';
import '../../../models/district.dart';
import '../../../models/governorate_config.dart';
import '../../../repositories/categories_repository.dart';
import '../../../repositories/governorates_repository.dart';
import '../../../theme/design_tokens.dart';

/// يسمح بأحرف الإحداثيات فقط (0-9 و . و -) ويحافظ على موضع المؤشر.
class _CoordinateInputFormatter extends TextInputFormatter {
  static bool _allowed(int c) => (c >= 48 && c <= 57) || c == 46 || c == 45;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final units = text.codeUnits;
    final kept = StringBuffer();
    final keptBefore = List<int>.filled(units.length + 1, 0);
    for (var i = 0; i < units.length; i++) {
      keptBefore[i] = kept.length;
      if (_allowed(units[i])) kept.writeCharCode(units[i]);
    }
    keptBefore[units.length] = kept.length;
    final filtered = kept.toString();
    if (filtered == text) return newValue;
    int map(int offset) {
      if (offset < 0) return offset;
      if (offset > units.length) return filtered.length;
      return keptBefore[offset];
    }

    final sel = newValue.selection;
    return TextEditingValue(
      text: filtered,
      selection: TextSelection(
        baseOffset: map(sel.baseOffset),
        extentOffset: map(sel.extentOffset),
        affinity: sel.affinity,
        isDirectional: sel.isDirectional,
      ),
      composing: TextRange.empty,
    );
  }
}

class AddPlaceScreen extends StatefulWidget {
  final String? placeId;
  const AddPlaceScreen({super.key, this.placeId});
  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoading = false;

  // v5.5: GPS State
  bool _isFetchingLocation = false;
  String _fetchedZoneName = '';

  // v5.4: Global Edit Mode (edit screen only)
  bool _isEditing = false;
  Map<String, dynamic>? _originalData;

  final CategoriesRepository _categoriesRepo = CategoriesRepository();
  List<Category> _categories = const [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _pasteUrlCtrl = TextEditingController();

  String _selectedCategory = 'restaurants';
  String? _originalCategory;
  int _priceLevel = 1;

  // ─── Wave 17: Governorates & Districts ───
  GovernorateConfig? _selectedGovernorate;
  District? _selectedDistrict;
  String _pendingGovName = '';
  String _pendingDistrictName = '';

  List<GovernorateConfig> _governorates = const [];
  List<District> _districts = const [];
  bool _loadingGovernorates = true;
  bool _loadingDistricts = false;

  bool _hasWifi = false;
  bool _hasParking = false;
  bool _hasRestroom = false;
  bool _hasAccessibility = false;
  bool _isFamilyFriendly = false;
  bool _isHalal = false;
  bool _hasDelivery = false;
  bool _hasReservation = false;

  static final List<TextInputFormatter> _coordinateFormatters = [
    _CoordinateInputFormatter(),
  ];

  bool get _isEditMode => widget.placeId != null;

  String get _effectiveGovName =>
      _selectedGovernorate?.nameAr ?? _pendingGovName;
  String get _effectiveDistrictName =>
      _selectedDistrict?.nameAr ?? _pendingDistrictName;

  @override
  void initState() {
    super.initState();
    _isEditing = !_isEditMode;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadGovernorates();
    if (_isEditMode) {
      final found = await _loadPlaceData();
      if (!found || !mounted) return;
      await _resolveInitialSelection();
      await _loadCategories(preserveSelection: true);
    } else {
      if (_governorates.isNotEmpty) {
        _selectedGovernorate = _governorates.first;
        await _loadDistricts(_selectedGovernorate!.docId);
      }
      await _loadCategories();
    }
  }

  Future<void> _loadGovernorates() async {
    try {
      final govs =
          await GovernoratesRepository.instance.watchActiveGovernorates().first;
      if (!mounted) return;
      setState(() {
        _governorates = govs;
        _loadingGovernorates = false;
      });
    } catch (e) {
      debugPrint('Failed to load governorates: $e');
      if (!mounted) return;
      setState(() {
        _governorates = const [];
        _loadingGovernorates = false;
      });
    }
  }

  Future<void> _loadDistricts(String govDocId) async {
    setState(() => _loadingDistricts = true);
    try {
      final dists = await GovernoratesRepository.instance
          .watchActiveDistricts(govDocId)
          .first;
      if (!mounted) return;
      setState(() {
        _districts = dists;
        _loadingDistricts = false;
      });
    } catch (e) {
      debugPrint('Failed to load districts: $e');
      if (!mounted) return;
      setState(() {
        _districts = const [];
        _loadingDistricts = false;
      });
    }
  }

  Future<void> _resolveInitialSelection() async {
    if (_pendingGovName.isEmpty) {
      if (_governorates.isNotEmpty) {
        _selectedGovernorate = _governorates.first;
        await _loadDistricts(_selectedGovernorate!.docId);
      }
      if (mounted) setState(() {});
      return;
    }

    GovernorateConfig? matchedGov;
    for (final g in _governorates) {
      if (g.nameAr == _pendingGovName) {
        matchedGov = g;
        break;
      }
    }

    if (matchedGov != null) {
      _selectedGovernorate = matchedGov;
      await _loadDistricts(matchedGov.docId);
      if (_pendingDistrictName.isNotEmpty) {
        for (final d in _districts) {
          if (d.nameAr == _pendingDistrictName) {
            _selectedDistrict = d;
            break;
          }
        }
      }
    } else {
      _selectedGovernorate = GovernorateConfig(
        docId: '__legacy_gov__',
        nameAr: _pendingGovName,
        nameEn: '',
        order: 999,
        isActive: false,
        deliveryEnabled: false,
        tripsEnabled: false,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadCategories({bool preserveSelection = false}) async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final cats = await _categoriesRepo.getAllActive();
      if (!mounted) return;
      if (cats.isEmpty) {
        setState(() {
          _categoriesLoading = false;
          _categoriesError = 'لا توجد تصنيفات متاحة.';
        });
        return;
      }
      setState(() {
        _categories = cats;
        _categoriesLoading = false;
        if (!preserveSelection && !cats.any((c) => c.id == _selectedCategory)) {
          _selectedCategory = cats.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesLoading = false;
        _categoriesError = e.toString();
      });
    }
  }

  Future<bool> _loadPlaceData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ المكان غير موجود'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return false;
      }

      final data = doc.data() ?? <String, dynamic>{};

      if (mounted) {
        _originalData = Map<String, dynamic>.from(data);

        setState(() {
          _nameArCtrl.text = data['nameAr']?.toString() ?? '';
          _nameEnCtrl.text = data['nameEn']?.toString() ?? '';
          _descCtrl.text = data['description']?.toString() ?? '';
          _addressCtrl.text = data['address']?.toString() ?? '';
          _phoneCtrl.text = data['phone']?.toString() ??
              data['businessPhone']?.toString() ??
              '';
          _websiteCtrl.text = data['website']?.toString() ?? '';
          _emailCtrl.text = data['businessEmail']?.toString() ?? '';
          _facebookCtrl.text = data['facebookPage']?.toString() ?? '';
          _tagsCtrl.text =
              (data['tags'] as List?)?.map((e) => e.toString()).join(', ') ??
                  '';
          _priceLevel = (data['priceLevel'] as num?)?.toInt() ?? 1;

          // ✅ v5.5: Load saved zone
          _fetchedZoneName = data['geoZoneName']?.toString() ?? '';

          final location = data['location'];
          final geo = location is GeoPoint ? location : null;
          final lat = data['latitude'] ?? geo?.latitude;
          final lng = data['longitude'] ?? geo?.longitude;
          _latCtrl.text = lat?.toString() ?? '';
          _lngCtrl.text = lng?.toString() ?? '';

          _selectedCategory = data['categoryId']?.toString() ?? 'restaurants';
          _originalCategory = _selectedCategory;

          _pendingGovName = data['governorate']?.toString() ?? '';
          _pendingDistrictName = data['city']?.toString() ?? '';

          _hasWifi = data['hasWifi'] == true;
          _hasParking = data['hasParking'] == true;
          _hasRestroom = data['hasRestroom'] == true;
          _hasAccessibility = data['hasAccessibility'] == true;
          _isFamilyFriendly = data['isFamilyFriendly'] == true;
          _isHalal = data['isHalal'] == true;
          _hasDelivery = data['hasDelivery'] == true;
          _hasReservation = data['hasReservation'] == true;
        });
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error loading place: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
      return true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _emailCtrl.dispose();
    _facebookCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _tagsCtrl.dispose();
    _pasteUrlCtrl.dispose();
    super.dispose();
  }

  // ───────────────────── v5.5: GPS Fetch ─────────────────────

  Future<void> _fetchCurrentLocation() async {
    if (!_isEditing) return;

    setState(() => _isFetchingLocation = true);

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'خدمة الموقع (GPS) غير مفعلة في الهاتف';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'تم رفض صلاحية الوصول للموقع';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'صلاحية الموقع مرفوضة نهائياً من إعدادات الهاتف';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // جلب اسم الحي
      final zoneName = await ZoneService()
          .getZoneName(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _latCtrl.text = position.latitude.toStringAsFixed(6);
          _lngCtrl.text = position.longitude.toStringAsFixed(6);
          _fetchedZoneName = zoneName ?? 'غير معروف';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم جلب الموقع: $_fetchedZoneName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // ───────────────────── v5.4: Global Edit Mode ─────────────────────

  void _enterEditMode() {
    if (_isSaving) return;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    if (_isSaving) return;
    final d = _originalData;
    if (d == null) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() {
      _nameArCtrl.text = d['nameAr']?.toString() ?? '';
      _nameEnCtrl.text = d['nameEn']?.toString() ?? '';
      _descCtrl.text = d['description']?.toString() ?? '';
      _addressCtrl.text = d['address']?.toString() ?? '';
      _phoneCtrl.text =
          d['phone']?.toString() ?? d['businessPhone']?.toString() ?? '';
      _websiteCtrl.text = d['website']?.toString() ?? '';
      _emailCtrl.text = d['businessEmail']?.toString() ?? '';
      _facebookCtrl.text = d['facebookPage']?.toString() ?? '';
      _tagsCtrl.text =
          (d['tags'] as List?)?.map((e) => e.toString()).join(', ') ?? '';
      _priceLevel = (d['priceLevel'] as num?)?.toInt() ?? 1;

      // ✅ v5.5: Revert zone
      _fetchedZoneName = d['geoZoneName']?.toString() ?? '';

      final location = d['location'];
      final geo = location is GeoPoint ? location : null;
      final lat = d['latitude'] ?? geo?.latitude;
      final lng = d['longitude'] ?? geo?.longitude;
      _latCtrl.text = lat?.toString() ?? '';
      _lngCtrl.text = lng?.toString() ?? '';

      _selectedCategory = d['categoryId']?.toString() ?? 'restaurants';
      _originalCategory = _selectedCategory;

      _pendingGovName = d['governorate']?.toString() ?? '';
      _pendingDistrictName = d['city']?.toString() ?? '';
      _selectedDistrict = null;
      _districts = const [];

      _hasWifi = d['hasWifi'] == true;
      _hasParking = d['hasParking'] == true;
      _hasRestroom = d['hasRestroom'] == true;
      _hasAccessibility = d['hasAccessibility'] == true;
      _isFamilyFriendly = d['isFamilyFriendly'] == true;
      _isHalal = d['isHalal'] == true;
      _hasDelivery = d['hasDelivery'] == true;
      _hasReservation = d['hasReservation'] == true;

      _pasteUrlCtrl.clear();
      _isEditing = false;
    });

    _resolveInitialSelection();
  }

  Future<void> _savePlace() async {
    if (!_isEditing) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (_effectiveGovName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ الرجاء اختيار المحافظة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double lat = double.parse(_latCtrl.text.trim());
      final double lng = double.parse(_lngCtrl.text.trim());
      final geoPoint = GeoPoint(lat, lng);
      final geohash = _encodeGeohash(lat, lng);
      final googleMapsUrl = LocationUrlHelper.mapUrl(lat: lat, lng: lng);

      final tags = _tagsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final commonData = {
        'nameAr': _nameArCtrl.text.trim(),
        'nameEn': _nameEnCtrl.text.trim().isEmpty
            ? _nameArCtrl.text.trim()
            : _nameEnCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'categoryId': _selectedCategory,
        'governorate': _effectiveGovName,
        'city': _effectiveDistrictName,
        'geoZoneName': _fetchedZoneName, // ✅ v5.5: Save zone name
        'tags': tags,
        'address': _addressCtrl.text.trim(),
        'location': geoPoint,
        'latitude': lat,
        'longitude': lng,
        'geohash': geohash,
        'googleMapsUrl': googleMapsUrl,
        'phone': _phoneCtrl.text.trim(),
        'businessPhone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'businessEmail': _emailCtrl.text.trim(),
        'facebookPage': _facebookCtrl.text.trim(),
        'priceLevel': _priceLevel,
        'hasWifi': _hasWifi,
        'hasParking': _hasParking,
        'hasRestroom': _hasRestroom,
        'hasAccessibility': _hasAccessibility,
        'isFamilyFriendly': _isFamilyFriendly,
        'isHalal': _isHalal,
        'hasDelivery': _hasDelivery,
        'hasReservation': _hasReservation,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .update(commonData);

        if (_originalCategory != null &&
            _originalCategory != _selectedCategory) {
          await _categoriesRepo.incrementPlacesCount(_originalCategory!, -1);
          await _categoriesRepo.incrementPlacesCount(_selectedCategory, 1);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تحديث المكان'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await FirebaseFirestore.instance.collection('places').add({
          ...commonData,
          'addedBy': 'admin',
          'isApproved': true,
          'isActive': true,
          'averageRating': 0.0,
          'reviewCount': 0,
          'imageUrls': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _categoriesRepo.incrementPlacesCount(_selectedCategory, 1);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم إضافة المكان'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _encodeGeohash(double latitude, double longitude,
      {int precision = 7}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var isEven = true;
    var bit = 0;
    var ch = 0;
    final sb = StringBuffer();
    var latMin = -90.0, latMax = 90.0;
    var lonMin = -180.0, lonMax = 180.0;
    while (sb.length < precision) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (longitude > mid) {
          ch |= 1 << (4 - bit);
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude > mid) {
          ch |= 1 << (4 - bit);
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        sb.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return sb.toString();
  }

  String? _validateCoordinate(String? v, {required double limit}) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'مطلوب';
    final n = double.tryParse(text);
    if (n == null) return 'رقم غير صحيح';
    if (n < -limit || n > limit) return 'خارج النطاق';
    return null;
  }

  List<DropdownMenuItem<String>> _categoryItems() {
    final items = _categories
        .map((c) => DropdownMenuItem<String>(
              value: c.id,
              child: Row(children: [
                Icon(c.icon, size: 18, color: c.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.nameAr, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Text('${c.placesCount}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ))
        .toList();

    if (!_categories.any((c) => c.id == _selectedCategory)) {
      items.add(DropdownMenuItem<String>(
        value: _selectedCategory,
        child: Row(children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$_selectedCategory (غير متاح)',
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<String>> _governorateItems() {
    final items = _governorates
        .map((g) => DropdownMenuItem<String>(
              value: g.docId,
              child: Text(g.nameAr),
            ))
        .toList();

    final sel = _selectedGovernorate;
    if (sel != null && !_governorates.any((g) => g.docId == sel.docId)) {
      items.add(DropdownMenuItem<String>(
        value: sel.docId,
        child: Row(children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${sel.nameAr} (غير متاح)',
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<String>> _districtItems() {
    final items = _districts
        .map((d) => DropdownMenuItem<String>(
              value: d.id,
              child: Text(d.nameAr),
            ))
        .toList();

    final sel = _selectedDistrict;
    if (sel != null && !_districts.any((d) => d.id == sel.id)) {
      items.add(DropdownMenuItem<String>(
        value: sel.id,
        child: Row(children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${sel.nameAr} (غير متاح)',
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ));
    }
    return items;
  }

  GovernorateConfig? _findGovByDocId(String? docId) {
    if (docId == null) return null;
    for (final g in _governorates) {
      if (g.docId == docId) return g;
    }
    return null;
  }

  District? _findDistrictById(String? id) {
    if (id == null) return null;
    for (final d in _districts) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _extractFromUrl() {
    final coords = LocationUrlHelper.extractCoordinates(_pasteUrlCtrl.text);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ لم يتم التعرف على إحداثيات في الرابط. '
            'الروابط المختصرة (maps.app.goo.gl) غير مدعومة، '
            'الصق الرابط الكامل أو الإحداثيات مباشرة',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    setState(() {
      _latCtrl.text = coords.lat.toString();
      _lngCtrl.text = coords.lng.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم استخراج: ${coords.lat}, ${coords.lng}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _previewOnMap() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل إحداثيات صحيحة أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final url = LocationUrlHelper.mapUrl(lat: lat, lng: lng);
    final opened = await LocationUrlHelper.open(url);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح الخريطة')),
      );
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _categoriesLoading || _loadingGovernorates) {
      return _buildLoadingScaffold();
    }
    if (_categoriesError != null) {
      return _buildErrorScaffold();
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode
            ? (_isEditing ? 'تعديل المكان' : 'بيانات المكان')
            : 'إضافة مكان جديد'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: _isEditMode
            ? (_isEditing
                ? [
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'إلغاء التعديل',
                      onPressed: _isSaving ? null : _cancelEdit,
                    ),
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      tooltip: 'حفظ التعديلات',
                      onPressed: _isSaving ? null : _savePlace,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'تعديل البيانات',
                      onPressed: _enterEditMode,
                    ),
                  ])
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEditMode && _isEditing) _buildEditModeBanner(theme),
            if (_isEditMode && !_isEditing) _buildReadOnlyBanner(theme),

            _buildSectionHeader(
              icon: Icons.info_outline,
              title: 'المعلومات الأساسية',
              subtitle: 'الاسم والوصف',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameArCtrl,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'اسم المكان (بالعربية) *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                hintText: 'مثال: ميدان الشهداء',
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameEnCtrl,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'اسم المكان (بالإنجليزية)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.language),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'الوصف (اختياري)',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.description),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              icon: Icons.place,
              title: 'التصنيف والموقع',
              subtitle: 'التصنيف، المحافظة، الحي، والموقع',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('cat_${_selectedCategory}_$_isEditing'),
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'التصنيف *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
              items: _categoryItems(),
              onChanged: _isEditing
                  ? (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(
                  'gov_${_selectedGovernorate?.docId ?? 'none'}_$_isEditing'),
              initialValue: _selectedGovernorate?.docId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'المحافظة *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
              items: _governorateItems(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'اختر المحافظة' : null,
              onChanged: (_isEditing && !_loadingGovernorates)
                  ? (val) async {
                      final gov = _findGovByDocId(val);
                      if (gov == null) return;
                      setState(() {
                        _selectedGovernorate = gov;
                        _selectedDistrict = null;
                        _districts = const [];
                        _pendingDistrictName = '';
                      });
                      await _loadDistricts(gov.docId);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(
                  'dist_${_selectedDistrict?.id ?? 'none'}_${_selectedGovernorate?.docId ?? 'none'}_$_isEditing'),
              initialValue: _selectedDistrict?.id,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'الحي (اختياري)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                helperText: _loadingDistricts ? 'جارٍ التحميل...' : null,
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
              items: _districtItems(),
              onChanged: (_isEditing && !_loadingDistricts)
                  ? (val) =>
                      setState(() => _selectedDistrict = _findDistrictById(val))
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'العنوان التفصيلي',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.map),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // GPS block
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.location_on,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text('الموقع الجغرافي',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87)),
                      ]),
                      // ✅ v5.5: Fetch Location Button
                      if (_isEditing)
                        ElevatedButton.icon(
                          onPressed: _isFetchingLocation
                              ? null
                              : _fetchCurrentLocation,
                          icon: _isFetchingLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 16),
                          label: const Text('تحديد موقعي',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),

                  // ✅ v5.5: Display Fetched Zone
                  if (_fetchedZoneName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade800, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'المنطقة المكتشفة: $_fetchedZoneName',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pasteUrlCtrl,
                    readOnly: !_isEditing,
                    decoration: InputDecoration(
                      labelText: 'الصق رابط Google Maps (اختياري)',
                      hintText: 'https://maps.google.com/?q=31.26,32.29',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                      helperText: 'سيتم استخراج الإحداثيات تلقائياً',
                      filled: !_isEditing,
                      fillColor: !_isEditing
                          ? theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3)
                          : null,
                      suffixIcon: _isEditing
                          ? IconButton(
                              icon: const Icon(Icons.content_paste_go),
                              tooltip: 'استخراج الإحداثيات',
                              onPressed: _extractFromUrl,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        readOnly: !_isEditing,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        inputFormatters:
                            _isEditing ? _coordinateFormatters : null,
                        decoration: InputDecoration(
                          labelText: 'خط العرض *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.north),
                          hintText: '31.2699',
                          filled: !_isEditing,
                          fillColor: !_isEditing
                              ? theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3)
                              : null,
                        ),
                        validator: (v) => _validateCoordinate(v, limit: 90),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        readOnly: !_isEditing,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        inputFormatters:
                            _isEditing ? _coordinateFormatters : null,
                        decoration: InputDecoration(
                          labelText: 'خط الطول *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.east),
                          hintText: '32.2998',
                          filled: !_isEditing,
                          fillColor: !_isEditing
                              ? theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3)
                              : null,
                        ),
                        validator: (v) => _validateCoordinate(v, limit: 180),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isEditing ? _previewOnMap : null,
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('معاينة الموقع على Google Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(
              icon: Icons.phone,
              title: 'معلومات التواصل',
              subtitle: 'الهاتف والموقع (اختياري)',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              readOnly: !_isEditing,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteCtrl,
              readOnly: !_isEditing,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'الموقع الإلكتروني',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.language),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              readOnly: !_isEditing,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facebookCtrl,
              readOnly: !_isEditing,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'صفحة الفيسبوك',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.facebook),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey('price_${_priceLevel}_$_isEditing'),
              initialValue: _priceLevel,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'مستوى السعر',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('اقتصادي')),
                DropdownMenuItem(value: 2, child: Text('متوسط')),
                DropdownMenuItem(value: 3, child: Text('مرتفع')),
                DropdownMenuItem(value: 4, child: Text('فاخر')),
              ],
              onChanged: _isEditing
                  ? (v) => setState(() => _priceLevel = v ?? 1)
                  : null,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(
              icon: Icons.room_service,
              title: 'الخدمات المتاحة',
              subtitle: 'حدد الخدمات',
            ),
            const SizedBox(height: 12),
            _buildServiceSwitch(
                icon: Icons.wifi,
                label: 'واي فاي',
                value: _hasWifi,
                onChanged: (v) => setState(() => _hasWifi = v)),
            _buildServiceSwitch(
                icon: Icons.local_parking,
                label: 'موقف سيارات',
                value: _hasParking,
                onChanged: (v) => setState(() => _hasParking = v)),
            _buildServiceSwitch(
                icon: Icons.wc,
                label: 'دورة مياه',
                value: _hasRestroom,
                onChanged: (v) => setState(() => _hasRestroom = v)),
            _buildServiceSwitch(
                icon: Icons.accessible,
                label: 'سهولة الوصول',
                value: _hasAccessibility,
                onChanged: (v) => setState(() => _hasAccessibility = v)),
            _buildServiceSwitch(
                icon: Icons.family_restroom,
                label: 'مناسب للعائلات',
                value: _isFamilyFriendly,
                onChanged: (v) => setState(() => _isFamilyFriendly = v)),
            _buildServiceSwitch(
                icon: Icons.restaurant_menu,
                label: 'حلال',
                value: _isHalal,
                onChanged: (v) => setState(() => _isHalal = v)),
            _buildServiceSwitch(
                icon: Icons.delivery_dining,
                label: 'توصيل',
                value: _hasDelivery,
                onChanged: (v) => setState(() => _hasDelivery = v)),
            _buildServiceSwitch(
                icon: Icons.event_seat,
                label: 'حجز مسبق',
                value: _hasReservation,
                onChanged: (v) => setState(() => _hasReservation = v)),
            const SizedBox(height: 24),

            _buildSectionHeader(
              icon: Icons.tag,
              title: 'الكلمات المفتاحية',
              subtitle: 'مفصولة بفاصلة',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsCtrl,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'الكلمات المفتاحية',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.tag),
                hintText: 'معلم, ميدان, نصب',
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _savePlace,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(_isEditMode ? Icons.check : Icons.save),
                  label: Text(_isSaving
                      ? 'جارٍ الحفظ...'
                      : (_isEditMode ? 'حفظ التعديلات' : 'حفظ المكان')),
                  style: FilledButton.styleFrom(
                    backgroundColor: YaBaladiDesignTokens.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _isSaving ? null : _cancelEdit,
                  icon: const Icon(Icons.close),
                  label: const Text('إلغاء التعديل'),
                ),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── v5.4 banners ───
  Widget _buildEditModeBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'وضع التعديل مفعّل — يمكنك الآن تعديل البيانات',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility,
              color: theme.colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'أنت في وضع القراءة فقط — اضغط ✏️ بالأعلى للدخول في وضع التعديل',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جارٍ التحميل...'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل المكان' : 'إضافة مكان جديد'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 72, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('تعذر تحميل التصنيفات',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _categoriesError ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _loadCategories(),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: YaBaladiDesignTokens.primaryBlue, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    ]);
  }

  Widget _buildServiceSwitch({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: _isEditing ? onChanged : null,
        secondary: Icon(icon,
            color: value
                ? YaBaladiDesignTokens.primaryBlue
                : theme.colorScheme.outline),
        title: Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        activeThumbColor: YaBaladiDesignTokens.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
