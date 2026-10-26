// lib/features/merchant/screens/merchant_place_screen.dart
//
// [v3.0 — 2026-10-26] — FEATURE: Comprehensive data view & edit

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/place.dart';

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
        final place = Place.fromMap(doc.id, doc.data());

        return _PlaceEditView(place: place, rawData: doc.data());
      },
    );
  }
}

class _PlaceEditView extends StatefulWidget {
  final Place place;
  final Map<String, dynamic> rawData;

  const _PlaceEditView({required this.place, required this.rawData});

  @override
  State<_PlaceEditView> createState() => _PlaceEditViewState();
}

class _PlaceEditViewState extends State<_PlaceEditView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers للنصوص
  late TextEditingController _nameArCtrl;
  late TextEditingController _nameEnCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _govCtrl;
  late TextEditingController _imagesCtrl;

  // متغيرات للمميزات (Bools)
  bool _hasWifi = false;
  bool _hasParking = false;
  bool _hasRestroom = false;
  bool _hasAccessibility = false;
  bool _hasDelivery = false;
  bool _isFamilyFriendly = false;
  bool _hasReservation = false;
  bool _isHalal = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    final d = widget.rawData;

    _nameArCtrl = TextEditingController(text: d['nameAr']?.toString() ?? '');
    _nameEnCtrl = TextEditingController(text: d['nameEn']?.toString() ?? '');
    _categoryCtrl =
        TextEditingController(text: d['categoryId']?.toString() ?? '');
    _descCtrl = TextEditingController(text: d['description']?.toString() ?? '');
    _phoneCtrl = TextEditingController(
        text: d['businessPhone']?.toString() ?? d['phone']?.toString() ?? '');
    _whatsappCtrl =
        TextEditingController(text: d['whatsapp']?.toString() ?? '');
    _addressCtrl = TextEditingController(text: d['address']?.toString() ?? '');
    _cityCtrl = TextEditingController(text: d['city']?.toString() ?? '');
    _govCtrl = TextEditingController(text: d['governorate']?.toString() ?? '');

    // التعامل مع قائمة الصور
    final images = d['imageUrls'] as List? ?? [];
    _imagesCtrl = TextEditingController(text: images.join(', '));

    // المميزات
    _hasWifi = d['hasWifi'] == true;
    _hasParking = d['hasParking'] == true;
    _hasRestroom = d['hasRestroom'] == true;
    _hasAccessibility = d['hasAccessibility'] == true;
    _hasDelivery = d['hasDelivery'] == true;
    _isFamilyFriendly = d['isFamilyFriendly'] == true;
    _hasReservation = d['hasReservation'] == true;
    _isHalal = d['isHalal'] == true;
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _govCtrl.dispose();
    _imagesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // تجهيز قائمة الصور من النص المفصول بفاصلة
      final imageList = _imagesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update({
        // ملاحظة: الحقول المحمية بالقواعد (الاسم، التصنيف، الموقع) قد ترفض التحديث
        // إذا أردت تعديلها، يجب تعديل قواعد Firestore للسماح للتاجر بذلك.
        'nameAr': _nameArCtrl.text.trim(),
        'nameEn': _nameEnCtrl.text.trim(),
        'categoryId': _categoryCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'businessPhone': _phoneCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'governorate': _govCtrl.text.trim(),
        'imageUrls': imageList,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تحديث كافة البيانات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: $e\n(تأكد من قواعد الصلاحيات)'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // استخراج الموقع الجغرافي
    final geoPoint = widget.rawData['location'] as GeoPoint?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة بيانات المكان'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── البيانات الأساسية ───
            _SectionCard(
              title: 'البيانات الأساسية',
              children: [
                _buildTextField(_nameArCtrl, 'الاسم بالعربية', Icons.store),
                const SizedBox(height: 12),
                _buildTextField(_nameEnCtrl, 'الاسم بالإنجليزية', Icons.store),
                const SizedBox(height: 12),
                _buildTextField(
                    _categoryCtrl, 'التصنيف (Category ID)', Icons.category),
                const SizedBox(height: 12),
                _buildTextField(_descCtrl, 'وصف المكان', Icons.description,
                    maxLines: 3),
              ],
            ),
            const SizedBox(height: 16),

            // ─── بيانات الاتصال والعنوان ───
            _SectionCard(
              title: 'الاتصال والعنوان',
              children: [
                _buildTextField(_phoneCtrl, 'رقم الهاتف', Icons.phone,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(
                    _whatsappCtrl, 'رقم الواتساب', Icons.phone_android,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(_govCtrl, 'المحافظة', Icons.location_city),
                const SizedBox(height: 12),
                _buildTextField(_cityCtrl, 'المدينة/الحي', Icons.location_on),
                const SizedBox(height: 12),
                _buildTextField(_addressCtrl, 'العنوان التفصيلي', Icons.map),
              ],
            ),
            const SizedBox(height: 16),

            // ─── الموقع الجغرافي ───
            _SectionCard(
              title: 'الموقع الجغرافي (GPS)',
              children: [
                if (geoPoint != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.my_location,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text('خط العرض: ${geoPoint.latitude}',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.my_location,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text('خط الطول: ${geoPoint.longitude}',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      '*(لتعديل الموقع، يجب استخدام الخريطة أو التواصل مع الأدمن)*',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ] else ...[
                  const Text('لم يتم تحديد موقع جغرافي'),
                ]
              ],
            ),
            const SizedBox(height: 16),

            // ─── المميزات ───
            _SectionCard(
              title: 'المميزات والخدمات',
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

            // ─── الصور ───
            _SectionCard(
              title: 'روابط الصور (مفصولة بفاصلة)',
              children: [
                _buildTextField(_imagesCtrl, 'روابط الصور', Icons.image,
                    maxLines: 2),
              ],
            ),
            const SizedBox(height: 24),

            // زر الحفظ
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
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ويدجت مساعد للنصوص
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  // ويدجت مساعد للمفاتيح (Switches)
  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ويدجتس مساعدة
// ═══════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
