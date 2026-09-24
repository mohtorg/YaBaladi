// screens/admin/admin_place_form_screen.dart
//
// ============================================================
// ╪د┘┘┘â╪▒╪ر ╪د┘╪╣╪د┘à╪ر ┘à┘ ╪د┘╪┤╪د╪┤╪ر ╪»┘è:
// ┘┘ê╪▒┘à ┘ê╪د╪ص╪» ╪ذ┘è╪«╪»┘à ╪ص╪د┘╪ز┘è┘: "╪ح╪╢╪د┘╪ر ┘à┘â╪د┘ ╪ش╪»┘è╪»" ┘ê"╪ز╪╣╪»┘è┘ ┘à┘â╪د┘ ┘à┘ê╪ش┘ê╪»".
// ╪د┘┘╪▒┘é ╪د┘┘ê╪ص┘è╪»: ┘┘ê existingPlace ╪د╪ز╪ذ╪╣╪ز┘┘╪د╪î ╪ذ┘┘à┘╪ث ╪د┘╪ص┘é┘ê┘ ╪ذ┘é┘è┘à┘ç ╪د┘┘é╪»┘è┘à╪ر
// ┘ê╪ذ┘╪ص╪»┘ّ╪س ┘┘╪│ ╪د┘┘à╪│╪ز┘╪» ╪ذ╪»┘ ┘à╪د ┘┘╪┤╪خ ┘ê╪د╪ص╪» ╪ش╪»┘è╪». ┘â╪»┘ç ┘à┘┘â╪▒╪▒╪┤ ┘┘╪│ ╪د┘┘┘ê╪▒┘à ┘à╪▒╪ز┘è┘.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/place.dart';
import '../../models/egypt_governorates.dart';
import '../../models/audience_tags.dart';
import '../../models/place_categories.dart';
import '../../models/app_content_type.dart';
import '../../services/location_service.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/locale_controller.dart';

class AdminPlaceFormScreen extends StatefulWidget {
  final Place? existingPlace; // null = ╪ح╪╢╪د┘╪ر ╪ش╪»┘è╪»╪ر╪î ╪║┘è╪▒ null = ╪ز╪╣╪»┘è┘

  const AdminPlaceFormScreen({super.key, this.existingPlace});

  @override
  State<AdminPlaceFormScreen> createState() => _AdminPlaceFormScreenState();
}

