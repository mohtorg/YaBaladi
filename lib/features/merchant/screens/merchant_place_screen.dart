// lib/features/merchant/screens/merchant_place_screen.dart
//
// [v6.3] — FIX (مراجعة وتصويب، بدون تغيير الوظائف):
//   - MerchantPlaceScreen: تخزين الـ stream مؤقتاً + context.select بدل watch،
//     لمنع إعادة الاشتراك وتدمير النموذج (وضياع تعديلات المستخدم) عند أي إعادة بناء.
//   - حماية من uid فارغ (كان الاستعلام يطابق ownerId == null).
//   - إظهار مؤشر التحميل فقط عند عدم وجود بيانات + معالجة أخطاء الـ stream.
//   - Image.network: إزالة cacheHeight لمنع تشويه نسبة أبعاد الصور المصغرة.
//   - _deleteImage: الحذف من Firestore أولاً ثم Storage (best-effort).
//   - isActive: قراءة آمنة لا تنهار مع أنواع غير منطقية.
//   - الاسم بالعربية حقل مطلوب (كان Form.validate بلا أي فاحص).
//   - عدم عرض نص الاستثناء الخام للمستخدم عند فشل الحفظ.
// [v6.2] — FIX:
//   - Remove redundant `flutter/foundation.dart` import (material re-exports debugPrint).
//   - Harden `_readImageUrls` against null/non-string array elements.
//   - Show ban banner even when admin didn't provide a reason.
//   - KEPT: all upload, save, GPS, features, and form functionality.
// [v6.1] — ADD: Ban Warning Banner (isActive=false + banReason)

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/place.dart';

class MerchantPlaceScreen extends StatefulWidget {
  const MerchantPlaceScreen({super.key});

  @override
  State<MerchantPlaceScreen> createState() => _MerchantPlaceScreenState();
}

class _MerchantPlaceScreenState extends State<MerchantPlaceScreen> {
  String? _cachedUid;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _cachedStream;

