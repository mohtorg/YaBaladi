// screens/admin/admin_place_form_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// فورم واحد بيخدم حالتين: "إضافة مكان جديد" و"تعديل مكان موجود".
// الفرق الوحيد: لو existingPlace اتبعتلنا، بنملأ الحقول بقيمه القديمة
// وبنحدّث نفس المستند بدل ما ننشئ واحد جديد. كده منكررش نفس الفورم مرتين.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/place.dart';
import '../../models/egypt_governorates.dart';
import '../../models/audience_tags.dart';
import '../../models/place_categories.dart';
import '../../models/app_content_type.dart';

class AdminPlaceFormScreen extends StatefulWidget {
  final Place? existingPlace; // null = إضافة جديدة، غير null = تعديل

  const AdminPlaceFormScreen({super.key, this.existingPlace});

  @override
  State<AdminPlaceFormScreen> createState() => _AdminPlaceFormScreenState();
}

class _AdminPlaceFormScreenState extends State<AdminPlaceFormScreen> {
  // ------------------------------------------------------------
  // الفكرة: كل حقل نصي في الفورم ليه Controller منفصل، وبنملأهم
  // بالقيم القديمة لو إحنا في وضع "تعديل" (initState)
  // ------------------------------------------------------------
  late TextEditingController _nameAr, _nameEn, _descAr, _descEn;
  late TextEditingController _addressAr, _addressEn, _category, _imageUrl;
  late TextEditingController _hoursAr, _hoursEn, _lat, _lng, _discountOffer;

  late String _selectedCity;
  late String _contentType;
  bool _isPublished = true;
  final Set<String> _selectedTags = {};
  bool _isFree = false;
  bool _allowFoodInside = false;
  String _priceRange = '';
  bool _hasParking = false, _hasWifi = false, _acceptsElectronicPayment = false, _hasDelivery = false, _requiresReservation = false;
  bool _isSaving = false;

  bool get _isEditing => widget.existingPlace != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlace;

    _nameAr = TextEditingController(text: p?.nameAr ?? '');
    _nameEn = TextEditingController(text: p?.nameEn ?? '');
    _descAr = TextEditingController(text: p?.descriptionAr ?? '');
    _descEn = TextEditingController(text: p?.descriptionEn ?? '');
    _addressAr = TextEditingController(text: p?.addressAr ?? '');
    _addressEn = TextEditingController(text: p?.addressEn ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _hoursAr = TextEditingController(text: p?.openingHoursAr ?? '');
    _hoursEn = TextEditingController(text: p?.openingHoursEn ?? '');
    _lat = TextEditingController(text: p?.latitude.toString() ?? '');
    _lng = TextEditingController(text: p?.longitude.toString() ?? '');
    _discountOffer = TextEditingController(text: p?.discountOffer ?? '');

    _selectedCity = p?.cityId ?? EgyptGovernorates.activeGovernorateId;
    _contentType = p?.contentType ?? (p?.ownerId == null ? AppContentType.publicPlace.id : AppContentType.serviceProvider.id);
    _isPublished = p?.isPublished ?? true;
    if (p != null) {
      _selectedTags.addAll(p.audienceTags);
      _hasParking = p.hasParking; _hasWifi = p.hasWifi; _acceptsElectronicPayment = p.acceptsElectronicPayment;
      _hasDelivery = p.hasDelivery; _requiresReservation = p.requiresReservation;
    }
    _isFree = p?.isFree ?? false;
    _allowFoodInside = p?.allowFoodInside ?? false;
    _priceRange = p?.priceRange ?? '';
  }