class _AdminPlaceFormScreenState extends State<AdminPlaceFormScreen> {
  // ------------------------------------------------------------
  // ╪د┘┘┘â╪▒╪ر: ┘â┘ ╪ص┘é┘ ┘╪╡┘è ┘┘è ╪د┘┘┘ê╪▒┘à ┘┘è┘ç Controller ┘à┘┘╪╡┘╪î ┘ê╪ذ┘┘à┘╪ث┘ç┘à
  // ╪ذ╪د┘┘é┘è┘à ╪د┘┘é╪»┘è┘à╪ر ┘┘ê ╪ح╪ص┘╪د ┘┘è ┘ê╪╢╪╣ "╪ز╪╣╪»┘è┘" (initState)
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
  bool _isLocating = false;

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
  // ╪د┘┘┘â╪▒╪ر: ╪»╪د┘╪ر ╪د┘╪ص┘╪╕ - ╪ذ╪ز╪ذ┘┘è Map ┘ê╪د╪ص╪» ┘à┘ ┘â┘ ╪د┘╪ص┘é┘ê┘╪î ┘ê╪ذ╪ز┘é╪▒╪▒
  // (╪ذ┘╪د╪ة┘ï ╪╣┘┘ë _isEditing) ┘ç┘ ╪ز╪╣┘à┘ update ┘┘┘à╪│╪ز┘╪» ╪د┘┘é╪»┘è┘à
  // ┘ê┘╪د ╪ز╪╣┘à┘ add ┘┘à╪│╪ز┘╪» ╪ش╪»┘è╪» ╪ذ╪د┘┘â╪د┘à┘
  // ------------------------------------------------------------
  // ┘à┘╪د╪ص╪╕╪ر ╪د┘╪ز╪╣╪»┘è┘:
  // ╪ث╪╢┘┘╪د try/catch/finally ╪ص┘ê┘ ╪د┘╪ص┘╪╕ ╪ص╪ز┘ë ╪ز╪╕┘ç╪▒ ╪ث╪«╪╖╪د╪ة Permission Denied ╪ث┘ê ╪د┘╪┤╪ذ┘â╪ر
  // ┘┘┘à╪│╪ز╪«╪»┘à ╪ذ╪»┘ ╪«╪▒┘ê╪ش ╪د┘╪┤╪د╪┤╪ر ╪ح┘┘ë ╪ص╪د┘╪ر ╪║┘è╪▒ ┘à╪╣╪▒┘ê┘╪ر. ┘â┘à╪د ┘╪ص╪د┘╪╕ ╪╣┘┘ë isSaving ╪ذ╪╡┘ê╪▒╪ر ╪╡╪ص┘è╪ص╪ر.
  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    final result = await LocationService().getCurrentLocation(allowCached: false);
    if (!mounted) return;
    setState(() => _isLocating = false);
    if (!result.isSuccess || result.position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_locationErrorText(result.error))),
      );
      return;
    }
    final position = result.position!;
    _lat.text = position.latitude.toStringAsFixed(7);
    _lng.text = position.longitude.toStringAsFixed(7);
    final address = await LocationService().addressFromCoordinates(position.latitude, position.longitude);
    if (!mounted) return;
    if (address.isSuccess && address.address != null && _addressAr.text.trim().isEmpty) {
      _addressAr.text = address.address!;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of('location_selected_success', LocaleController.of(context).locale.languageCode))),
    );
    setState(() {});
  }

  Future<void> _searchAddress() async {
    final address = _addressAr.text.trim().isNotEmpty ? _addressAr.text.trim() : _addressEn.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of('merchant_location_address_required', LocaleController.of(context).locale.languageCode))),
      );
      return;
    }
    setState(() => _isLocating = true);
    final result = await LocationService().coordinatesFromAddress(address);
    if (!mounted) return;
    setState(() => _isLocating = false);
    if (!result.isSuccess || result.latitude == null || result.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of('merchant_location_search_failed', LocaleController.of(context).locale.languageCode))),
      );
      return;
    }
    _lat.text = result.latitude!.toStringAsFixed(7);
    _lng.text = result.longitude!.toStringAsFixed(7);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of('location_selected_success', LocaleController.of(context).locale.languageCode))),
    );
    setState(() {});
  }

  String _locationErrorText(LocationError? error) {
    final lang = LocaleController.of(context).locale.languageCode;
    switch (error) {
      case LocationError.serviceDisabled:
        return AppStrings.of('location_service_disabled', lang);
      case LocationError.permissionDenied:
        return AppStrings.of('location_permission_denied', lang);
      case LocationError.permissionDeniedForever:
        return AppStrings.of('location_permission_denied_forever', lang);
      case LocationError.unavailable:
      case null:
        return AppStrings.of('location_unavailable', lang);
    }
  }

  Future<void> _save() async {
    if (_nameAr.text.trim().isEmpty || _nameEn.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('╪د╪│┘à ╪د┘┘à┘â╪د┘ ╪ذ╪د┘╪╣╪▒╪ذ┘è ┘ê╪د┘╪ح┘╪ش┘┘è╪▓┘è ┘à╪╖┘┘ê╪ذ┘è┘')),
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
        SnackBar(content: Text('╪ز╪╣╪░╪▒ ╪ص┘╪╕ ╪د┘┘à┘â╪د┘: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ┘à┘╪د╪ص╪╕╪ر ╪د┘╪ز╪╣╪»┘è┘:
  // ╪ز╪ص╪▒┘è╪▒ ╪ش┘à┘è╪╣ TextEditingController ╪╣┘╪» ╪ح╪║┘╪د┘é ╪د┘╪┤╪د╪┤╪ر ┘┘à┘╪╣ ╪ز╪│╪▒╪ذ ╪د┘┘à┘ê╪د╪▒╪».
  List<Widget> _propertySwitches() => [
    SwitchListTile(title: const Text('┘à┘ê┘é┘ ╪│┘è╪د╪▒╪د╪ز'), value: _hasParking, onChanged: (v) => setState(() => _hasParking = v)),
    SwitchListTile(title: const Text('Wi-Fi'), value: _hasWifi, onChanged: (v) => setState(() => _hasWifi = v)),
    SwitchListTile(title: const Text('╪»┘╪╣ ╪ح┘┘â╪ز╪▒┘ê┘┘è'), value: _acceptsElectronicPayment, onChanged: (v) => setState(() => _acceptsElectronicPayment = v)),
    SwitchListTile(title: const Text('╪«╪»┘à╪ر ╪ز┘ê╪╡┘è┘'), value: _hasDelivery, onChanged: (v) => setState(() => _hasDelivery = v)),
    SwitchListTile(title: const Text('┘è╪ز╪╖┘╪ذ ╪ص╪ش╪▓┘ï╪د ┘à╪│╪ذ┘é┘ï╪د'), value: _requiresReservation, onChanged: (v) => setState(() => _requiresReservation = v)),
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
        title: Text(_isEditing ? '╪ز╪╣╪»┘è┘ ╪د┘┘à┘â╪د┘' : '╪ح╪╢╪د┘╪ر ┘à┘â╪د┘ ╪ش╪»┘è╪»'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('╪د┘╪د╪│┘à ╪ذ╪د┘╪╣╪▒╪ذ┘è', _nameAr),
          _field('╪د┘╪د╪│┘à ╪ذ╪د┘╪ح┘╪ش┘┘è╪▓┘è', _nameEn),
          _field('╪د┘┘ê╪╡┘ ╪ذ╪د┘╪╣╪▒╪ذ┘è', _descAr, maxLines: 3),
          _field('╪د┘┘ê╪╡┘ ╪ذ╪د┘╪ح┘╪ش┘┘è╪▓┘è', _descEn, maxLines: 3),
          _field('╪د┘╪╣┘┘ê╪د┘ ╪ذ╪د┘╪╣╪▒╪ذ┘è', _addressAr),
          _field('╪د┘╪╣┘┘ê╪د┘ ╪ذ╪د┘╪ح┘╪ش┘┘è╪▓┘è', _addressEn),
          // ┘┘ê╪╣ ╪د┘┘à╪ص╪ز┘ê┘ë ┘à┘┘╪╡┘ ╪╣┘ ╪د┘╪ز╪╡┘┘è┘: ┘è╪ص╪»╪» ╪»┘ê╪▒╪ر ╪د┘╪ح╪»╪د╪▒╪ر ┘ê╪د┘╪ز┘ê╪│╪╣╪î ╪ذ┘è┘┘à╪د category ╪ز╪╡┘ ╪د┘┘╪┤╪د╪╖.
          const Text('┘┘ê╪╣ ╪د┘┘à╪ص╪ز┘ê┘ë', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: AppContentType.byId(_contentType)?.id ?? AppContentType.publicPlace.id,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: AppContentType.all.map((c) => DropdownMenuItem(value: c.id, child: Text(c.labelAr))).toList(),
            onChanged: (value) { if (value != null) setState(() => _contentType = value); },
          ),
          const SizedBox(height: 16),

          // ╪د┘╪ز╪╡┘┘è┘ ┘è┘╪«╪ز╪د╪▒ ┘à┘ ┘é╪د╪خ┘à╪ر ┘à┘ê╪ص╪»╪ر ╪ص╪ز┘ë ┘╪د ╪ز╪ز┘â╪▒╪▒ ┘é┘è┘à category ╪ذ╪╡┘è╪║ ┘à╪«╪ز┘┘╪ر.
          const Text('┘┘ê╪╣ ╪د┘┘à┘â╪د┘ / ╪د┘┘╪┤╪د╪╖', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: PlaceCategories.byId(_category.text.trim())?.id ?? '╪ث╪«╪▒┘ë',
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: PlaceCategories.all.map((c) => DropdownMenuItem(value: c.id, child: Text(c.labelAr))).toList(),
            onChanged: (value) { if (value != null) _category.text = value; setState(() {}); },
          ),
          _field('╪▒╪د╪ذ╪╖ ╪د┘╪╡┘ê╪▒╪ر', _imageUrl),
          _field('╪│╪د╪╣╪د╪ز ╪د┘╪╣┘à┘ ╪ذ╪د┘╪╣╪▒╪ذ┘è', _hoursAr),
          _field('╪│╪د╪╣╪د╪ز ╪د┘╪╣┘à┘ ╪ذ╪د┘╪ح┘╪ش┘┘è╪▓┘è', _hoursEn),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.of('merchant_location_title', LocaleController.of(context).locale.languageCode),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(AppStrings.of('merchant_location_hint', LocaleController.of(context).locale.languageCode)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLocating ? null : _searchAddress,
                          icon: const Icon(Icons.search),
                          label: Text(AppStrings.of('merchant_location_search', LocaleController.of(context).locale.languageCode)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLocating ? null : _useCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: Text(AppStrings.of('merchant_location_current', LocaleController.of(context).locale.languageCode)),
                        ),
                      ),
                    ],
                  ),
                  if (_isLocating) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field('╪«╪╖ ╪د┘╪╣╪▒╪╢ (Lat)', _lat)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('╪«╪╖ ╪د┘╪╖┘ê┘ (Lng)', _lng)),
                    ],
                  ),
                  Text(
                    AppStrings.of('merchant_location_manual_fallback', LocaleController.of(context).locale.languageCode),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------------------
          // ╪د┘┘┘â╪▒╪ر: ┘é╪د╪خ┘à╪ر ┘à┘╪│╪»┘╪ر ┘┘┘à╪ص╪د┘╪╕╪ر - ┘┘╪│ ╪د┘┘é╪د╪خ┘à╪ر ╪د┘╪س╪د╪ذ╪ز╪ر ╪د┘┘à╪│╪ز╪«╪»┘à╪ر
          // ┘┘è ┘â┘ ╪د┘╪ز╪╖╪ذ┘è┘é╪î ╪╣╪┤╪د┘ ╪د┘┘é┘è┘à╪ر ╪د┘┘à╪ص┘┘ê╪╕╪ر ╪ز╪ز╪╖╪د╪ذ┘é ╪»╪د┘è┘à┘ï╪د
          // ------------------------------------------------------------
          const Text('╪د┘┘à╪ص╪د┘╪╕╪ر', style: TextStyle(fontWeight: FontWeight.bold)),
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
            title: const Text('┘à┘╪┤┘ê╪▒ ┘┘┘à╪│╪ز╪«╪»┘à┘è┘'),
            subtitle: const Text('╪ح┘╪║╪د╪ة ╪د┘┘╪┤╪▒ ┘è╪«┘┘è ╪د┘┘à╪ص╪ز┘ê┘ë ╪╣┘ ┘ê╪د╪ش┘ç╪ر ╪د┘┘à╪│╪ز╪«╪»┘à ╪»┘ê┘ ╪ص╪░┘┘ç.'),
            value: _isPublished,
            onChanged: (value) => setState(() => _isPublished = value),
          ),

          // ------------------------------------------------------------
          // ╪د┘┘┘â╪▒╪ر: ┘╪╡ ╪╣╪▒╪╢ ╪د┘╪«╪╡┘à ╪د┘┘┘è ┘ç┘è╪╕┘ç╪▒ ┘â┘à┘â╪د┘╪ث╪ر ┘┘┘à╪│╪ز╪«╪»┘à ╪ذ╪╣╪» ┘à╪د ┘è┘é┘è┘ّ┘à
          // ╪▓┘è╪د╪▒╪ز┘ç ╪د┘┘à┘ê╪س┘ّ┘é╪ر ┘┘ç╪░╪د ╪د┘┘à┘â╪د┘. ┘┘ê ╪│╪د┘è╪ذ┘ç ┘╪د╪╢┘è╪î ┘ç┘è╪ز╪│╪ز╪«╪»┘à ┘╪╡ ╪د┘╪ز╪▒╪د╪╢┘è ╪╣╪د┘à
          // ------------------------------------------------------------
          _field('╪╣╪▒╪╢ ╪د┘╪«╪╡┘à ╪ذ╪╣╪» ╪د┘╪ز┘é┘è┘è┘à (╪د╪«╪ز┘è╪د╪▒┘è╪î ┘à╪س╪د┘: ╪«╪╡┘à 15% ╪╣┘┘ë ╪د┘┘╪د╪ز┘ê╪▒╪ر)', _discountOffer),

          // ------------------------------------------------------------
          // ╪د┘┘┘â╪▒╪ر: ┘à┘╪ز╪د╪ص "┘à╪ش╪د┘┘è ╪ذ╪د┘┘â╪د┘à┘" - ┘┘ê ┘à┘╪╣┘ّ┘╪î ╪ذ┘è╪ز╪«┘┘ë ╪د╪«╪ز┘è╪د╪▒
          // ┘╪╖╪د┘é ╪د┘╪│╪╣╪▒ ╪ز┘┘é╪د╪خ┘è┘ï╪د ┘╪ث┘┘ç ┘à╪د┘┘ê╪┤ ┘à╪╣┘┘ë ┘┘à┘â╪د┘ ┘à╪ش╪د┘┘è
          // ------------------------------------------------------------
          SwitchListTile(
            title: const Text('┘à╪│┘à┘ê╪ص ╪ذ╪»╪«┘ê┘ ╪د┘╪ث┘â┘'),
            subtitle: const Text('┘à╪╣┘┘ê┘à╪ر ╪ز╪╕┘ç╪▒ ┘â┘┘╪ز╪▒ ┘┘┘à╪│╪ز╪«╪»┘à'),
            value: _allowFoodInside,
            onChanged: (value) => setState(() => _allowFoodInside = value),
          ),

          const SizedBox(height: 12),
          const Text('╪«╪╡╪د╪خ╪╡ ╪د┘┘à┘â╪د┘ ┘ê╪د┘╪«╪»┘à╪د╪ز', style: TextStyle(fontWeight: FontWeight.bold)),
          // ┘ç╪░┘ç ╪د┘╪«╪╡╪د╪خ╪╡ ┘╪د ╪ز╪ص╪»╪» ╪د┘╪ش┘à┘ç┘ê╪▒╪ؤ ┘ç┘è ┘à╪╣┘┘ê┘à╪د╪ز ┘é╪د╪ذ┘╪ر ┘┘┘┘╪ز╪▒╪ر ┘┘┘à╪│╪ز╪«╪»┘à.
          ..._propertySwitches(),

          SwitchListTile(
            title: const Text('┘à┘â╪د┘ ┘à╪ش╪د┘┘è ╪ذ╪د┘┘â╪د┘à┘'),
            value: _isFree,
            onChanged: (value) => setState(() => _isFree = value),
          ),
          if (!_isFree) ...[
            const SizedBox(height: 8),
            const Text('┘╪╖╪د┘é ╪د┘╪│╪╣╪▒ ╪د┘╪ز┘é╪▒┘è╪ذ┘è', style: TextStyle(fontWeight: FontWeight.bold)),
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
          // ╪د┘┘┘â╪▒╪ر: ┘╪خ╪د╪ز ╪د┘╪ش┘à┘ç┘ê╪▒ - ┘┘╪│ ╪د┘┘ Chips ╪د┘┘à╪│╪ز╪«╪»┘à╪ر ┘┘è ╪┤╪د╪┤╪ر ╪د┘┘┘╪ز╪▒╪ر╪î
          // ┘┘â┘ ┘ç┘╪د ╪ذ╪ز╪ص╪»╪» ╪د┘┘╪خ╪د╪ز ╪د┘┘╪╣┘┘è╪ر ┘┘┘à┘â╪د┘ ╪ذ╪»┘ ┘à╪د ╪ز┘┘╪ز╪▒ ╪ذ┘è┘ç╪د
          // ------------------------------------------------------------
          const Text('┘à┘╪د╪│╪ذ ┘┘ (┘╪خ╪د╪ز ╪د┘╪ش┘à┘ç┘ê╪▒)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                : Text(_isEditing ? '╪ص┘╪╕ ╪د┘╪ز╪╣╪»┘è┘╪د╪ز' : '╪ح╪╢╪د┘╪ر ╪د┘┘à┘â╪د┘'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ╪د┘┘┘â╪▒╪ر: ╪»╪د┘╪ر ┘à╪│╪د╪╣╪»╪ر ╪ذ╪│┘è╪╖╪ر ╪ذ╪ز╪▒╪ش╪╣ ┘┘╪│ ╪ز╪╡┘à┘è┘à TextField ┘┘è ┘â┘ ┘à┘â╪د┘
  // ╪ذ╪»┘ ┘à╪د ┘┘â╪▒╪▒ ┘┘╪│ ╪د┘┘ decoration ┘┘è ┘â┘ ╪ص┘é┘ ┘à┘ ╪د┘┘ 10 ╪ص┘é┘ê┘ ┘┘ê┘é
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
