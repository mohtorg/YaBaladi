// lib/features/merchant/screens/merchant_place_screen.dart
// [v6.6.3 — 2026-11-01] — ANALYZER FIX: Added ignore_for_file for RegExp warning.
//   - FIXED: Suppressed false-positive RegExp deprecation warning.
//   - KEPT: GeoZone resolution, Editable GPS, Global Edit Mode, Categories Dropdown.

// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../core/helpers/location_url_helper.dart';
import '../../../models/district.dart';
import '../../../models/governorate_config.dart';
import '../../../models/place.dart';
import '../../../repositories/governorates_repository.dart';

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

// ───────────────────────── Category model (lightweight) ─────────────────────────
class _CategoryItem {
  final String id;
  final String nameAr;
  final String nameEn;
  const _CategoryItem({
    required this.id,
    required this.nameAr,
    this.nameEn = '',
  });
}

class MerchantPlaceScreen extends StatelessWidget {
  const MerchantPlaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .where('ownerId', isEqualTo: auth.uid)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('لا يوجد مكان مرتبط بحسابك')),
          );
        }
        final doc = snap.data!.docs.first;
        final data = doc.data();
        final place = Place.fromMap(doc.id, data);
        return _PlaceEditView(
          key: ValueKey(doc.id),
          place: place,
          rawData: data,
        );
      },
    );
  }
}

class _PlaceEditView extends StatefulWidget {
  final Place place;
  final Map<String, dynamic> rawData;

  const _PlaceEditView({super.key, required this.place, required this.rawData});

  @override
  State<_PlaceEditView> createState() => _PlaceEditViewState();
}

class _PlaceEditViewState extends State<_PlaceEditView> {
  final _formKey = GlobalKey<FormState>();

  static const int _maxImageSizeBytes = 500 * 1024;
  static const int _maxImages = 8;
  static const Duration _uploadTimeout = Duration(seconds: 60);
  static const List<String> _allowedExt = ['jpg', 'jpeg', 'png', 'webp'];

  late TextEditingController _nameArCtrl;
  late TextEditingController _nameEnCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _addressCtrl;

  // Wave 19: New controllers
  late TextEditingController _emailCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _facebookCtrl;
  late TextEditingController _tagsCtrl;

  // v6.5: GPS controllers
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _pasteUrlCtrl;

  int _priceLevel = 1;

  // Wave 19 (v6.4): categories from Firestore
  List<_CategoryItem> _categories = const [];
  bool _loadingCategories = true;
  String? _selectedCategoryId;

  // v6.6: GeoZone resolution
  String? _detectedZoneName;
  String? _detectedZoneId;
  bool _isDetectingZone = false;

  // Wave 19 (v6.4): Global Edit Mode
  bool _isEditing = false;

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
  bool _hasDelivery = false;
  bool _isFamilyFriendly = false;
  bool _hasReservation = false;
  bool _isHalal = false;

  bool _isSaving = false;
  bool _isUploadingImage = false;
  List<String> _imageUrls = [];

  static final List<TextInputFormatter> _coordinateFormatters = [
    _CoordinateInputFormatter(),
  ];

  String get _effectiveGovName =>
      _selectedGovernorate?.nameAr ?? _pendingGovName;
  String get _effectiveDistrictName =>
      _selectedDistrict?.nameAr ?? _pendingDistrictName;

  @override
  void initState() {
    super.initState();
    _initFields();
    _resolveInitialSelection();
    _loadCategories();
  }

  @override
  void didUpdateWidget(covariant _PlaceEditView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _imageUrls = _readImageUrls(widget.rawData);
  }