  // ------------------------------------------------------------
  // الفكرة: دالة الحفظ - بتبني Map واحد من كل الحقول، وبتقرر
  // (بناءً على _isEditing) هل تعمل update للمستند القديم
  // ولا تعمل add لمستند جديد بالكامل
  // ------------------------------------------------------------
  // ملاحظة التعديل:
  // أضفنا try/catch/finally حول الحفظ حتى تظهر أخطاء Permission Denied أو الشبكة
  // للمستخدم بدل خروج الشاشة إلى حالة غير معروفة. كما نحافظ على isSaving بصورة صحيحة.
  Future<void> _save() async {
    if (_nameAr.text.trim().isEmpty || _nameEn.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المكان بالعربي والإنجليزي مطلوبين')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final place = Place(
      id: widget.existingPlace?.id ?? '',
      governorateId: _selectedCity,
      cityId: _selectedCity,
      ownerId: widget.existingPlace?.ownerId,
      contentType: _contentType,
      nameAr: _nameAr.text.trim(),
      nameEn: _nameEn.text.trim(),
      descriptionAr: _descAr.text.trim(),
      descriptionEn: _descEn.text.trim(),
      addressAr: _addressAr.text.trim(),
      addressEn: _addressEn.text.trim(),
      category: _category.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      rating: widget.existingPlace?.rating ?? 0,
      ratingCount: widget.existingPlace?.ratingCount ?? 0,
      openingHoursAr: _hoursAr.text.trim(),
      openingHoursEn: _hoursEn.text.trim(),
      latitude: double.tryParse(_lat.text.trim()) ?? 0,
      longitude: double.tryParse(_lng.text.trim()) ?? 0,
      audienceTags: _selectedTags.toList(),
      isFeatured: widget.existingPlace?.isFeatured ?? false,
      allowFoodInside: _allowFoodInside,
      isFree: _isFree,
      priceRange: _isFree ? '' : _priceRange,
      discountOffer: _discountOffer.text.trim().isEmpty ? null : _discountOffer.text.trim(),
      hasParking: _hasParking,
      hasWifi: _hasWifi,
      acceptsElectronicPayment: _acceptsElectronicPayment,
      hasDelivery: _hasDelivery,
      requiresReservation: _requiresReservation,
      isPublished: _isPublished,
      publishedAt: _isPublished ? (widget.existingPlace?.publishedAt ?? DateTime.now()) : widget.existingPlace?.publishedAt,
    );

    try {
      final collection = FirebaseFirestore.instance.collection('places');
      if (_isEditing) {
        await collection.doc(place.id).update(place.toMap());
      } else {
        await collection.add(place.toMap());
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ المكان: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ملاحظة التعديل:
  // تحرير جميع TextEditingController عند إغلاق الشاشة لمنع تسرب الموارد.
  List<Widget> _propertySwitches() => [
    SwitchListTile(title: const Text('موقف سيارات'), value: _hasParking, onChanged: (v) => setState(() => _hasParking = v)),
    SwitchListTile(title: const Text('Wi-Fi'), value: _hasWifi, onChanged: (v) => setState(() => _hasWifi = v)),
    SwitchListTile(title: const Text('دفع إلكتروني'), value: _acceptsElectronicPayment, onChanged: (v) => setState(() => _acceptsElectronicPayment = v)),
    SwitchListTile(title: const Text('خدمة توصيل'), value: _hasDelivery, onChanged: (v) => setState(() => _hasDelivery = v)),
    SwitchListTile(title: const Text('يتطلب حجزًا مسبقًا'), value: _requiresReservation, onChanged: (v) => setState(() => _requiresReservation = v)),
  ];

  @override
  void dispose() {
    for (final controller in [
      _nameAr, _nameEn, _descAr, _descEn, _addressAr, _addressEn, _category,
      _imageUrl, _hoursAr, _hoursEn, _lat, _lng, _discountOffer,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المكان' : 'إضافة مكان جديد'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('الاسم بالعربي', _nameAr),
          _field('الاسم بالإنجليزي', _nameEn),
          _field('الوصف بالعربي', _descAr, maxLines: 3),
          _field('الوصف بالإنجليزي', _descEn, maxLines: 3),
          _field('العنوان بالعربي', _addressAr),
          _field('العنوان بالإنجليزي', _addressEn),
          // نوع المحتوى منفصل عن التصنيف: يحدد دورة الإدارة والتوسع، بينما category تصف النشاط.
          const Text('نوع المحتوى', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: AppContentType.byId(_contentType)?.id ?? AppContentType.publicPlace.id,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: AppContentType.all.map((c) => DropdownMenuItem(value: c.id, child: Text(c.labelAr))).toList(),
            onChanged: (value) { if (value != null) setState(() => _contentType = value); },
          ),
          const SizedBox(height: 16),

          // التصنيف يُختار من قائمة موحدة حتى لا تتكرر قيم category بصيغ مختلفة.
          const Text('نوع المكان / النشاط', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: PlaceCategories.byId(_category.text.trim())?.id ?? 'أخرى',
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: PlaceCategories.all.map((c) => DropdownMenuItem(value: c.id, child: Text(c.labelAr))).toList(),
            onChanged: (value) { if (value != null) _category.text = value; setState(() {}); },
          ),
          _field('رابط الصورة', _imageUrl),
          _field('ساعات العمل بالعربي', _hoursAr),
          _field('ساعات العمل بالإنجليزي', _hoursEn),
          Row(
            children: [
              Expanded(child: _field('خط العرض (Lat)', _lat)),
              const SizedBox(width: 12),
              Expanded(child: _field('خط الطول (Lng)', _lng)),
            ],
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------------
          // الفكرة: قائمة منسدلة للمحافظة - نفس القائمة الثابتة المستخدمة
          // في كل التطبيق، عشان القيمة المحفوظة تتطابق دايمًا
          // ------------------------------------------------------------
          const Text('المحافظة', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _selectedCity,
            isExpanded: true,
            items: EgyptGovernorates.all
                .map((gov) => DropdownMenuItem(value: gov.id, child: Text(gov.nameAr)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCity = value!),
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('منشور للمستخدمين'),
            subtitle: const Text('إلغاء النشر يخفي المحتوى عن واجهة المستخدم دون حذفه.'),
            value: _isPublished,
            onChanged: (value) => setState(() => _isPublished = value),
          ),

          // ------------------------------------------------------------
          // الفكرة: نص عرض الخصم اللي هيظهر كمكافأة للمستخدم بعد ما يقيّم
          // زيارته الموثّقة لهذا المكان. لو سايبه فاضي، هيتستخدم نص افتراضي عام
          // ------------------------------------------------------------
          _field('عرض الخصم بعد التقييم (اختياري، مثال: خصم 15% على الفاتورة)', _discountOffer),

          // ------------------------------------------------------------
          // الفكرة: مفتاح "مجاني بالكامل" - لو مفعّل، بيتخفى اختيار
          // نطاق السعر تلقائيًا لأنه مالوش معنى لمكان مجاني
          // ------------------------------------------------------------
          SwitchListTile(
            title: const Text('مسموح بدخول الأكل'),
            subtitle: const Text('معلومة تظهر كفلتر للمستخدم'),
            value: _allowFoodInside,
            onChanged: (value) => setState(() => _allowFoodInside = value),
          ),

          const SizedBox(height: 12),
          const Text('خصائص المكان والخدمات', style: TextStyle(fontWeight: FontWeight.bold)),
          // هذه الخصائص لا تحدد الجمهور؛ هي معلومات قابلة للفلترة للمستخدم.
          ..._propertySwitches(),

          SwitchListTile(
            title: const Text('مكان مجاني بالكامل'),
            value: _isFree,
            onChanged: (value) => setState(() => _isFree = value),
          ),
          if (!_isFree) ...[
            const SizedBox(height: 8),
            const Text('نطاق السعر التقريبي', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['\$', '\$\$', '\$\$\$'].map((price) {
                return ChoiceChip(
                  label: Text(price),
                  selected: _priceRange == price,
                  onSelected: (selected) => setState(() => _priceRange = selected ? price : ''),
                );
              }).toList(),
            ),
          ],

          // ------------------------------------------------------------
          // الفكرة: فئات الجمهور - نفس الـ Chips المستخدمة في شاشة الفلترة،
          // لكن هنا بتحدد الفئات الفعلية للمكان بدل ما تفلتر بيها
          // ------------------------------------------------------------
          const Text('مناسب لـ (فئات الجمهور)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AudienceTags.all.map((tag) {
              final isSelected = _selectedTags.contains(tag.id);
              return FilterChip(
                avatar: Icon(tag.icon, size: 16),
                label: Text(tag.labelAr),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag.id);
                    } else {
                      _selectedTags.remove(tag.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_isEditing ? 'حفظ التعديلات' : 'إضافة المكان'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // الفكرة: دالة مساعدة بسيطة بترجع نفس تصميم TextField في كل مكان
  // بدل ما نكرر نفس الـ decoration في كل حقل من الـ 10 حقول فوق
  // ------------------------------------------------------------
  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
