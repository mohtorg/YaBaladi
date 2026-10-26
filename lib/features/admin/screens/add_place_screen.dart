// lib/features/admin/screens/add_place_screen.dart
//
// [v5.0 — 2026-10-26] — BULLETPROOF BUILD: Fixed Dropdown value, strict analyzer compliance

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/helpers/location_url_helper.dart';
import '../../../models/category.dart';
import '../../../repositories/categories_repository.dart';
import '../../../theme/design_tokens.dart';

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
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _pasteUrlCtrl = TextEditingController();

  String _selectedCategory = 'restaurants';
  String _selectedGovernorate = 'بورسعيد';
  String? _originalCategory;

  bool _hasWifi = false;
  bool _hasParking = false;
  bool _hasRestroom = false;
  bool _hasAccessibility = false;
  bool _isFamilyFriendly = false;
  bool _isHalal = false;
  bool _hasDelivery = false;
  bool _hasReservation = false;

  /// Coordinate input formatter — digits, minus, dot.
  static final List<TextInputFormatter> _coordinateFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
  ];

  static const List<String> _governorates = [
    'بورسعيد',
    'القاهرة',
    'الإسكندرية',
    'الجيزة',
    'الدقهلية',
    'الشرقية',
    'المنوفية',
    'أسيوط',
    'أسوان',
    'الأقصر',
    'الغربية',
    'كفر الشيخ',
    'البحيرة',
    'دمياط',
    'الإسماعيلية',
    'السويس',
    'شمال سيناء',
    'جنوب سيناء',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'سوهاج',
    'قنا',
    'البحر الأحمر',
    'الوادي الجديد',
    'مطروح',
    'حلوان',
  ];

  bool get _isEditMode => widget.placeId != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_isEditMode) {
      await _loadPlaceData();
      if (!mounted) return;
      await _loadCategories(preserveSelection: true);
    } else {
      await _loadCategories();
    }
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

  Future<void> _loadPlaceData() async {
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
        return;
      }

      final data = doc.data() ?? <String, dynamic>{};

      if (mounted) {
        setState(() {
          _nameArCtrl.text = data['nameAr']?.toString() ?? '';
          _nameEnCtrl.text = data['nameEn']?.toString() ?? '';
          _descCtrl.text = data['description']?.toString() ?? '';
          _addressCtrl.text = data['address']?.toString() ?? '';
          _phoneCtrl.text = data['phone']?.toString() ?? '';
          _websiteCtrl.text = data['website']?.toString() ?? '';
          _tagsCtrl.text =
              (data['tags'] as List?)?.map((e) => e.toString()).join(', ') ??
                  '';

          final location = data['location'];
          final geo = location is GeoPoint ? location : null;
          final lat = data['latitude'] ?? geo?.latitude;
          final lng = data['longitude'] ?? geo?.longitude;
          _latCtrl.text = lat?.toString() ?? '';
          _lngCtrl.text = lng?.toString() ?? '';

          _selectedCategory = data['categoryId']?.toString() ?? 'restaurants';
          _originalCategory = _selectedCategory;
          _selectedGovernorate = data['governorate']?.toString() ?? 'بورسعيد';

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
    } catch (e) {
      debugPrint('❌ Error loading place: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _tagsCtrl.dispose();
    // _pasteUrlCtrl is intentionally NOT disposed here
    super.dispose();
  }

  Future<void> _savePlace() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
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
        'governorate': _selectedGovernorate,
        'tags': tags,
        'address': _addressCtrl.text.trim(),
        'location': geoPoint,
        'latitude': lat,
        'longitude': lng,
        'geohash': geohash,
        'googleMapsUrl': googleMapsUrl,
        'phone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
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
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _encodeGeohash(
    double latitude,
    double longitude, {
    int precision = 7,
  }) {
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
        .map(
          (c) => DropdownMenuItem<String>(
            value: c.id,
            child: Row(
              children: [
                Icon(c.icon, size: 18, color: c.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.nameAr, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Text(
                  '${c.placesCount}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();

    if (!_categories.any((c) => c.id == _selectedCategory)) {
      items.add(
        DropdownMenuItem<String>(
          value: _selectedCategory,
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_selectedCategory (غير متاح)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  List<DropdownMenuItem<String>> _governorateItems() {
    final values = [..._governorates];
    if (!values.contains(_selectedGovernorate)) {
      values.add(_selectedGovernorate);
    }
    return values
        .map((g) => DropdownMenuItem<String>(value: g, child: Text(g)))
        .toList();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _categoriesLoading) {
      return _buildLoadingScaffold();
    }

    if (_categoriesError != null) {
      return _buildErrorScaffold();
    }

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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(
              icon: Icons.info_outline,
              title: 'المعلومات الأساسية',
              subtitle: 'الاسم والوصف',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameArCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المكان (بالعربية) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                hintText: 'مثال: ميدان الشهداء',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameEnCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المكان (بالإنجليزية)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              icon: Icons.place,
              title: 'التصنيف والموقع',
              subtitle: 'التصنيف، المحافظة، والموقع',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ✅ [FIX] استخدام value بدلاً من initialValue
              value: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'التصنيف *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categoryItems(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ✅ [FIX] استخدام value بدلاً من initialValue
              value: _selectedGovernorate,
              decoration: const InputDecoration(
                labelText: 'المحافظة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _governorateItems(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedGovernorate = val);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'العنوان التفصيلي',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),
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
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'الموقع الجغرافي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pasteUrlCtrl,
                    decoration: InputDecoration(
                      labelText: 'الصق رابط Google Maps (اختياري)',
                      hintText: 'https://maps.google.com/?q=31.26,32.29',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                      helperText: 'سيتم استخراج الإحداثيات تلقائياً',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_go),
                        tooltip: 'استخراج الإحداثيات',
                        onPressed: _extractFromUrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latCtrl,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          inputFormatters: _coordinateFormatters,
                          decoration: const InputDecoration(
                            labelText: 'خط العرض *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.north),
                            hintText: '31.2699',
                          ),
                          validator: (v) => _validateCoordinate(v, limit: 90),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngCtrl,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          inputFormatters: _coordinateFormatters,
                          decoration: const InputDecoration(
                            labelText: 'خط الطول *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.east),
                            hintText: '32.2998',
                          ),
                          validator: (v) => _validateCoordinate(v, limit: 180),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _previewOnMap,
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
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'الموقع الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
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
              onChanged: (v) => setState(() => _hasWifi = v),
            ),
            _buildServiceSwitch(
              icon: Icons.local_parking,
              label: 'موقف سيارات',
              value: _hasParking,
              onChanged: (v) => setState(() => _hasParking = v),
            ),
            _buildServiceSwitch(
              icon: Icons.wc,
              label: 'دورة مياه',
              value: _hasRestroom,
              onChanged: (v) => setState(() => _hasRestroom = v),
            ),
            _buildServiceSwitch(
              icon: Icons.accessible,
              label: 'سهولة الوصول',
              value: _hasAccessibility,
              onChanged: (v) => setState(() => _hasAccessibility = v),
            ),
            _buildServiceSwitch(
              icon: Icons.family_restroom,
              label: 'مناسب للعائلات',
              value: _isFamilyFriendly,
              onChanged: (v) => setState(() => _isFamilyFriendly = v),
            ),
            _buildServiceSwitch(
              icon: Icons.restaurant_menu,
              label: 'حلال',
              value: _isHalal,
              onChanged: (v) => setState(() => _isHalal = v),
            ),
            _buildServiceSwitch(
              icon: Icons.delivery_dining,
              label: 'توصيل',
              value: _hasDelivery,
              onChanged: (v) => setState(() => _hasDelivery = v),
            ),
            _buildServiceSwitch(
              icon: Icons.event_seat,
              label: 'حجز مسبق',
              value: _hasReservation,
              onChanged: (v) => setState(() => _hasReservation = v),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              icon: Icons.tag,
              title: 'الكلمات المفتاحية',
              subtitle: 'مفصولة بفاصلة',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'الكلمات المفتاحية',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                hintText: 'معلم, ميدان, نصب',
              ),
            ),
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
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(_isEditMode ? Icons.check : Icons.save),
                label: Text(
                  _isSaving
                      ? 'جارٍ الحفظ...'
                      : (_isEditMode ? 'حفظ التعديلات' : 'حفظ المكان'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: YaBaladiDesignTokens.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
              Icon(
                Icons.cloud_off,
                size: 72,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'تعذر تحميل التصنيفات',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _categoriesError ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: YaBaladiDesignTokens.primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color: value
              ? YaBaladiDesignTokens.primaryBlue
              : theme.colorScheme.outline,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        activeThumbColor: YaBaladiDesignTokens.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
