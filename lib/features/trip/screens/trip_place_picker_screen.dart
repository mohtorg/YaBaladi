// lib/features/trip/screens/trip_place_picker_screen.dart
//
// [v1.1 — 2026-10-17] — Fix analyzer errors (missing import + types)
//   - ADDED: import '../../../models/trip_draft.dart'
//   - FIX: catch (e) → on Exception catch (e)
//   - FIX: const constructors & trailing commas

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/place.dart';
import '../../../models/trip_draft.dart'; // ✅ FIX: Missing import
import '../../../models/trip_plan.dart';
import '../../../theme/design_tokens.dart';
import '../../../widgets/ya_app_bar.dart';
import '../../places/controllers/places_controller.dart';
import '../../../services/trip_draft_service.dart';

class TripPlacePickerScreen extends StatefulWidget {
  const TripPlacePickerScreen({
    super.key,
    required this.initialStops,
    required this.governorateId,
    required this.governorateNameAr,
    required this.maxStops,
    this.userId = 'guest',
  });

  final List<TripStop> initialStops;
  final String governorateId;
  final String governorateNameAr;
  final int maxStops;
  final String userId;

  @override
  State<TripPlacePickerScreen> createState() => _TripPlacePickerScreenState();
}

class _TripPlacePickerScreenState extends State<TripPlacePickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<TripStop> _selectedStops;

  String _searchQuery = '';
  String? _selectedCategory;

  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedStops = List.from(widget.initialStops);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final placesCtrl = context.read<PlacesController>();
      if (placesCtrl.allPlacesRaw.isEmpty ||
          placesCtrl.mode != PlacesMode.all) {
        placesCtrl.load();
      }
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════

  bool _isSelected(String placeId) =>
      _selectedStops.any((s) => s.placeId == placeId);

  void _addPlace(Place place) {
    if (_isSelected(place.id)) return;
    if (_selectedStops.length >= widget.maxStops) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'وصلت الحد الأقصى (${widget.maxStops}) — احذف مكاناً أولاً',
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }

    final stop = TripStop(
      placeId: place.id,
      placeNameAr: place.nameAr,
      placeNameEn: place.nameEn,
      placeImageUrl:
          place.imageUrls.isNotEmpty ? place.imageUrls.first : null,
      lat: place.location?.latitude ?? 0,
      lng: place.location?.longitude ?? 0,
      categoryId: place.categoryId,
      rating: place.averageRating,
      reviewCount: place.reviewCount,
      plannedDurationMin: 60,
    );

    setState(() => _selectedStops.add(stop));
    _scheduleSave();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('✅ أُضيف: ${place.nameAr}'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () {
              if (!mounted) return;
              setState(() => _selectedStops.remove(stop));
              _scheduleSave();
            },
          ),
        ),
      );
  }

  void _removeStop(TripStop stop) {
    final removed = stop;
    setState(() => _selectedStops.remove(stop));
    _scheduleSave();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('🗑️ حُذف: ${removed.placeNameAr}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () {
              if (!mounted) return;
              setState(() => _selectedStops.add(removed));
              _scheduleSave();
            },
          ),
        ),
      );
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  Future<void> _saveNow() async {
    try {
      // ✅ FIX: الآن existing نوعه TripDraft (بفضل الاستيراد)
      final existing = await TripDraftService.load(widget.userId) ??
          TripDraft.empty(widget.userId);

      final tempPlan = TripPlan(
        id: '',
        userId: widget.userId,
        title: existing.title,
        governorateId: widget.governorateId,
        governorateNameAr: widget.governorateNameAr,
        transportMode: existing.transportMode,
        durationType: existing.durationType,
        interests: existing.interests,
        status: TripStatus.draft,
        stops: _selectedStops,
        totalDistanceKm: 0,
        totalDurationMin: 0,
      );

      final updated = existing.copyWith(
        currentStep: 2,
        governorateId: widget.governorateId,
        generatedPlanJson: _encodePlan(tempPlan),
      );
      await TripDraftService.save(updated);
    } on Exception catch (e) {
      debugPrint('❌ _saveNow failed: $e');
    }
  }

  String _encodePlan(TripPlan plan) {
    return _manualJsonEncode(plan);
  }

  String _manualJsonEncode(TripPlan plan) {
    return '{"stops":${_stopsToJson(plan.stops)},"title":"${_escape(plan.title)}","governorateId":"${plan.governorateId}","governorateNameAr":"${_escape(plan.governorateNameAr)}"}';
  }

  String _stopsToJson(List<TripStop> stops) {
    final parts = stops.map((s) {
      return '{"placeId":"${_escape(s.placeId)}","placeNameAr":"${_escape(s.placeNameAr)}","placeNameEn":"${_escape(s.placeNameEn)}","lat":${s.lat},"lng":${s.lng},"categoryId":"${_escape(s.categoryId)}","rating":${s.rating},"reviewCount":${s.reviewCount},"plannedDurationMin":${s.plannedDurationMin ?? 60}}';
    }).join(',');
    return '[$parts]';
  }

  String _escape(String s) => s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');

  // ═══════════════════════════════════════════════════════════════
  // Filtering
  // ═══════════════════════════════════════════════════════════════

  List<Place> _filteredPlaces(PlacesController ctrl) {
    var list = ctrl.allPlacesRaw
        .where((p) => p.governorate == widget.governorateNameAr)
        .toList();

    if (_selectedCategory != null) {
      list = list.where((p) => p.categoryId == _selectedCategory).toList();
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.nameAr.toLowerCase().contains(q) ||
              p.nameEn.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final placesCtrl = context.watch<PlacesController>();
    final isLoading = placesCtrl.status == PlacesStatus.loading;

    return Scaffold(
      appBar: YaAppBar(
        title: 'اختيار الأماكن',
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_selectedStops),
            icon: const Icon(Icons.check),
            label: Text('تم (${_selectedStops.length})'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCounterBar(),
          _buildTabBar(),
          Expanded(
            child: isLoading && placesCtrl.allPlacesRaw.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCardsTab(placesCtrl),
                      _buildMapTab(),
                      _buildSelectedTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBar() {
    final theme = Theme.of(context);
    final pct = widget.maxStops > 0
        ? (_selectedStops.length / widget.maxStops).clamp(0.0, 1.0)
        : 0.0;
    final isOver = pct >= 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: isOver
          ? Colors.orange.withValues(alpha: 0.1)
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '${_selectedStops.length} من ${widget.maxStops}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isOver)
                Text(
                  'وصلت الحد',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                isOver ? Colors.orange : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        const Tab(icon: Icon(Icons.grid_view), text: 'بطاقات'),
        const Tab(icon: Icon(Icons.map_outlined), text: 'خريطة'),
        Tab(
          icon: Badge(
            label: Text('${_selectedStops.length}'),
            isLabelVisible: _selectedStops.isNotEmpty,
            child: const Icon(Icons.check_circle_outline),
          ),
          text: 'المختارة',
        ),
      ],
    );
  }

  Widget _buildCardsTab(PlacesController ctrl) {
    final places = _filteredPlaces(ctrl);

    return Column(
      children: [
        _buildSearchField(),
        _buildCategoryChips(),
        Expanded(
          child: places.isEmpty
              ? _buildEmptyPlaces()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: places.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: YaBaladiDesignTokens.space2),
                  itemBuilder: (_, i) => _PlaceCard(
                    place: places[i],
                    isSelected: _isSelected(places[i].id),
                    onAdd: () => _addPlace(places[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'ابحث عن مكان...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    const categories = <({String id, String label})>[
      (id: 'landmarks', label: 'معالم'),
      (id: 'restaurants', label: 'مطاعم'),
      (id: 'cafes', label: 'كافيهات'),
      (id: 'shopping', label: 'تسوق'),
      (id: 'hotels', label: 'فنادق'),
      (id: 'parks', label: 'حدائق'),
      (id: 'family', label: 'عائلي'),
      (id: 'events', label: 'فعاليات'),
      (id: 'beaches', label: 'شواطئ'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('الكل'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
            ),
          ),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c.label),
                selected: _selectedCategory == c.id,
                onSelected: (v) =>
                    setState(() => _selectedCategory = v ? c.id : null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaces() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد أماكن في ${widget.governorateNameAr}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'جرّب محافظة أخرى من الخطوة 1',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'الخريطة التفاعلية',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'قادمة في التحديث القادم',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTab() {
    if (_selectedStops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'لم تختر أماكن بعد',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'اذهب لتبويب "بطاقات" واضغط "أضف"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedStops.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: YaBaladiDesignTokens.space2),
      itemBuilder: (_, i) {
        final stop = _selectedStops[i];
        return _SelectedStopTile(
          index: i + 1,
          stop: stop,
          onRemove: () => _removeStop(stop),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.isSelected,
    required this.onAdd,
  });

  final Place place;
  final bool isSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.place,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star,
                          size: 12, color: Colors.amber.shade700),
                      const SizedBox(width: 2),
                      Text(
                        place.averageRating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        place.categoryId,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: isSelected ? null : onAdd,
              icon: Icon(
                isSelected ? Icons.check : Icons.add,
                size: 16,
              ),
              label: Text(isSelected ? 'مضاف' : 'أضف'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedStopTile extends StatelessWidget {
  const _SelectedStopTile({
    required this.index,
    required this.stop,
    required this.onRemove,
  });

  final int index;
  final TripStop stop;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          stop.placeNameAr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.star, size: 12, color: Colors.amber.shade700),
            const SizedBox(width: 2),
            Text(
              stop.rating.toStringAsFixed(1),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.schedule,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 2),
            Text(
              '${stop.plannedDurationMin ?? 0} د',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'حذف',
          onPressed: onRemove,
        ),
      ),
    );
  }
}