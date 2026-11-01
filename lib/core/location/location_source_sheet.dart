// lib/core/location/location_source_sheet.dart
//
// [v1.0 — 2026-10-19] — Wave 5.5c: 5 خيارات لتحديد الموقع (ADR-2)

import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import 'browsing_location_controller.dart';
import 'governorate_picker_sheet.dart';
import 'location_source.dart';

class LocationSourceSheet extends StatefulWidget {
  const LocationSourceSheet({
    super.key,
    required this.controller,
    this.currentLocation,
  });

  final BrowsingLocationController controller;
  final LocationData? currentLocation;

  static Future<LocationData?> show(
    BuildContext context, {
    required BrowsingLocationController controller,
    LocationData? currentLocation,
  }) {
    return showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LocationSourceSheet(
        controller: controller,
        currentLocation: currentLocation,
      ),
    );
  }

  @override
  State<LocationSourceSheet> createState() => _LocationSourceSheetState();
}

class _LocationSourceSheetState extends State<LocationSourceSheet> {
  bool _loading = false;
  LocationSource? _activeSource;
  String? _error;

  Future<void> _pick(LocationSource source) async {
    if (source == LocationSource.manual) {
      Navigator.of(context).pop();
      await GovernoratePickerSheet.show(
        context,
        controller: widget.controller,
      );
      return;
    }

    if (source == LocationSource.onlineSearch) {
      Navigator.of(context).pop();
      final result = await showDialog<PlaceSearchResult>(
        context: context,
        builder: (_) => const _SearchDialog(),
      );
      if (result == null || !mounted) return;

      final loc = LocationData(
        latitude: result.latitude,
        longitude: result.longitude,
        nameAr: result.displayName,
      );
      widget.controller.setPhysicalLocation(
        loc.latitude,
        loc.longitude,
        placeName: loc.nameAr,
        source: LocationSource.onlineSearch,
      );
      if (!mounted) return;
      Navigator.of(context).pop(loc);
      return;
    }

    setState(() {
      _loading = true;
      _activeSource = source;
      _error = null;
    });

    try {
      final loc = await LocationService.getBySource(source)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;

      if (loc == null) {
        setState(() {
          _loading = false;
          _error = 'تعذر الحصول على الموقع من هذا المصدر';
        });
        return;
      }

      widget.controller.setPhysicalLocation(
        loc.latitude,
        loc.longitude,
        placeName: loc.nameAr,
        source: source,
      );
      if (!mounted) return;
      Navigator.of(context).pop(loc);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'خطأ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = widget.currentLocation;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تحديد موقعي',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (loc != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location,
                        color: theme.colorScheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.nameAr ?? 'موقع محدد',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${loc.latitude.toStringAsFixed(3)} N '
                            '${loc.longitude.toStringAsFixed(3)} E',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            ...LocationSource.values.map((source) {
              // تجاهل manual في القائمة هنا لأنها تفتح Sheet آخر
              // لكن نعرضها! المستخدم يجب أن يراها.
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(_iconFor(source), color: theme.colorScheme.primary),
                title: Text(source.labelAr),
                subtitle:
                    Text(source.subtitleAr, style: theme.textTheme.bodySmall),
                trailing: _loading && _activeSource == source
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_left),
                onTap: _loading ? null : () => _pick(source),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(LocationSource source) {
    switch (source) {
      case LocationSource.gps:
        return Icons.gps_fixed;
      case LocationSource.network:
        return Icons.wifi_tethering;
      case LocationSource.lastKnown:
        return Icons.history;
      case LocationSource.manual:
        return Icons.map_outlined;
      case LocationSource.onlineSearch:
        return Icons.search;
    }
  }
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog();

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<PlaceSearchResult> _results = [];
  bool _loading = false;

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _loading = true);
      final r = await LocationService.searchPlaces(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('بحث عن مكان'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'مثال: بورسعيد، الشرق',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      title: Text(r.displayName,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(context).pop(r),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
