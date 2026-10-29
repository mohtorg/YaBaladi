// lib/features/merchant/widgets/location_input_widget.dart
//
// [v5.3 — 2026-10-27] — SMART FIX: Replaced dart:html with url_launcher (Mobile compatible)
//   - FIX: GPS updated to use LocationSettings (Geolocator v13 compatible)
//   - ADD: Fallback to Last Known Position
//   - FIX: _previewOnMap now uses url_launcher for both Web and Mobile

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ حل بديل لمكتبة dart:html

import '../../../core/location/egypt_governorates.dart';

class LocationInputWidget extends StatefulWidget {
  final Function(String governorateId, String address, GeoPoint? location)
      onChanged;

  const LocationInputWidget({super.key, required this.onChanged});

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  String? _selectedGovId;
  final _addressCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  GeoPoint? _location;
  bool _isParsing = false;
  bool _isGettingLocation = false;

  // ═══════════════════════════════════════════════════════════════
  // INLINE HELPERS
  // ═══════════════════════════════════════════════════════════════

  static final List<RegExp> _coordinatePatterns = [
    // !3d..!4d.. — إحداثيات المكان الفعلية
    RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)'),
    // q= / query= / ll= / destination=
    RegExp(
      r'[?&](?:q|query|ll|destination)=(-?\d+(?:\.\d+)?)(?:,|%2C)\s*\+?(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    ),
    // @lat,lng
    RegExp(r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)'),
    // place/lat,lng
    RegExp(r'place/(-?\d+(?:\.\d+)?),\+?(-?\d+(?:\.\d+)?)'),
    // "lat,lng" مجردة
    RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*[,;]\s*(-?\d+(?:\.\d+)?)\s*$'),
  ];

