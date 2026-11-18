// lib/features/admin/screens/geo_zones_admin_screen.dart
// [v1.3 — SEVERITY ADDED]
//   - ADDED: severity 'medium' for GeoJSON import audit log.
//   - KEPT: All v1.2 logic, context capture, UI/UX, repository intact.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/audit_log_service.dart';
import '../../../repositories/geo_zones_repository.dart';
import '../../../models/geo_zone.dart';
import '../../auth/controllers/auth_controller.dart';

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
          _status = 'تم تحميل ${zones.length} منطقة بنجاح';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'خطأ: $e');
    }
  }

  Future<void> _importData() async {
    // ✅ Capture context BEFORE any await (async gap safe)
    final admin = context.read<AuthController>();

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

      // ─── سجل التدقيق عبر AuditLogService ───
      final imported = result['imported'] ?? 0;
      final skipped = result['skipped'] ?? 0;
      final failed = result['failed'] ?? 0;

      await AuditLogService.logAction(
        action: 'استيراد مناطق جغرافية من GeoJSON',
        adminName: admin.displayName,
        target: 'المناطق الجغرافية',
        details: 'تم الاستيراد: $imported | تم التخطي: $skipped | فشل: $failed',
        severity: 'medium',
      );

      await _loadZones();
    } catch (e) {
      if (mounted) setState(() => _status = '❌ خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ دالة لتحديد لون النص بناءً على الحالة
  Color _getStatusColor(ThemeData theme) {
    if (_status.startsWith('✅')) return Colors.green.shade700;
    if (_status.startsWith('❌') || _status.startsWith('خطأ')) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المناطق الجغرافية',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getStatusColor(theme),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
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
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    // ✅ إضافة السحب للتحديث
                    onRefresh: _loadZones,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _zones.length,
                      itemBuilder: (context, index) {
                        final z = _zones[index];
                        return Card(
                          clipBehavior:
                              Clip.antiAlias, // ✅ يمنع تحذير الـ Ink Splash
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(Icons.map,
                                  color: theme.colorScheme.primary),
                            ),
                            title: Text(
                              z.nameAr,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${z.nameEn.toString()} | نقاط: ${z.polygon.length}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ حالة فارغة احترافية
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('لا توجد مناطق جغرافية',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('اضغط على "استيراد من GeoJSON" لإضافة البيانات.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
