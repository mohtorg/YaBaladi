// lib/features/admin/screens/add_place_screen.dart
//
// [v9.5.0 — 2026-11-15] — LINTER FIX: Added curly braces to single-line if in category onChanged,
//   and converted `var f` to `final f` in _loadFiltersForCategory loop.
// [v9.4.0 — 2026-11-12] — DYNAMIC FILTERS BY CATEGORY + PROTECTION:
//   - Filters are now loaded based on the selected category (general + specific).
//   - Filters reload automatically when category changes.
//   - Prevent changing category if the place has reviews (reviewCount > 0).
//   - Added `_loadFiltersForCategory()` and removed legacy `_loadDynamicFilters`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/location_url_helper.dart';
import '../../../core/services/audit_log_service.dart';
import '../../../core/utils/import_data_utility.dart';
import '../../../repositories/geo_zones_repository.dart';
import '../../../models/category.dart';
import '../../../models/governorate_config.dart';
import '../../../models/location_hierarchy_models.dart';
import '../../../repositories/categories_repository.dart';
import '../../../repositories/governorates_repository.dart';
import '../../../repositories/location_repository.dart';
import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/place_form/basic_info_section.dart';
import '../widgets/place_form/location_section.dart';
import '../widgets/place_form/contact_section.dart';
import '../widgets/place_form/tags_section.dart';

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
  bool _isFetchingLocation = false;
  String _fetchedZoneName = '';
  bool _isEditing = false;
  Map<String, dynamic>? _originalData;

  final CategoriesRepository _categoriesRepo = CategoriesRepository();
  final LocationRepository _locationRepo = LocationRepository();

  List<Category> _categories = const [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  List<Map<String, dynamic>> _availableFilters = [];
  bool _loadingFilters = true;
  final Map<String, dynamic> _dynamicFilterValues = {};

  // لحماية التصنيف عند وجود تقييمات
  int _originalReviewCount = 0;

  List<DistrictModel> _districtsList = [];
  List<ZoneModel> _zonesList = [];
  String? _selectedDistrictId;
  String? _selectedZoneId;

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

  GovernorateConfig? _selectedGovernorate;
  String _pendingGovName = '';

  List<GovernorateConfig> _governorates = const [];
  bool _loadingGovernorates = true;

  bool get _isEditMode => widget.placeId != null;
  String get _effectiveGovName =>
      _selectedGovernorate?.nameAr ?? _pendingGovName;

  @override
  void initState() {
    super.initState();
    _isEditing = !_isEditMode;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadGovernorates()]);

    if (_isEditMode) {
      final found = await _loadPlaceData();
      if (!found || !mounted) {
        return;
      }
      await _resolveInitialSelection();
      await _loadCategories(preserveSelection: true);
    } else {
      if (_governorates.isNotEmpty) {
        _selectedGovernorate = _governorates.first;
        await _fetchDistricts(_selectedGovernorate!.docId);
      }
      await _loadCategories();
    }

    // بعد معرفة التصنيف، نجلب الفلاتر المناسبة
    await _loadFiltersForCategory(_selectedCategory);
    if (mounted) {
      setState(() => _loadingFilters = false);
    }
  }

  /// ✅ دالة جديدة: تجلب الفلاتر العامة + الخاصة بالتصنيف
  Future<void> _loadFiltersForCategory(String categoryId) async {
    setState(() => _loadingFilters = true);

    try {
      // 1. الفلاتر العامة
      final generalSnap = await FirebaseFirestore.instance
          .collection('filters')
          .where('isActive', isEqualTo: true)
          .where('categoryId', isNull: true)
          .get();

      // 2. الفلاتر الخاصة بالتصنيف
      final specificSnap = await FirebaseFirestore.instance
          .collection('filters')
          .where('isActive', isEqualTo: true)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      // 3. دمج + ترتيب
      final allDocs = [...generalSnap.docs, ...specificSnap.docs];
      final filtersList = allDocs.map((d) => d.data()).toList()
        ..sort((a, b) => ((a['order'] as num?)?.toInt() ?? 0)
            .compareTo((b['order'] as num?)?.toInt() ?? 0));

      // 4. تنظيف القيم القديمة التي لم تعد موجودة
      final validKeys = filtersList
          .map((f) => f['fieldKey']?.toString() ?? '')
          .where((k) => k.isNotEmpty)
          .toSet();
      _dynamicFilterValues.removeWhere((key, _) => !validKeys.contains(key));

      // 5. تهيئة قيم جديدة
      for (final f in filtersList) {
        final key = f['fieldKey']?.toString() ?? '';
        if (key.isEmpty) {
          continue;
        }
        if (f['type'] == 'boolean' && !_dynamicFilterValues.containsKey(key)) {
          _dynamicFilterValues[key] = false;
        }
      }

      if (mounted) {
        setState(() {
          _availableFilters = filtersList;
          _loadingFilters = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading filters: $e');
      if (mounted) {
        setState(() {
          _availableFilters = [];
          _loadingFilters = false;
        });
      }
    }
  }

  Future<void> _fetchDistricts(String govId) async {
    setState(() {
      _districtsList = [];
      _selectedDistrictId = null;
      _zonesList = [];
      _selectedZoneId = null;
    });
    final districts = await _locationRepo.getDistricts(govId);
    if (mounted) {
      setState(() => _districtsList = districts);
    }
  }

  Future<void> _fetchZones(String districtId) async {
    setState(() {
      _zonesList = [];
      _selectedZoneId = null;
    });
    final zones = await _locationRepo.getZones(districtId);
    if (mounted) {
      setState(() => _zonesList = zones);
    }
  }

  void _showImportMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استيراد بيانات'),
        content:
            const Text('اختر نوع البيانات التي تريد استيرادها من ملف CSV:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ImportDataUtility.importCsvToFirestore(
                  collectionName: 'districts', isDistrictCollection: true);
            },
            child: const Text('استيراد الأحياء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ImportDataUtility.importCsvToFirestore(
                  collectionName: 'zones', isDistrictCollection: false);
            },
            child: const Text('استيراد المناطق'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadGovernorates() async {
    try {
      final govs =
          await GovernoratesRepository.instance.watchActiveGovernorates().first;
      if (!mounted) {
        return;
      }
      setState(() {
        _governorates = govs;
        _loadingGovernorates = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _governorates = const [];
        _loadingGovernorates = false;
      });
    }
  }

  Future<void> _resolveInitialSelection() async {
    if (_pendingGovName.isEmpty) {
      if (_governorates.isNotEmpty) {
        _selectedGovernorate = _governorates.first;
        await _fetchDistricts(_selectedGovernorate!.docId);
      }
      if (mounted) {
        setState(() {});
      }
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

    if (_selectedGovernorate != null &&
        _selectedGovernorate!.docId != '__legacy_gov__') {
      await _fetchDistricts(_selectedGovernorate!.docId);
    }
    if (_selectedDistrictId != null) {
      await _fetchZones(_selectedDistrictId!);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCategories({bool preserveSelection = false}) async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final cats = await _categoriesRepo.getAllActive();
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
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
          Navigator.pop(context);
        }
        return false;
      }
      final data = doc.data() ?? <String, dynamic>{};
      if (mounted) {
        _originalData = Map<String, dynamic>.from(data);
        setState(() {
          _nameArCtrl.text =
              data['nameAr']?.toString() ?? data['name']?.toString() ?? '';
          _nameEnCtrl.text =
              data['nameEn']?.toString() ?? data['name_en']?.toString() ?? '';
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
          _priceLevel = _parseSafePriceLevel(data['priceLevel']);

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

          _selectedDistrictId = data['districtId']?.toString();
          _selectedZoneId = data['zoneId']?.toString();

          // ✅ حفظ عدد التقييمات الأصلي
          _originalReviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

          // ملء قيم الفلاتر من البيانات المحفوظة (قبل تحميل الفلاتر)
          final reserved = _reservedFields();
          data.forEach((key, value) {
            if (!reserved.contains(key) && value != null) {
              _dynamicFilterValues[key] = value;
            }
          });
        });
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _fetchCurrentLocation() async {
    if (!_isEditing) {
      return;
    }
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
              const LocationSettings(accuracy: LocationAccuracy.high));
      final geoZone = await GeoZonesRepository.instance
          .findZoneForPoint(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _latCtrl.text = position.latitude.toStringAsFixed(6);
          _lngCtrl.text = position.longitude.toStringAsFixed(6);
          _fetchedZoneName = geoZone?.nameAr ?? 'غير معروف';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ تم جلب الموقع والمنطقة'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  void _enterEditMode() {
    if (_isSaving) {
      return;
    }
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    if (_isSaving) {
      return;
    }
    final d = _originalData;
    if (d == null) {
      setState(() => _isEditing = false);
      return;
    }
    setState(() {
      _nameArCtrl.text = d['nameAr']?.toString() ?? d['name']?.toString() ?? '';
      _nameEnCtrl.text =
          d['nameEn']?.toString() ?? d['name_en']?.toString() ?? '';
      _descCtrl.text = d['description']?.toString() ?? '';
      _addressCtrl.text = d['address']?.toString() ?? '';
      _phoneCtrl.text =
          d['phone']?.toString() ?? d['businessPhone']?.toString() ?? '';
      _websiteCtrl.text = d['website']?.toString() ?? '';
      _emailCtrl.text = d['businessEmail']?.toString() ?? '';
      _facebookCtrl.text = d['facebookPage']?.toString() ?? '';
      _tagsCtrl.text =
          (d['tags'] as List?)?.map((e) => e.toString()).join(', ') ?? '';
      _priceLevel = _parseSafePriceLevel(d['priceLevel']);

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

      _selectedDistrictId = d['districtId']?.toString();
      _selectedZoneId = d['zoneId']?.toString();

      // إعادة تعيين القيم
      _dynamicFilterValues.clear();
      final reserved = _reservedFields();
      d.forEach((key, value) {
        if (!reserved.contains(key) && value != null) {
          _dynamicFilterValues[key] = value;
        }
      });

      _pasteUrlCtrl.clear();
      _isEditing = false;
    });
    _resolveInitialSelection();
    // إعادة تحميل الفلاتر بناءً على التصنيف المختار
    _loadFiltersForCategory(_selectedCategory);
  }

  int _parseSafePriceLevel(dynamic val) {
    final int parsed = (val as num?)?.toInt() ?? 1;
    return (parsed >= 1 && parsed <= 4) ? parsed : 1;
  }

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'restroom':
        return Icons.wc;
      case 'accessibility':
        return Icons.accessible;
      case 'family_friendly':
        return Icons.family_restroom;
      case 'shade':
        return Icons.beach_access;
      case 'delivery':
        return Icons.delivery_dining;
      case 'reservation':
        return Icons.event_seat;
      case 'halal':
        return Icons.restaurant_menu;
      default:
        return Icons.check_circle_outline;
    }
  }

  /// ✅ الحقول المحجوزة التي لا يجب أن تتعارض مع الفلاتر
  Set<String> _reservedFields() {
    return {
      'nameAr',
      'name',
      'nameEn',
      'name_en',
      'description',
      'categoryId',
      'governorate',
      'districtId',
      'districtName',
      'zoneId',
      'zoneName',
      'city',
      'geoZoneName',
      'address',
      'tags',
      'location',
      'latitude',
      'longitude',
      'geohash',
      'googleMapsUrl',
      'map_url',
      'phone',
      'businessPhone',
      'website',
      'businessEmail',
      'facebookPage',
      'priceLevel',
      'updatedAt',
      'createdAt',
      'created_at',
      'addedBy',
      'isApproved',
      'isActive',
      'is_active',
      'averageRating',
      'reviewCount',
      'imageUrls',
      'ownerId',
      'pin_obfuscated',
    };
  }

  Future<void> _savePlace() async {
    if (!_isEditing) {
      return;
    }
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final admin = context.read<AuthController>();

    if (_effectiveGovName.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('❌ الرجاء اختيار المحافظة'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final double lat = double.parse(_latCtrl.text.trim());
      final double lng = double.parse(_lngCtrl.text.trim());
      final geoPoint = GeoPoint(lat, lng);
      final geohash = _encodeGeohash(lat, lng);
      final googleMapsUrl =
          LocationUrlHelper.getSmartMapUrl(lat: lat, lng: lng);

      final selectedDistrict = _districtsList.firstWhere(
          (d) => d.id == _selectedDistrictId,
          orElse: () => throw 'اختر الحي');
      final selectedZone = _zonesList.firstWhere((z) => z.id == _selectedZoneId,
          orElse: () => throw 'اختر المنطقة');

      final tags = _tagsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final commonData = {
        'nameAr': _nameArCtrl.text.trim(),
        'name': _nameArCtrl.text.trim(),
        'nameEn': _nameEnCtrl.text.trim().isEmpty
            ? _nameArCtrl.text.trim()
            : _nameEnCtrl.text.trim(),
        'name_en': _nameEnCtrl.text.trim().isEmpty
            ? _nameArCtrl.text.trim()
            : _nameEnCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'categoryId': _selectedCategory,
        'governorate': _effectiveGovName,
        'districtId': _selectedDistrictId,
        'districtName': selectedDistrict.nameAr,
        'zoneId': _selectedZoneId,
        'zoneName': selectedZone.nameAr,
        'city': selectedDistrict.nameAr,
        'geoZoneName': selectedZone.nameAr,
        'address': _addressCtrl.text.trim(),
        'tags': tags,
        'location': geoPoint,
        'latitude': lat,
        'longitude': lng,
        'geohash': geohash,
        'googleMapsUrl': googleMapsUrl,
        'map_url': googleMapsUrl,
        'phone': _phoneCtrl.text.trim(),
        'businessPhone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'businessEmail': _emailCtrl.text.trim(),
        'facebookPage': _facebookCtrl.text.trim(),
        'priceLevel': _priceLevel,
        ..._dynamicFilterValues,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final placeName = _nameArCtrl.text.trim();

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
        await AuditLogService.logAction(
          action: 'تعديل مكان',
          adminName: admin.displayName,
          target: placeName,
          details:
              'التصنيف: $_selectedCategory | المحافظة: $_effectiveGovName | placeId: ${widget.placeId}',
          severity: 'low',
        );
        if (mounted) {
          messenger.showSnackBar(const SnackBar(
              content: Text('✅ تم تحديث المكان'),
              backgroundColor: Colors.green));
          navigator.pop(true);
        }
      } else {
        final newDoc =
            await FirebaseFirestore.instance.collection('places').add({
          ...commonData,
          'addedBy': 'admin',
          'isApproved': true,
          'isActive': true,
          'is_active': true,
          'averageRating': 0.0,
          'reviewCount': 0,
          'imageUrls': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        });
        await _categoriesRepo.incrementPlacesCount(_selectedCategory, 1);
        await AuditLogService.logAction(
          action: 'إضافة مكان جديد',
          adminName: admin.displayName,
          target: placeName,
          details:
              'التصنيف: $_selectedCategory | المحافظة: $_effectiveGovName | الموقع: $lat,$lng | placeId: ${newDoc.id}',
          severity: 'medium',
        );
        if (mounted) {
          messenger.showSnackBar(const SnackBar(
              content: Text('✅ تم إضافة المكان'),
              backgroundColor: Colors.green));
          navigator.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
    if (text.isEmpty) {
      return 'مطلوب';
    }
    final n = double.tryParse(text);
    if (n == null) {
      return 'رقم غير صحيح';
    }
    if (n < -limit || n > limit) {
      return 'خارج النطاق';
    }
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
                    child: Text(c.nameAr, overflow: TextOverflow.ellipsis)),
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
                  overflow: TextOverflow.ellipsis)),
        ]),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<String>> _governorateItems() {
    final items = _governorates
        .map((g) =>
            DropdownMenuItem<String>(value: g.docId, child: Text(g.nameAr)))
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
                  overflow: TextOverflow.ellipsis)),
        ]),
      ));
    }
    return items;
  }

  GovernorateConfig? _findGovByDocId(String? docId) {
    if (docId == null) {
      return null;
    }
    for (final g in _governorates) {
      if (g.docId == docId) {
        return g;
      }
    }
    return null;
  }

  void _extractFromUrl() async {
    final coords = LocationUrlHelper.extractCoordinates(_pasteUrlCtrl.text);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ لم يتم التعرف على إحداثيات في الرابط.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _latCtrl.text = coords.lat.toString();
      _lngCtrl.text = coords.lng.toString();
    });
    try {
      final geoZone = await GeoZonesRepository.instance
          .findZoneForPoint(coords.lat, coords.lng);
      if (mounted && geoZone != null) {
        setState(() => _fetchedZoneName = geoZone.nameAr);
      }
    } catch (e) {
      debugPrint('Error extracting zone from URL: $e');
    }
  }

  Future<void> _previewOnMap() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('أدخل إحداثيات صحيحة أولاً'),
          backgroundColor: Colors.orange));
      return;
    }
    final url = LocationUrlHelper.getSmartMapUrl(lat: lat, lng: lng);
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن إنشاء رابط الخريطة')));
      }
      return;
    }
    final opened = await LocationUrlHelper.openSmart(url);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('لا يمكن فتح الخريطة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading ||
        _categoriesLoading ||
        _loadingGovernorates ||
        _loadingFilters) {
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
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            tooltip: 'استيراد ملفات CSV',
            onPressed: _showImportMenu,
          ),
          ...(_isEditMode
              ? (_isEditing
                  ? [
                      IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'إلغاء التعديل',
                          onPressed: _isSaving ? null : _cancelEdit),
                      IconButton(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check),
                        tooltip: 'حفظ التعديلات',
                        onPressed: _isSaving ? null : _savePlace,
                      ),
                    ]
                  : [
                      IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'تعديل البيانات',
                          onPressed: _enterEditMode)
                    ])
              : []),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEditMode && _isEditing) _buildEditModeBanner(theme),
            if (_isEditMode && !_isEditing) _buildReadOnlyBanner(theme),
            BasicInfoSection(
                nameArCtrl: _nameArCtrl,
                nameEnCtrl: _nameEnCtrl,
                descCtrl: _descCtrl,
                isEditing: _isEditing,
                theme: theme),
            const SizedBox(height: 24),
            _buildSectionHeader(
                icon: Icons.place,
                title: 'التصنيف والموقع',
                subtitle: 'التصنيف، المحافظة، والموقع'),
            const SizedBox(height: 12),
            LocationSection(
              categoryDropdown: DropdownButtonFormField<String>(
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
                        if (val == null) {
                          return;
                        }
                        // ✅ منع تغيير التصنيف إذا كان المكان له تقييمات
                        if (_isEditMode &&
                            _originalReviewCount > 0 &&
                            val != _originalCategory) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'لا يمكن تغيير تصنيف مكان له تقييمات سابقة. تواصل مع الدعم إذا كنت متأكداً.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 4),
                            ),
                          );
                          return;
                        }
                        setState(() => _selectedCategory = val);
                        // ✅ إعادة تحميل الفلاتر للتصنيف الجديد
                        _loadFiltersForCategory(val);
                      }
                    : null,
              ),
              governorateDropdown: DropdownButtonFormField<String>(
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
                    ? (val) {
                        final gov = _findGovByDocId(val);
                        if (gov != null) {
                          setState(() => _selectedGovernorate = gov);
                          _fetchDistricts(gov.docId);
                        }
                      }
                    : null,
              ),
              districtDropdown: DropdownButtonFormField<String>(
                key: ValueKey('dist_${_selectedDistrictId}_$_isEditing'),
                initialValue: _selectedDistrictId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'الحي *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.map),
                  filled: !_isEditing,
                  fillColor: !_isEditing
                      ? theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3)
                      : null,
                ),
                items: _districtsList
                    .map((d) => DropdownMenuItem<String>(
                        value: d.id, child: Text(d.nameAr)))
                    .toList(),
                validator: (v) => v == null ? 'اختر الحي' : null,
                onChanged: _isEditing
                    ? (val) {
                        setState(() => _selectedDistrictId = val);
                        if (val != null) {
                          _fetchZones(val);
                        }
                      }
                    : null,
              ),
              zoneDropdown: DropdownButtonFormField<String>(
                key: ValueKey('zone_${_selectedZoneId}_$_isEditing'),
                initialValue: _selectedZoneId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'المنطقة *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                  filled: !_isEditing,
                  fillColor: !_isEditing
                      ? theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3)
                      : null,
                ),
                items: _zonesList
                    .map((z) => DropdownMenuItem<String>(
                        value: z.id, child: Text(z.nameAr)))
                    .toList(),
                validator: (v) => v == null ? 'اختر المنطقة' : null,
                onChanged: _isEditing && _selectedDistrictId != null
                    ? (val) {
                        setState(() => _selectedZoneId = val);
                      }
                    : null,
              ),
              addressCtrl: _addressCtrl,
              pasteUrlCtrl: _pasteUrlCtrl,
              latCtrl: _latCtrl,
              lngCtrl: _lngCtrl,
              isEditing: _isEditing,
              isFetchingLocation: _isFetchingLocation,
              fetchedZoneName: _fetchedZoneName,
              onFetchLocation: _fetchCurrentLocation,
              onExtractUrl: _extractFromUrl,
              onPreviewMap: _previewOnMap,
              latValidator: (v) => _validateCoordinate(v, limit: 90),
              lngValidator: (v) => _validateCoordinate(v, limit: 180),
              theme: theme,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
                icon: Icons.phone,
                title: 'معلومات التواصل',
                subtitle: 'الهاتف والموقع (اختياري)'),
            const SizedBox(height: 12),
            ContactSection(
              phoneCtrl: _phoneCtrl,
              websiteCtrl: _websiteCtrl,
              emailCtrl: _emailCtrl,
              facebookCtrl: _facebookCtrl,
              priceDropdown: DropdownButtonFormField<int>(
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
              isEditing: _isEditing,
              theme: theme,
            ),
            const SizedBox(height: 24),
            if (_availableFilters.isNotEmpty) ...[
              _buildSectionHeader(
                  icon: Icons.room_service,
                  title: 'الخدمات المتاحة',
                  subtitle: 'حدد الخدمات المتوفرة في المكان'),
              const SizedBox(height: 12),
              ..._availableFilters.map((filter) {
                final String type = filter['type']?.toString() ?? '';
                final String fieldKey = filter['fieldKey']?.toString() ?? '';
                final String nameAr = filter['nameAr']?.toString() ?? '';
                final String iconName = filter['icon']?.toString() ?? '';
                if (type == 'boolean' && fieldKey.isNotEmpty) {
                  return _buildServiceSwitch(
                    icon: _getIconData(iconName),
                    label: nameAr,
                    value: _dynamicFilterValues[fieldKey] == true,
                    onChanged: (v) =>
                        setState(() => _dynamicFilterValues[fieldKey] = v),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
              const SizedBox(height: 24),
            ],
            _buildSectionHeader(
                icon: Icons.tag,
                title: 'الكلمات المفتاحية',
                subtitle: 'مفصولة بفاصلة'),
            const SizedBox(height: 12),
            TagsSection(
                tagsCtrl: _tagsCtrl, isEditing: _isEditing, theme: theme),
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
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                    onPressed: _isSaving ? null : _cancelEdit,
                    icon: const Icon(Icons.close),
                    label: const Text('إلغاء التعديل')),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEditModeBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300, width: 1.2)),
      child: Row(children: [
        Icon(Icons.edit, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text('وضع التعديل مفعّل — يمكنك الآن تعديل البيانات',
                style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 13))),
      ]),
    );
  }

  Widget _buildReadOnlyBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Row(children: [
        Icon(Icons.visibility,
            color: theme.colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                'أنت في وضع القراءة فقط — اضغط ✏️ بالأعلى للدخول في وضع التعديل',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13))),
      ]),
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
            onPressed: () => Navigator.pop(context)),
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
            onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off, size: 72, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('تعذر تحميل البيانات',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_categoriesError ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            FilledButton.icon(
                onPressed: () => _loadCategories(),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة')),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: YaBaladiDesignTokens.primaryBlue, size: 20)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(subtitle,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ])),
    ]);
  }

  Widget _buildServiceSwitch(
      {required IconData icon,
      required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}
