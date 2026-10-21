// lib/features/admin/screens/place_detail_screen.dart
//
// [v1.0 — 2026-10-21] — Thin place detail screen (uses sections)
//   - Reduced from 450+ lines to ~220 lines
//   - Delegates UI to PlaceXxxSection widgets
//   - Delegates data extraction to FirestoreUtils

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/helpers/location_url_helper.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../theme/design_tokens.dart';
import '../widgets/place_detail_sections.dart';
import 'add_place_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _updating = false;

  Future<void> _toggleStatus(String field, bool newValue) async {
    setState(() => _updating = true);
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .update({
        field: newValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSnack('✅ تم التحديث', Colors.green);
    } catch (e) {
      _showSnack('❌ خطأ: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _deletePlace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
            'هل أنت متأكد من حذف هذا المكان نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .delete();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showSnack('❌ خطأ: $e', Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _openOnMap(double lat, double lng) async {
    final url = LocationUrlHelper.mapUrl(lat: lat, lng: lng);
    final opened = await LocationUrlHelper.open(url);
    if (!opened) _showSnack('لا يمكن فتح الخريطة', Colors.orange);
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = LocationUrlHelper.directionsUrl(lat: lat, lng: lng);
    final opened = await LocationUrlHelper.open(url);
    if (!opened) _showSnack('لا يمكن فتح الاتجاهات', Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('إدارة المكان'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_updating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = FirestoreUtils.dataOf(snapshot.data!);
          final coords = FirestoreUtils.coordinatesOf(data);
          final tags = FirestoreUtils.stringListOf(data, 'tags');
          final rating = FirestoreUtils.doubleOf(data, 'averageRating');
          final reviewCount = FirestoreUtils.intOf(data, 'reviewCount');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(data, rating, reviewCount),
              const SizedBox(height: 16),
              PlaceStatusSection(
                isActive: FirestoreUtils.boolOf(data, 'isActive'),
                isApproved: FirestoreUtils.boolOf(data, 'isApproved'),
                updating: _updating,
                onToggle: _toggleStatus,
              ),
              const SizedBox(height: 16),
              PlaceLocationSection(
                data: data,
                onOpenMap: () {
                  if (coords != null) _openOnMap(coords.lat, coords.lng);
                },
                onOpenDirections: () {
                  if (coords != null) _openDirections(coords.lat, coords.lng);
                },
              ),
              const SizedBox(height: 16),
              PlaceContactSection(data: data),
              const SizedBox(height: 16),
              PlaceServicesSection(data: data),
              const SizedBox(height: 16),
              PlaceTagsSection(tags: tags),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPlaceScreen(placeId: widget.placeId),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('تعديل المكان'),
                style: FilledButton.styleFrom(
                  backgroundColor: YaBaladiDesignTokens.primaryBlue,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _deletePlace,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('حذف المكان',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      Map<String, dynamic> data, double rating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            YaBaladiDesignTokens.primaryBlue,
            YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FirestoreUtils.stringOf(data, 'nameAr', 'بدون اسم'),
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (FirestoreUtils.stringOf(data, 'nameEn').isNotEmpty)
            Text(
              FirestoreUtils.stringOf(data, 'nameEn'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  FirestoreUtils.stringOf(data, 'categoryId', '—'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('($reviewCount)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