  ({double lat, double lng})? _extractCoordinates(String url) {
    final input = url.trim();
    if (input.isEmpty) return null;

    for (final pattern in _coordinatePatterns) {
      final match = pattern.firstMatch(input);
      if (match == null) continue;

      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) {
        return (lat: lat, lng: lng);
      }
    }
    return null;
  }

  String _buildMapPreviewUrl(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  bool _isValidEgyptCoord(double lat, double lng) {
    return lat >= 22.0 && lat <= 32.0 && lng >= 24.0 && lng <= 37.0;
  }

  void _notifyParent() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());

    if (lat != null && lng != null && _isValidEgyptCoord(lat, lng)) {
      _location = GeoPoint(lat, lng);
    } else {
      _location = null;
    }

    widget.onChanged(
      _selectedGovId ?? '',
      _addressCtrl.text.trim(),
      _location,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // USE CURRENT LOCATION (GPS)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() => _isGettingLocation = true);

    try {
      // 1. هل خدمة الموقع مفعلة؟
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('خدمة الموقع غير مفعلة. يرجى تفعيل GPS في جهازك.');
        setState(() => _isGettingLocation = false);
        return;
      }

      // 2. هل لدينا صلاحية؟
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('تم رفض صلاحية الموقع. يرجى السماح بالوصول.');
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('صلاحية الموقع مرفوضة نهائياً. فعّلها من إعدادات التطبيق.');
        setState(() => _isGettingLocation = false);
        return;
      }

      // 3. جلب الموقع الحالي بدقة عالية (متوافق مع Geolocator 13)
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      );

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
      } catch (e) {
        // خطة بديلة ذكية: إذا فشل جلب الموقع، استخدم آخر موقع معروف
        debugPrint('GPS Error: $e. Trying last known position...');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _showError('فشل تحديد الموقع. تأكد من وجود إشارة GPS وحاول مرة أخرى.');
        setState(() => _isGettingLocation = false);
        return;
      }

      // 4. التحقق من أن الموقع داخل مصر
      if (!_isValidEgyptCoord(position.latitude, position.longitude)) {
        _showError('موقعك الحالي خارج نطاق مصر ('
            '${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)})');
        setState(() => _isGettingLocation = false);
        return;
      }

      // 5. ملء الإحداثيات
      setState(() {
        _latCtrl.text = position!.latitude.toStringAsFixed(6);
        _lngCtrl.text = position.longitude.toStringAsFixed(6);
      });

      // 6. اكتشاف المحافظة تلقائياً
      final nearestGov =
          nearestGovernorate(position.latitude, position.longitude);
      if (_selectedGovId != nearestGov.id) {
        setState(() => _selectedGovId = nearestGov.id);
      }

      _notifyParent();
      setState(() => _isGettingLocation = false);

      _showSuccess(
        '✅ تم تحديد موقعك بدقة ±${position.accuracy.toStringAsFixed(0)}م '
        '(${nearestGov.nameAr})',
      );
    } on TimeoutException {
      _showError('استغرق GPS وقتاً طويلاً. تأكد من وجود إشارة وحاول مرة أخرى.');
      setState(() => _isGettingLocation = false);
    } catch (e) {
      _showError('فشل تحديد الموقع: ${e.toString()}');
      setState(() => _isGettingLocation = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PARSE LINK
  // ═══════════════════════════════════════════════════════════════

  void _parseLink(String url) {
    if (url.trim().isEmpty) return;

    setState(() => _isParsing = true);

    try {
      final coords = _extractCoordinates(url);

      if (coords != null && _isValidEgyptCoord(coords.lat, coords.lng)) {
        setState(() {
          _latCtrl.text = coords.lat.toStringAsFixed(6);
          _lngCtrl.text = coords.lng.toStringAsFixed(6);
          _isParsing = false;
        });

        // اكتشاف المحافظة تلقائياً (إن لم تكن محددة)
        final nearestGov = nearestGovernorate(coords.lat, coords.lng);
        if (_selectedGovId == null) {
          setState(() => _selectedGovId = nearestGov.id);
        }

        _notifyParent();
        _showSuccess('✅ تم استخراج الإحداثيات بنجاح');
      } else if (coords != null) {
        setState(() => _isParsing = false);
        _showError('⚠️ الإحداثيات خارج نطاق مصر');
      } else {
        setState(() => _isParsing = false);
        _showError('❌ تعذر استخراج الإحداثيات. تأكد من الرابط.');
      }
    } catch (e) {
      setState(() => _isParsing = false);
      _showError('حدث خطأ: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PREVIEW ON MAP (using url_launcher — works on Web & Mobile)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _previewOnMap() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());

    if (lat == null || lng == null) {
      _showError('أدخل إحداثيات صحيحة أولاً');
      return;
    }

    if (!_isValidEgyptCoord(lat, lng)) {
      _showError('الإحداثيات خارج نطاق مصر');
      return;
    }

    final url = Uri.parse(_buildMapPreviewUrl(lat, lng));

    try {
      // ✅ يفتح الخريطة في التطبيق الخارجي (أو تبويب جديد على الويب)
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showError('تعذر فتح تطبيق الخرائط.');
      }
    } catch (e) {
      _showError('حدث خطأ أثناء فتح الخريطة: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ═══════════════════════════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _addressCtrl.dispose();
    _linkCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── 1. المحافظة ───
        DropdownButtonFormField<String>(
          initialValue: _selectedGovId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'المحافظة',
            prefixIcon: Icon(Icons.map_outlined),
            border: OutlineInputBorder(),
          ),
          items: kEgyptGovernorates
              .map((gov) => DropdownMenuItem<String>(
                    value: gov.id,
                    child: Text(gov.nameAr),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() => _selectedGovId = val);
            _notifyParent();
          },
        ),
        const SizedBox(height: 16),

        // ─── 2. العنوان ───
        TextFormField(
          controller: _addressCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'العنوان التفصيلي',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
            hintText: 'مثال: شارع الجيش - الزقازيق',
          ),
          onChanged: (_) => _notifyParent(),
        ),
        const SizedBox(height: 24),

        // ─── 3. الموقع الجغرافي ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'الموقع الجغرافي',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🆕 زر GPS (بارز)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isGettingLocation ? null : _useCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location, size: 20),
                  label: Text(
                    _isGettingLocation
                        ? 'جاري تحديد موقعك...'
                        : 'استخدم موقعي الحالي (GPS)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'سيتم تحديد موقعك بدقة عالية تلقائياً',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),

              // فاصل "أو"
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'أو أدخل يدوياً',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // رابط Google Maps
              TextField(
                controller: _linkCtrl,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'الصق رابط Google Maps',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: _isParsing
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'استخراج الإحداثيات',
                          onPressed: () => _parseLink(_linkCtrl.text),
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: _parseLink,
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  'أو الإحداثيات اليدوية',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),

              // Lat/Lng
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'خط العرض (Lat)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: '30.5877',
                      ),
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'خط الطول (Lng)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: '31.5020',
                      ),
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // زر المعاينة
              OutlinedButton.icon(
                onPressed: _previewOnMap,
                icon: const Icon(Icons.map, size: 18),
                label: const Text('معاينة الموقع على Google Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  minimumSize: const Size(0, 44),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}