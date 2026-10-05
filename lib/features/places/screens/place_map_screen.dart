import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/categories/controllers/categories_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

/// خريطة:
/// - لمكان واحد (placeId ممرَّر)
/// - أو لتصنيف كامل (categoryId ممرَّر)
///
/// تستخدم OpenStreetMap عبر flutter_map — بدون API key.
class PlaceMapScreen extends StatefulWidget {
  const PlaceMapScreen({
    super.key,
    this.placeId,
    this.categoryId,
  }) : assert(
          placeId != null || categoryId != null,
          'Either placeId or categoryId must be provided',
        );

  final String? placeId;
  final String? categoryId;

  @override
  State<PlaceMapScreen> createState() => _PlaceMapScreenState();
}

class _PlaceMapScreenState extends State<PlaceMapScreen> {
  final _repo = PlacesRepository();
  final _mapController = MapController();

  List<Place> _places = const [];
  bool _loading = true;
  String? _error;

  static const _defaultCenter = LatLng(26.8206, 30.8025);
  static const _defaultZoom = 6.0;
  static const _singlePlaceZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<Place> places;

      if (widget.placeId != null) {
        final p = await _repo.getById(widget.placeId!);
        places = p != null ? [p] : [];
      } else if (widget.categoryId != null) {
        places = await _repo.search(
          query: '',
          categoryId: widget.categoryId,
        );
      } else {
        places = [];
      }

      // نعرض بس الأماكن اللي عندها إحداثيات
      places = places.where((p) => p.location != null).toList();

      if (!mounted) return;

      setState(() {
        _places = places;
        _loading = false;
      });

      if (places.isNotEmpty) {
        final first = places.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(
            LatLng(
              first.location!.latitude,
              first.location!.longitude,
            ),
            widget.placeId != null ? _singlePlaceZoom : 11.0,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    String title = l10n.appName;
    if (widget.placeId != null && _places.isNotEmpty) {
      title = isArabic ? _places.first.nameAr : _places.first.nameEn;
    } else if (widget.categoryId != null) {
      final cats = context.read<CategoriesController>().categories;
      final cat = cats.where((c) => c.id == widget.categoryId).firstOrNull;
      if (cat != null) title = isArabic ? cat.nameAr : cat.nameEn;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: l10n.recenter,
            onPressed: _recenter,
          ),
        ],
      ),
      body: _buildBody(isArabic),
    );
  }

  Widget _buildBody(bool isArabic) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    if (_places.isEmpty) {
      return const _EmptyView();
    }

    LatLng center = _defaultCenter;
    double zoom = _defaultZoom;

    if (_places.first.location != null) {
      center = LatLng(
        _places.first.location!.latitude,
        _places.first.location!.longitude,
      );
      zoom = widget.placeId != null ? _singlePlaceZoom : 11.0;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 3,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.egypt.yabaladi_rebuild',
          maxNativeZoom: 19,
        ),
        MarkerLayer(
          markers: _places.map((p) {
            final loc = p.location!;
            return Marker(
              point: LatLng(loc.latitude, loc.longitude),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _showPlaceSheet(p, isArabic),
                child: _PlaceMarker(
                  label: isArabic ? p.nameAr : p.nameEn,
                ),
              ),
            );
          }).toList(),
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  void _recenter() {
    if (_places.isEmpty || _places.first.location == null) return;
    _mapController.move(
      LatLng(
        _places.first.location!.latitude,
        _places.first.location!.longitude,
      ),
      widget.placeId != null ? _singlePlaceZoom : 11.0,
    );
  }

  void _showPlaceSheet(Place place, bool isArabic) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PlaceBottomSheet(
        place: place,
        isArabic: isArabic,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MARKER
// ═══════════════════════════════════════════════════════════════

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Icon(
          Icons.location_on,
          size: 32,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════

class _PlaceBottomSheet extends StatelessWidget {
  const _PlaceBottomSheet({
    required this.place,
    required this.isArabic,
  });

  final Place place;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final name = isArabic ? place.nameAr : place.nameEn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (place.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              place.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 4),
              Text(place.averageRating.toStringAsFixed(1)),
              const SizedBox(width: 8),
              Text(
                '(${place.reviewCount})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(RoutePaths.placePath(place.id));
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: Text(l10n.details),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDirections(place),
                  icon: const Icon(Icons.directions, size: 18),
                  label: Text(l10n.directions),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(Place place) async {
    final lat = place.location!.latitude;
    final lng = place.location!.longitude;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY / ERROR
// ═══════════════════════════════════════════════════════════════

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noCoordinates,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}