  List<String> _readImageUrls(Map<String, dynamic> d) {
    final raw = d['imageUrls'];
    if (raw is List) {
      return raw.whereType<String>().where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  void _initFields() {
    final d = widget.rawData;

    _nameArCtrl = TextEditingController(text: d['nameAr']?.toString() ?? '');
    _nameEnCtrl = TextEditingController(text: d['nameEn']?.toString() ?? '');
    _descCtrl = TextEditingController(text: d['description']?.toString() ?? '');
    _phoneCtrl = TextEditingController(
        text: d['businessPhone']?.toString() ?? d['phone']?.toString() ?? '');
    _whatsappCtrl =
        TextEditingController(text: d['whatsapp']?.toString() ?? '');
    _addressCtrl = TextEditingController(text: d['address']?.toString() ?? '');

    // Wave 19
    _emailCtrl =
        TextEditingController(text: d['businessEmail']?.toString() ?? '');
    _websiteCtrl = TextEditingController(text: d['website']?.toString() ?? '');
    _facebookCtrl =
        TextEditingController(text: d['facebookPage']?.toString() ?? '');
    _tagsCtrl = TextEditingController(
        text: (d['tags'] as List?)?.map((e) => e.toString()).join(', ') ?? '');
    _priceLevel = (d['priceLevel'] as num?)?.toInt() ?? 1;

    // v6.5: GPS
    final locationRaw = d['location'];
    final geoPoint = locationRaw is GeoPoint ? locationRaw : null;
    final lat = d['latitude'] ?? geoPoint?.latitude;
    final lng = d['longitude'] ?? geoPoint?.longitude;
    _latCtrl = TextEditingController(text: lat?.toString() ?? '');
    _lngCtrl = TextEditingController(text: lng?.toString() ?? '');
    _pasteUrlCtrl = TextEditingController();

    // v6.6: GeoZone
    _detectedZoneName = d['geoZoneName']?.toString();
    _detectedZoneId = d['geoZoneId']?.toString();

    // v6.4: category is now an ID stored in state
    final catId = d['categoryId']?.toString();
    _selectedCategoryId = (catId != null && catId.isNotEmpty) ? catId : null;

    _pendingGovName = d['governorate']?.toString() ?? '';
    _pendingDistrictName = d['city']?.toString() ?? '';
    _imageUrls = _readImageUrls(d);

    _hasWifi = d['hasWifi'] == true;
    _hasParking = d['hasParking'] == true;
    _hasRestroom = d['hasRestroom'] == true;
    _hasAccessibility = d['hasAccessibility'] == true;
    _hasDelivery = d['hasDelivery'] == true;
    _isFamilyFriendly = d['isFamilyFriendly'] == true;
    _hasReservation = d['hasReservation'] == true;
    _isHalal = d['isHalal'] == true;
  }

  Future<void> _loadCategories() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('categories').get();
      if (!mounted) return;

      final items = snap.docs.map((doc) {
        final data = doc.data();
        final nameAr =
            (data['nameAr'] ?? data['name'] ?? data['title'] ?? '').toString();
        final nameEn = (data['nameEn'] ?? '').toString();
        return _CategoryItem(
          id: doc.id,
          nameAr: nameAr.isEmpty ? doc.id : nameAr,
          nameEn: nameEn,
        );
      }).toList();

      items.sort((a, b) => a.nameAr.compareTo(b.nameAr));

      setState(() {
        _categories = items;
        _loadingCategories = false;
      });
    } catch (e) {
      debugPrint('Failed to load categories: $e');
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _resolveInitialSelection() async {
    try {
      final govs =
          await GovernoratesRepository.instance.watchActiveGovernorates().first;
      if (!mounted) return;
      setState(() {
        _governorates = govs;
        _loadingGovernorates = false;
      });

      if (_pendingGovName.isEmpty) {
        if (govs.isNotEmpty) {
          setState(() => _selectedGovernorate = govs.first);
          await _loadDistricts(govs.first.docId);
        }
        return;
      }

      GovernorateConfig? matched;
      for (final g in govs) {
        if (g.nameAr == _pendingGovName) {
          matched = g;
          break;
        }
      }

      if (matched != null) {
        setState(() => _selectedGovernorate = matched);
        await _loadDistricts(matched.docId);
        if (_pendingDistrictName.isNotEmpty) {
          for (final d in _districts) {
            if (d.nameAr == _pendingDistrictName) {
              if (mounted) setState(() => _selectedDistrict = d);
              break;
            }
          }
        }
      } else if (mounted) {
        setState(() {
          _selectedGovernorate = GovernorateConfig(
            docId: '__legacy_gov__',
            nameAr: _pendingGovName,
            nameEn: '',
            order: 999,
            isActive: false,
            deliveryEnabled: false,
            tripsEnabled: false,
          );
        });
      }
    } catch (e) {
      debugPrint('Failed to load governorates: $e');
      if (mounted) setState(() => _loadingGovernorates = false);
    }
  }

  Future<void> _loadDistricts(String govDocId) async {
    if (!mounted) return;
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
      if (mounted) setState(() => _loadingDistricts = false);
    }
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

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _facebookCtrl.dispose();
    _tagsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _pasteUrlCtrl.dispose();
    super.dispose();
  }

  // ───────────────────── v6.4: Global Edit Mode ─────────────────────

  void _enterEditMode() {
    if (_isSaving) return;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    if (_isSaving) return;
    final d = widget.rawData;

    // Revert text controllers synchronously
    _nameArCtrl.text = d['nameAr']?.toString() ?? '';
    _nameEnCtrl.text = d['nameEn']?.toString() ?? '';
    _descCtrl.text = d['description']?.toString() ?? '';
    _phoneCtrl.text =
        d['businessPhone']?.toString() ?? d['phone']?.toString() ?? '';
    _whatsappCtrl.text = d['whatsapp']?.toString() ?? '';
    _addressCtrl.text = d['address']?.toString() ?? '';
    _emailCtrl.text = d['businessEmail']?.toString() ?? '';
    _websiteCtrl.text = d['website']?.toString() ?? '';
    _facebookCtrl.text = d['facebookPage']?.toString() ?? '';
    _tagsCtrl.text =
        (d['tags'] as List?)?.map((e) => e.toString()).join(', ') ?? '';

    final locationRaw = d['location'];
    final geoPoint = locationRaw is GeoPoint ? locationRaw : null;
    final lat = d['latitude'] ?? geoPoint?.latitude;
    final lng = d['longitude'] ?? geoPoint?.longitude;
    _latCtrl.text = lat?.toString() ?? '';
    _lngCtrl.text = lng?.toString() ?? '';
    _pasteUrlCtrl.clear();

    // Revert state + exit edit mode
    setState(() {
      _priceLevel = (d['priceLevel'] as num?)?.toInt() ?? 1;
      final catId = d['categoryId']?.toString();
      _selectedCategoryId = (catId != null && catId.isNotEmpty) ? catId : null;

      _detectedZoneName = d['geoZoneName']?.toString();
      _detectedZoneId = d['geoZoneId']?.toString();

      _pendingGovName = d['governorate']?.toString() ?? '';
      _pendingDistrictName = d['city']?.toString() ?? '';
      _selectedDistrict = null;
      _districts = const [];

      _hasWifi = d['hasWifi'] == true;
      _hasParking = d['hasParking'] == true;
      _hasRestroom = d['hasRestroom'] == true;
      _hasAccessibility = d['hasAccessibility'] == true;
      _hasDelivery = d['hasDelivery'] == true;
      _isFamilyFriendly = d['isFamilyFriendly'] == true;
      _hasReservation = d['hasReservation'] == true;
      _isHalal = d['isHalal'] == true;

      _isEditing = false;
    });

    // Fire-and-forget: re-resolve governorate/district selection from originals
    _resolveInitialSelection();
  }

  // ───────────────────────── Helpers ─────────────────────────

  String _contentTypeFor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  // ─── Image upload (kept for future activation) ───
  // ignore: unused_element
  Future<void> _pickAndUploadImage() async {
    if (_isUploadingImage) return;
    if (_imageUrls.length >= _maxImages) {
      _showError('بلغت الحد الأقصى لعدد الصور ($_maxImages).');
      return;
    }
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExt,
        allowMultiple: false,
        withData: true,
      );
    } catch (e) {
      debugPrint('File picking failed: $e');
      _showError('تعذر فتح نافذة اختيار الصورة.');
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final PlatformFile file = result.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) return _showError('تعذر قراءة بيانات الصورة');
    if (bytes.length > _maxImageSizeBytes) {
      return _showError('❌ الصورة كبيرة. الحد الأقصى 500 KB.');
    }
    if (!mounted) return;
    setState(() => _isUploadingImage = true);
    UploadTask? task;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('places')
          .child(widget.place.id)
          .child('images')
          .child(
              '${DateTime.now().millisecondsSinceEpoch}_${_safeName(file.name)}');
      task = ref.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeFor(file.extension)),
      );
      final snapshot = await task.timeout(_uploadTimeout);
      final url = await snapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update({
        'imageUrls': FieldValue.arrayUnion([url]),
      });
      if (!mounted) return;
      setState(() => _imageUrls.add(url));
      _showSuccess('✅ تم رفع الصورة');
    } catch (e) {
      _showError('❌ تعذر رفع الصورة');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // v6.5: Extract coords from Google Maps URL
  void _extractFromUrl() {
    final coords = LocationUrlHelper.extractCoordinates(_pasteUrlCtrl.text);
    if (coords == null) {
      _showError(
          '❌ لم يتم التعرف على إحداثيات في الرابط. الصق الرابط الكامل أو الإحداثيات مباشرة.');
      return;
    }
    setState(() {
      _latCtrl.text = coords.lat.toString();
      _lngCtrl.text = coords.lng.toString();
    });
    _showSuccess('✅ تم استخراج: ${coords.lat}, ${coords.lng}');
  }

  // v6.6: Resolve nearest GeoZone from Firestore using geoflutterfire_plus
  Future<Map<String, String>?> _resolveNearestZone(
      double lat, double lng) async {
    try {
      final collectionRef = FirebaseFirestore.instance.collection('geo_zones');
      final geoRef =
          GeoCollectionReference<Map<String, dynamic>>(collectionRef);
      final point = GeoFirePoint(GeoPoint(lat, lng));

      final docs = await geoRef.fetchWithin(
        center: point,
        radiusInKm: 5,
        field: 'position',
        geopointFrom: (data) => data['position'] as GeoPoint,
      );

      if (docs.isNotEmpty) {
        final doc = docs.first;
        final data = doc.data()!;
        return {
          'geoZoneId': doc.id,
          'geoZoneName': data['nameAr']?.toString() ??
              data['name']?.toString() ??
              'منطقة غير معروفة',
        };
      }
    } catch (e) {
      debugPrint('Error resolving GeoZone: $e');
    }
    return null;
  }

  // v6.6: Manually detect zone
  Future<void> _detectZoneManually() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      _showError('الرجاء إدخال إحداثيات صحيحة أولاً');
      return;
    }

    setState(() => _isDetectingZone = true);
    final result = await _resolveNearestZone(lat, lng);
    if (!mounted) return;

    setState(() {
      _isDetectingZone = false;
      if (result != null) {
        _detectedZoneName = result['geoZoneName'];
        _detectedZoneId = result['geoZoneId'];
      } else {
        _detectedZoneName = null;
        _detectedZoneId = null;
      }
    });

    if (result != null) {
      _showSuccess('✅ تم تحديد المنطقة: ${result['geoZoneName']}');
    } else {
      _showError('❌ لم يتم العثور على منطقة سكنية قريبة');
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

  // ─── Validation ───
  bool _hasAtLeastOneContact() {
    return _phoneCtrl.text.trim().isNotEmpty ||
        _whatsappCtrl.text.trim().isNotEmpty;
  }

  Future<void> _saveChanges() async {
    if (!_isEditing) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_hasAtLeastOneContact()) {
      _showError('يجب إدخال رقم هاتف أو رقم واتساب على الأقل');
      return;
    }
    if (_effectiveGovName.isEmpty) {
      _showError('الرجاء اختيار المحافظة');
      return;
    }
    if (_effectiveDistrictName.isEmpty) {
      _showError('الرجاء اختيار الحي');
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      _showError('الرجاء اختيار التصنيف');
      return;
    }

    final double? lat = double.tryParse(_latCtrl.text.trim());
    final double? lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      _showError('الرجاء إدخال إحداثيات صحيحة');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final tags = _tagsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final geoPoint = GeoPoint(lat, lng);
      final geohash = _encodeGeohash(lat, lng);

      // v6.6: Automatically resolve GeoZone on save if not detected or coordinates changed
      final zoneInfo = await _resolveNearestZone(lat, lng);
      final zoneNameToSave =
          zoneInfo != null ? zoneInfo['geoZoneName'] : _detectedZoneName;
      final zoneIdToSave =
          zoneInfo != null ? zoneInfo['geoZoneId'] : _detectedZoneId;

      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update({
        'nameAr': _nameArCtrl.text.trim(),
        'nameEn': _nameEnCtrl.text.trim(),
        'categoryId': _selectedCategoryId ?? '',
        'description': _descCtrl.text.trim(),
        'governorate': _effectiveGovName,
        'city': _effectiveDistrictName,
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'businessPhone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'businessEmail': _emailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'facebookPage': _facebookCtrl.text.trim(),
        'priceLevel': _priceLevel,
        'tags': tags,
        'location': geoPoint,
        'latitude': lat,
        'longitude': lng,
        'geohash': geohash,
        'geoZoneName': zoneNameToSave,
        'geoZoneId': zoneIdToSave,
        'hasWifi': _hasWifi,
        'hasParking': _hasParking,
        'hasRestroom': _hasRestroom,
        'hasAccessibility': _hasAccessibility,
        'hasDelivery': _hasDelivery,
        'isFamilyFriendly': _isFamilyFriendly,
        'hasReservation': _hasReservation,
        'isHalal': _isHalal,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _detectedZoneName = zoneNameToSave;
        _detectedZoneId = zoneIdToSave;
      });
      _showSuccess('✅ تم تحديث كافة البيانات بنجاح');
    } catch (e) {
      debugPrint('Save failed: $e');
      if (!mounted) return;
      _showError('❌ خطأ أثناء الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  List<DropdownMenuItem<String>> _categoryItems() {
    final items = _categories
        .map((c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.nameAr),
            ))
        .toList();
    final selId = _selectedCategoryId;
    if (selId != null &&
        selId.isNotEmpty &&
        !_categories.any((c) => c.id == selId)) {
      items.add(DropdownMenuItem<String>(
        value: selId,
        child: Row(children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$selId (غير متاح)', overflow: TextOverflow.ellipsis),
          ),
        ]),
      ));
    }
    return items;
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isActive = widget.rawData['isActive'] as bool? ?? true;
    final String banReason = widget.rawData['banReason']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة بيانات المكان'),
        centerTitle: true,
        actions: _isEditing
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
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  tooltip: 'حفظ التعديلات',
                  onPressed: _isSaving ? null : _saveChanges,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'تعديل البيانات',
                  onPressed: _enterEditMode,
                ),
              ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isActive && banReason.isNotEmpty) _buildBanBanner(banReason),
            if (_isEditing) _buildEditModeBanner(theme),

            // 1. Identity
            _buildSection(
              icon: Icons.store,
              title: 'بيانات المكان',
              subtitle: 'الاسم والتصنيف والوصف',
              children: [
                _buildTextField(_nameArCtrl, 'الاسم بالعربية *', Icons.title,
                    required: true),
                const SizedBox(height: 12),
                _buildTextField(
                    _nameEnCtrl, 'الاسم بالإنجليزية', Icons.language),
                const SizedBox(height: 12),

                // v6.4: category is now a Firestore-backed dropdown
                DropdownButtonFormField<String>(
                  key: ValueKey(
                      'cat_${_selectedCategoryId ?? 'none'}_$_loadingCategories'),
                  initialValue: _selectedCategoryId,
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
                    helperText:
                        _loadingCategories ? 'جارٍ تحميل التصنيفات...' : null,
                  ),
                  items: _categoryItems(),
                  validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                  onChanged: (_isEditing && !_loadingCategories)
                      ? (val) => setState(() => _selectedCategoryId = val)
                      : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(_descCtrl, 'الوصف التفصيلي (يُغني عن الصور)',
                    Icons.description,
                    maxLines: 4),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Location
            _buildSection(
              icon: Icons.location_on,
              title: 'الموقع',
              subtitle: 'المحافظة والحي والعنوان',
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('gov_${_selectedGovernorate?.docId ?? 'none'}'),
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
                  validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
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
                      'dist_${_selectedDistrict?.id ?? 'none'}_${_selectedGovernorate?.docId ?? 'none'}'),
                  initialValue: _selectedDistrict?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'الحي *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.place),
                    filled: !_isEditing,
                    fillColor: !_isEditing
                        ? theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3)
                        : null,
                  ),
                  items: _districtItems(),
                  validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                  onChanged: (_isEditing && !_loadingDistricts)
                      ? (val) => setState(
                          () => _selectedDistrict = _findDistrictById(val))
                      : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(_addressCtrl, 'العنوان التفصيلي', Icons.map),
                const SizedBox(height: 16),

                // v6.5 & v6.6: GPS Editing Section + GeoZone detection
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
                      Row(children: [
                        Icon(Icons.map_outlined,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text('الإحداثيات الجغرافية (GPS)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ]),
                      const SizedBox(height: 12),
                      if (_isEditing) ...[
                        TextFormField(
                          controller: _pasteUrlCtrl,
                          decoration: InputDecoration(
                            labelText: 'الصق رابط Google Maps (اختياري)',
                            hintText: 'https://maps.google.com/?q=31.26,32.29',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.link),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.content_paste_go),
                              tooltip: 'استخراج الإحداثيات',
                              onPressed: _extractFromUrl,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
                              filled: !_isEditing,
                              fillColor: !_isEditing
                                  ? theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3)
                                  : null,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'مطلوب';
                              final n = double.tryParse(v);
                              if (n == null || n < -90 || n > 90)
                                return 'غير صحيح';
                              return null;
                            },
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
                              filled: !_isEditing,
                              fillColor: !_isEditing
                                  ? theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3)
                                  : null,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'مطلوب';
                              final n = double.tryParse(v);
                              if (n == null || n < -180 || n > 180)
                                return 'غير صحيح';
                              return null;
                            },
                          ),
                        ),
                      ]),

                      // v6.6: GeoZone Display + Detect Button
                      if (_detectedZoneName != null &&
                          _detectedZoneName!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_city,
                                  color: Colors.green.shade700, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'المنطقة السكنية: $_detectedZoneName',
                                  style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isDetectingZone ? null : _detectZoneManually,
                            icon: _isDetectingZone
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.my_location, size: 18),
                            label: Text(_isDetectingZone
                                ? 'جارٍ البحث...'
                                : 'تحديد المنطقة السكنية تلقائياً'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              side: BorderSide(color: Colors.blue.shade300),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Contact
            _buildSection(
              icon: Icons.contact_phone,
              title: 'التواصل',
              subtitle: 'هاتف أو واتساب (واحد على الأقل)',
              children: [
                _buildTextField(_phoneCtrl, 'رقم الهاتف', Icons.phone,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(_whatsappCtrl, 'رقم الواتساب', Icons.chat,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(_emailCtrl, 'البريد الإلكتروني', Icons.email,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildTextField(_websiteCtrl, 'الموقع الإلكتروني', Icons.public,
                    keyboardType: TextInputType.url),
                const SizedBox(height: 12),
                _buildTextField(_facebookCtrl, 'صفحة الفيسبوك', Icons.facebook,
                    keyboardType: TextInputType.url),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Price & Tags
            _buildSection(
              icon: Icons.local_offer,
              title: 'السعر والكلمات المفتاحية',
              subtitle: 'مستوى السعر وكلمات للبحث',
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey('price_$_priceLevel'),
                  initialValue: _priceLevel,
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
                const SizedBox(height: 12),
                _buildTextField(
                    _tagsCtrl, 'كلمات مفتاحية (مفصولة بفاصلة)', Icons.tag),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Features
            _buildSection(
              icon: Icons.checklist,
              title: 'المميزات والخدمات',
              subtitle: 'حدد ما يتوفر في المكان',
              children: [
                _buildSwitch('واي فاي (WiFi)', _hasWifi,
                    (v) => setState(() => _hasWifi = v)),
                _buildSwitch('مواقف سيارات (Parking)', _hasParking,
                    (v) => setState(() => _hasParking = v)),
                _buildSwitch('دورات مياه (Restroom)', _hasRestroom,
                    (v) => setState(() => _hasRestroom = v)),
                _buildSwitch(
                    'تسهيلات لذوي الاحتياجات (Accessibility)',
                    _hasAccessibility,
                    (v) => setState(() => _hasAccessibility = v)),
                _buildSwitch('توصيل (Delivery)', _hasDelivery,
                    (v) => setState(() => _hasDelivery = v)),
                _buildSwitch(
                    'مناسب للعائلات (Family Friendly)',
                    _isFamilyFriendly,
                    (v) => setState(() => _isFamilyFriendly = v)),
                _buildSwitch('يقبل الحجوزات (Reservation)', _hasReservation,
                    (v) => setState(() => _hasReservation = v)),
                _buildSwitch('حلال (Halal)', _isHalal,
                    (v) => setState(() => _isHalal = v)),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Images (placeholder — disabled)
            _buildSection(
              icon: Icons.photo_library,
              title: 'صور المكان',
              subtitle: 'ميزة قادمة قريباً',
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          color: theme.colorScheme.outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'رفع الصور سيتاح قريباً. حالياً، استخدم '
                          'الوصف التفصيلي ورابط الفيسبوك لتعريف العملاء بمكانك.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // v6.4: bottom Save/Cancel — only visible in edit mode
            if (_isEditing) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ كل التغييرات'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isSaving ? null : _cancelEdit,
                icon: const Icon(Icons.close),
                label: const Text('إلغاء التعديل'),
              ),
            ],
            const SizedBox(height: 30),
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

  Widget _buildBanBanner(String banReason) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade400, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block, color: Colors.red.shade700, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تم إيقاف نشاطك مؤقتاً',
                    style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 6),
                Text('السبب: $banReason',
                    style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text('يرجى تعديل البيانات والتواصل مع الدعم الفني.',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
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
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: !_isEditing,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !_isEditing,
        fillColor: !_isEditing
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: _isEditing ? onChanged : null,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
