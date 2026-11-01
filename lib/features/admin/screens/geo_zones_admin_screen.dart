// lib/features/admin/screens/geo_zones_admin_screen.dart
import 'package:flutter/material.dart';
import '../../../repositories/geo_zones_repository.dart';
import '../../../models/geo_zone.dart';

class GeoZonesAdminScreen extends StatefulWidget {
  const GeoZonesAdminScreen({super.key});

  @override
  State<GeoZonesAdminScreen> createState() => _GeoZonesAdminScreenState();
}

class _GeoZonesAdminScreenState extends State<GeoZonesAdminScreen> {
  bool _isLoading = false;
  String _status = 'جارٍ التحميل...';
  List<GeoZone> _zones = [];

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final zones = await GeoZonesRepository.instance.getAllZones();
      if (mounted) {
        setState(() {
          _zones = zones;
          _status = 'تم تحميل ${zones.length} منطقة';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'خطأ: $e');
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
      _status = 'جارٍ استيراد البيانات من GeoJSON...';
    });
    try {
      final result = await GeoZonesRepository.instance.importFromGeoJson();
      if (!mounted) return;
      setState(() {
        _status =
            '✅ تم الاستيراد: ${result['imported']} | تم التخطي: ${result['skipped']} | فشل: ${result['failed']}';
      });
      await _loadZones();
    } catch (e) {
      if (mounted) setState(() => _status = '❌ خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المناطق الجغرافية')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_status, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _importData,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.download),
                        label:
                            Text(_isLoading ? 'جارٍ...' : 'استيراد من GeoJSON'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _zones.isEmpty
                ? const Center(child: Text('لا توجد مناطق في قاعدة البيانات.'))
                : ListView.builder(
                    itemCount: _zones.length,
                    itemBuilder: (context, index) {
                      final z = _zones[index];
                      return ListTile(
                        leading: const Icon(Icons.map),
                        title: Text(z.nameAr),
                        subtitle:
                            Text('${z.nameEn} | نقاط: ${z.polygon.length}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
