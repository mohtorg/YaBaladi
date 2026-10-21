// lib/features/admin/screens/add_place_screen.dart
//
// [v2.2 — 2026-10-21] — Paste URL + Preview on Map
//   - NEW: _pasteUrlCtrl for Google Maps URL input
//   - NEW: extractCoordinates() via LocationUrlHelper
//   - NEW: Preview button to open Google Maps
//   - SAVES: googleMapsUrl field
//   - FULL: Add + Edit modes with initialValue (no deprecated `value`)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/helpers/location_url_helper.dart';
import '../../../models/place_categories.dart';
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

  // ─── Controllers ───
  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _pasteUrlCtrl = TextEditingController(); // ✅ NEW

  // ─── Dropdowns ───
  String _selectedCategory = 'restaurants';
  String _selectedGovernorate = 'بورسعيد';

  // ─── Services ───
  bool _hasWifi = false;
  bool _hasParking = false;
  bool _hasRestroom = false;
  bool _hasAccessibility = false;
  bool _isFamilyFriendly = false;
  bool _isHalal = false;
  bool _hasDelivery = false;
  bool _hasReservation = false;

  final List<String> _governorates = const [
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
    'حلوان'
  ];

  bool get _isEditMode => widget.placeId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) _loadPlaceData();
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

      final data = doc.data() as Map<String, dynamic>? ?? {};

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

          final lat =
              data['latitude'] ?? (data['location'] as GeoPoint?)?.latitude;
          final lng =
              data['longitude'] ?? (data['location'] as GeoPoint?)?.longitude;
          _latCtrl.text = lat?.toString() ?? '';
          _lngCtrl.text = lng?.toString() ?? '';

          _selectedCategory = data['categoryId']?.toString() ?? 'restaurants';
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
    _pasteUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate()) return;
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
        'googleMapsUrl': googleMapsUrl, // ✅ NEW
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

  String _encodeGeohash(double latitude, double longitude,
      {int precision = 7}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var isEven = true;
    var bit = 0;
    var ch = 0;
    final sb = StringBuffer();
    var latMin = -90.0, latMax = 90.0, lonMin = -180.0, lonMax = 180.0;
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

  void _extractFromUrl() {
    final coords = LocationUrlHelper.extractCoordinates(_pasteUrlCtrl.text);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ لم يتم التعرف على إحداثيات في الرابط'),
          backgroundColor: Colors.red,
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text('جاري التحميل...'),
          backgroundColor: YaBaladiDesignTokens.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
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
            // ─── SECTION 1: المعلومات الأساسية ───
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

            // ─── SECTION 2: التصنيف والموقع ───
            _buildSectionHeader(
              icon: Icons.place,
              title: 'التصنيف والموقع',
              subtitle: 'التصنيف، المحافظة، والموقع',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'التصنيف *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: PlaceCategories.all
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.labelAr),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedGovernorate,
              decoration: const InputDecoration(
                labelText: 'المحافظة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _governorates
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGovernorate = val);
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

            // ─── بطاقة الموقع ───
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
                      Icon(Icons.location_on,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'الموقع الجغرافي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // الصق رابط Google Maps
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'خط العرض *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.north),
                            hintText: '31.2699',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'مطلوب';
                            if (double.tryParse(v) == null)
                              return 'رقم غير صحيح';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'خط الطول *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.east),
                            hintText: '32.2998',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'مطلوب';
                            if (double.tryParse(v) == null)
                              return 'رقم غير صحيح';
                            return null;
                          },
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

            // ─── SECTION 3: التواصل ───
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

            // ─── SECTION 4: الخدمات ───
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

            // ─── SECTION 5: Tags ───
            _buildSectionHeader(
              icon: Icons.tag,
              title: 'الكلمات المفتاحية',
              subtitle: 'مفصولة بفاصلة',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Tags',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                hintText: 'معلم, ميدان, نصب',
              ),
            ),
            const SizedBox(height: 32),

            // ─── زر الحفظ ───
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
                      ? 'جاري الحفظ...'
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: YaBaladiDesignTokens.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color: value ? YaBaladiDesignTokens.primaryBlue : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: value ? Colors.black87 : Colors.grey[700],
          ),
        ),
        activeThumbColor: YaBaladiDesignTokens.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