  /// يعيد نفس الـ stream ما دام الـ uid لم يتغير، حتى لا يُعاد الاشتراك
  /// (وتُدمَّر واجهة التحرير) عند كل إعادة بناء.
  Stream<QuerySnapshot<Map<String, dynamic>>>? _streamFor(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    if (_cachedStream == null || _cachedUid != uid) {
      _cachedUid = uid;
      _cachedStream = FirebaseFirestore.instance
          .collection('places')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .snapshots();
    }
    return _cachedStream;
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = context.select<AuthController, String?>((a) => a.uid);

    final stream = _streamFor(uid);
    if (stream == null) {
      return const Scaffold(
        body: Center(child: Text('لا يوجد مكان مرتبط بحسابك')),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('Place stream error: ${snap.error}');
          return const Scaffold(
            body:
                Center(child: Text('تعذر تحميل بيانات المكان. أعد المحاولة.')),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data!.docs.isEmpty) {
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

  // الحد الأقصى 500 كيلوبايت
  static const int _maxImageSizeBytes = 500 * 1024;

  // الحد الأقصى لعدد الصور
  static const int _maxImages = 8;

  // مهلة الرفع
  static const Duration _uploadTimeout = Duration(seconds: 60);

  // الامتدادات المسموح بها
  static const List<String> _allowedExt = ['jpg', 'jpeg', 'png', 'webp'];

  late TextEditingController _nameArCtrl;
  late TextEditingController _nameEnCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _govCtrl;

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

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  @override
  void didUpdateWidget(covariant _PlaceEditView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // مزامنة قائمة الصور مع آخر بيانات واردة من Firestore
    _imageUrls = _readImageUrls(widget.rawData);
  }

  /// يقرأ روابط الصور بحصانة ضد القيم غير الصالحة (null، أرقام، إلخ).
  List<String> _readImageUrls(Map<String, dynamic> d) {
    final imagesRaw = d['imageUrls'];
    if (imagesRaw is List) {
      return imagesRaw.whereType<String>().where((s) => s.isNotEmpty).toList();
    }
    return [];
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
    super.dispose();
  }

  // ───────────────────────── أدوات مساعدة ─────────────────────────

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

  /// يُبقي الأحرف اللاتينية والأرقام و . _ - ويستبدل سواها بـ '_'
  /// (مطابق لسلوك التعبير النمطي السابق، دون استعمال RegExp).
  String _safeName(String name) {
    final buf = StringBuffer();
    for (final c in name.codeUnits) {
      final bool ok = (c >= 48 && c <= 57) || // 0-9
          (c >= 65 && c <= 90) || // A-Z
          (c >= 97 && c <= 122) || // a-z
          c == 46 || // .
          c == 95 || // _
          c == 45; // -
      buf.writeCharCode(ok ? c : 95);
    }
    return buf.toString();
  }

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

  // ───────────────────────── رفع الصورة ─────────────────────────

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
        withData: true, // مهم لضمان الحصول على البايتات مباشرة (Web)
      );
    } catch (e) {
      debugPrint('File picking failed: $e');
      _showError('تعذر فتح نافذة اختيار الصورة.');
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final PlatformFile file = result.files.first;
    final Uint8List? bytes = file.bytes;

    if (bytes == null) {
      _showError('تعذر قراءة بيانات الصورة');
      return;
    }

    // فحص حجم الصورة
    if (bytes.length > _maxImageSizeBytes) {
      final kb = (bytes.length / 1024).toStringAsFixed(0);
      _showError('❌ الصورة كبيرة جداً ($kb KB). الحد الأقصى 500 KB.');
      return;
    }

    if (!mounted) return;
    setState(() => _isUploadingImage = true);

    UploadTask? task;
    try {
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('places')
          .child(widget.place.id)
          .child('images')
          .child(
              '${DateTime.now().millisecondsSinceEpoch}_${_safeName(file.name)}');

      // الرفع باستخدام putData بدون snapshotEvents
      task = ref.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeFor(file.extension)),
      );

      // انتظار انتهاء الرفع مع مهلة زمنية
      final TaskSnapshot snapshot = await task.timeout(_uploadTimeout);
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      try {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.place.id)
            .update({
          'imageUrls': FieldValue.arrayUnion([downloadUrl]),
        });
      } catch (_) {
        // منع بقاء ملف يتيم في Storage عند فشل الكتابة في Firestore
        try {
          await ref.delete();
        } catch (_) {}
        rethrow;
      }

      if (!mounted) return;
      setState(() {
        if (!_imageUrls.contains(downloadUrl)) {
          _imageUrls.add(downloadUrl);
        }
      });
      _showSuccess('✅ تم رفع الصورة بنجاح');
    } on TimeoutException {
      try {
        await task?.cancel();
      } catch (_) {}
      _showError('انتهت مهلة الرفع. تحقق من الاتصال وأعد المحاولة.');
    } catch (e) {
      debugPrint('Image upload failed: $e');
      _showError('❌ تعذر رفع الصورة. أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ───────────────────────── حذف الصورة ─────────────────────────

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل أنت متأكد من حذف هذه الصورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteImage(String url) async {
    try {
      // Firestore أولاً: حتى لا يبقى رابط يشير إلى ملف محذوف إن فشلت العملية.
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update({
        'imageUrls': FieldValue.arrayRemove([url]),
      });

      // ثم Storage على سبيل المحاولة الأفضل (قد يكون الملف محذوفاً مسبقاً).
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (e) {
        debugPrint('Storage delete failed (continuing): $e');
      }

      if (!mounted) return;
      setState(() => _imageUrls.remove(url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ تم حذف الصورة')),
      );
    } catch (e) {
      debugPrint('Image delete failed: $e');
      _showError('تعذر حذف الصورة. أعد المحاولة.');
    }
  }

  // ───────────────────────── حفظ البيانات ─────────────────────────

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update({
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
      _showSuccess('✅ تم تحديث كافة البيانات بنجاح');
    } catch (e) {
      debugPrint('Save failed: $e');
      if (!mounted) return;
      _showError('❌ تعذر حفظ التغييرات. أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ───────────────────────── الواجهة ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dynamic locationRaw = widget.rawData['location'];
    final GeoPoint? geoPoint = locationRaw is GeoPoint ? locationRaw : null;

    // ✅ بيانات الحظر (قراءة آمنة: لا يُعدّ المكان محظوراً إلا إذا كانت القيمة false صراحةً)
    final bool isActive = widget.rawData['isActive'] != false;
    final String banReason = widget.rawData['banReason']?.toString() ?? '';

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
            // ✅ لافتة الحظر الحمراء (تظهر دائماً عند الحظر، مع أو بدون سبب)
            if (!isActive) ...[
              Container(
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
                          Text(
                            'تم إيقاف نشاطك مؤقتاً',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (banReason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'السبب: $banReason',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'يرجى تعديل البيانات والتواصل مع الدعم الفني لإعادة التفعيل.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // صور المكان
            _SectionCard(
              title: 'صور المكان (${_imageUrls.length}/$_maxImages)',
              children: [
                if (_imageUrls.isEmpty)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('لا توجد صور. أضف صورة لجذب العملاء!'),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        final url = _imageUrls[index];
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  // عرض فقط: تحديد الاثنين معاً يشوّه نسبة الأبعاد.
                                  cacheWidth: 240,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () async {
                                    if (await _confirmDelete()) {
                                      await _deleteImage(url);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_photo_alternate),
                  label: Text(
                      _isUploadingImage ? 'جارٍ الرفع...' : 'إضافة صورة جديدة'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'الصيغ المسموحة: JPG / PNG / WEBP — الحد الأقصى 500 KB للصورة.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'البيانات الأساسية',
              children: [
                _buildTextField(_nameArCtrl, 'الاسم بالعربية', Icons.store,
                    required: true),
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
                ] else ...[
                  const Text('لم يتم تحديد موقع جغرافي'),
                ]
              ],
            ),
            const SizedBox(height: 16),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

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
