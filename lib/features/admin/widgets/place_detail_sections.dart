// lib/features/admin/widgets/place_detail_sections.dart
//
// [v1.1 — 2026-10-25] — FIX: remove unused import + safer GeoPoint cast
//   - REMOVED: unused import '../../../theme/design_tokens.dart'
//     (was flagged as unused_import by flutter analyze)
//   - IMPROVED: GeoPoint cast uses `is GeoPoint` guard instead of `as GeoPoint?`
//     (avoids runtime TypeError if location is not a GeoPoint)
//   - IMPROVED: `Function(String, bool)` → `void Function(String, bool)`
//     (explicit return type for clarity)
//   - KEPT: all widget structure, styling, and behavior identical
//
// [v1.0 — 2026-10-21] — Separate sections for place detail screen

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'common_widgets.dart';

// ═══════════════════════════════════════════════════════════════
// Status Section
// ═══════════════════════════════════════════════════════════════
class PlaceStatusSection extends StatelessWidget {
  final bool isActive;
  final bool isApproved;
  final bool updating;
  final void Function(String field, bool value) onToggle;

  const PlaceStatusSection({
    super.key,
    required this.isActive,
    required this.isApproved,
    required this.updating,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSection(
      title: 'حالة المكان',
      icon: Icons.tune,
      children: [
        SwitchListTile(
          value: isActive,
          onChanged: updating ? null : (v) => onToggle('isActive', v),
          title: const Text('نشط'),
          subtitle: const Text('يظهر في التطبيق للجميع'),
          secondary: Icon(
            isActive ? Icons.check_circle : Icons.block,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        SwitchListTile(
          value: isApproved,
          onChanged: updating ? null : (v) => onToggle('isApproved', v),
          title: const Text('معتمد'),
          subtitle: const Text('تمت مراجعته من الأدمن'),
          secondary: Icon(
            isApproved ? Icons.verified : Icons.pending,
            color: isApproved ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Location Section
// ═══════════════════════════════════════════════════════════════
class PlaceLocationSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenDirections;

  const PlaceLocationSection({
    super.key,
    required this.data,
    required this.onOpenMap,
    required this.onOpenDirections,
  });

  @override
  Widget build(BuildContext context) {
    // GeoPoint-safe extraction
    final location = data['location'];
    final geoPoint = location is GeoPoint ? location : null;

    final lat = (data['latitude'] as num?)?.toDouble() ?? geoPoint?.latitude;
    final lng = (data['longitude'] as num?)?.toDouble() ?? geoPoint?.longitude;

    final hasLocation = lat != null && lng != null;
    final address = data['address']?.toString() ?? '';
    final governorate = data['governorate']?.toString() ?? '';
    final geohash = data['geohash']?.toString();

    return AdminSection(
      title: 'الموقع',
      icon: Icons.location_on,
      children: [
        if (address.isNotEmpty)
          AdminDetailRow(label: 'العنوان', value: address),
        if (governorate.isNotEmpty)
          AdminDetailRow(label: 'المحافظة', value: governorate),
        if (geohash != null) AdminDetailRow(label: 'Geohash', value: geohash),
        if (hasLocation) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpenMap,
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('فتح الخريطة'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenDirections,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('الاتجاهات'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'لا توجد إحداثيات لهذا المكان',
                  style: TextStyle(color: Colors.orange[800], fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Contact Section
// ═══════════════════════════════════════════════════════════════
class PlaceContactSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const PlaceContactSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final phone = data['phone']?.toString() ?? '';
    final website = data['website']?.toString() ?? '';

    if (phone.isEmpty && website.isEmpty) return const SizedBox.shrink();

    return AdminSection(
      title: 'التواصل',
      icon: Icons.contact_phone,
      children: [
        if (phone.isNotEmpty) AdminDetailRow(label: 'الهاتف', value: phone),
        if (website.isNotEmpty)
          AdminDetailRow(label: 'الموقع الإلكتروني', value: website),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Services Section
// ═══════════════════════════════════════════════════════════════
class PlaceServicesSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const PlaceServicesSection({super.key, required this.data});

  bool _hasAny() {
    return data['hasWifi'] == true ||
        data['hasParking'] == true ||
        data['hasRestroom'] == true ||
        data['hasAccessibility'] == true ||
        data['isFamilyFriendly'] == true ||
        data['isHalal'] == true ||
        data['hasDelivery'] == true ||
        data['hasReservation'] == true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAny()) return const SizedBox.shrink();

    return AdminSection(
      title: 'الخدمات المتاحة',
      icon: Icons.room_service,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (data['hasWifi'] == true)
                const AdminServiceChip(
                    icon: Icons.wifi, label: 'واي فاي', color: Colors.blue),
              if (data['hasParking'] == true)
                const AdminServiceChip(
                    icon: Icons.local_parking,
                    label: 'موقف',
                    color: Colors.purple),
              if (data['hasRestroom'] == true)
                const AdminServiceChip(
                    icon: Icons.wc, label: 'دورة مياه', color: Colors.indigo),
              if (data['hasAccessibility'] == true)
                const AdminServiceChip(
                    icon: Icons.accessible,
                    label: 'سهولة وصول',
                    color: Colors.cyan),
              if (data['isFamilyFriendly'] == true)
                const AdminServiceChip(
                    icon: Icons.family_restroom,
                    label: 'عائلات',
                    color: Colors.pink),
              if (data['isHalal'] == true)
                const AdminServiceChip(
                    icon: Icons.restaurant_menu,
                    label: 'حلال',
                    color: Colors.green),
              if (data['hasDelivery'] == true)
                const AdminServiceChip(
                    icon: Icons.delivery_dining,
                    label: 'توصيل',
                    color: Colors.red),
              if (data['hasReservation'] == true)
                const AdminServiceChip(
                    icon: Icons.event_seat, label: 'حجز', color: Colors.brown),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tags Section
// ═══════════════════════════════════════════════════════════════
class PlaceTagsSection extends StatelessWidget {
  final List<String> tags;

  const PlaceTagsSection({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return AdminSection(
      title: 'الكلمات المفتاحية',
      icon: Icons.tag,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
