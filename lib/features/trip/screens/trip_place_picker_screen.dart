// lib/features/trip/screens/trip_place_picker_screen.dart
//
// [v2.1 - DARK THEME CONSISTENCY + FIXES]
//   - ADDED: ThemeData.dark() wrapper matching the entire trip flow.
//   - FIXED: Banner and counter bar now use dark-friendly colors.
//   - FIXED: Cards converted to Glassmorphism (no more white snap).
//   - FIXED: Search field has controller (can be cleared).
//   - FIXED: Category ID mapped to Arabic label.
//   - FIXED: Arabic pluralization for durations in _SelectedStopTile.
//   - FIXED: TabBar colors explicit (blue on dark).
//   - KEPT: All selection, validation, undo, and navigation logic.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/place.dart';
import '../../../models/trip_plan.dart';
import '../../../theme/design_tokens.dart';
import '../../../widgets/ya_app_bar.dart';
import '../../../services/map_service.dart';
import '../../places/controllers/places_controller.dart';

// ─── Shared dark palette ───
const _primaryBlue = Color(0xFF0EA5E9);
const _bgColor = Color(0xFF0F172A);
const _cardBg = Color(0x14FFFFFF); // white 8%
const _cardBorder = Color(0x26FFFFFF); // white 15%
const _amberWarning = Color(0xFFF59E0B);

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
  final _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory;

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
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════

  bool _isSelected(String placeId) =>
      _selectedStops.any((s) => s.placeId == placeId);

  bool _hasValidCoords(Place p) {
    final lat = p.location?.latitude;
    final lng = p.location?.longitude;
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    return true;
  }

  String _arabicDuration(int minutes) {
    if (minutes == 1) return 'دقيقة';
    if (minutes == 2) return 'دقيقتان';
    if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
    return '$minutes دقيقة';
  }

  String _categoryLabel(String id) {
    switch (id) {
      case 'landmarks':
        return 'معلم';
      case 'restaurants':
        return 'مطعم';
      case 'cafes':
        return 'مقهى';
      case 'shopping':
        return 'تسوق';
      case 'hotels':
        return 'فندق';
      case 'parks':
        return 'حديقة';
      case 'family':
        return 'عائلي';
      case 'events':
        return 'فعالية';
      case 'beaches':
        return 'شاطئ';
      default:
        return 'مكان';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════

  void _addPlace(Place place) {
    if (_isSelected(place.id)) return;

    if (!_hasValidCoords(place)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '"${place.nameAr}" لا يحتوي على إحداثيات صالحة للخريطة',
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      return;
    }

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
      placeImageUrl: place.imageUrls.isNotEmpty ? place.imageUrls.first : null,
      lat: place.location!.latitude,
      lng: place.location!.longitude,
      categoryId: place.categoryId,
      rating: place.averageRating,
      reviewCount: place.reviewCount,
      plannedDurationMin: 60,
    );

    setState(() => _selectedStops.add(stop));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('أُضيف: ${place.nameAr}'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () {
              if (!mounted) return;
              setState(() => _selectedStops.remove(stop));
            },
          ),
        ),
      );
  }

  void _removeStop(TripStop stop) {
    final removed = stop;
    setState(() => _selectedStops.remove(stop));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('حُذف: ${removed.placeNameAr}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () {
              if (!mounted) return;
              setState(() => _selectedStops.add(removed));
            },
          ),
        ),
      );
  }

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

  int _invalidCoordsCount(PlacesController ctrl) {
    return ctrl.allPlacesRaw
        .where((p) => p.governorate == widget.governorateNameAr)
        .where((p) => !_hasValidCoords(p))
        .length;
  }

  // ═══════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Dark theme wrapper — matches trip planner / overview / day screens.
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bgColor,
        colorScheme: const ColorScheme.dark(
          primary: _primaryBlue,
          surface: Color(0xFF1E293B),
          onSurface: Colors.white,
          surfaceContainerHighest: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: _primaryBlue,
          unselectedLabelColor: Colors.white54,
          indicatorColor: _primaryBlue,
        ),
      ),
      child: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    final placesCtrl = context.watch<PlacesController>();
    final isLoading = placesCtrl.status == PlacesStatus.loading;

    return Scaffold(
      appBar: YaAppBar(
        title: 'اختيار الأماكن',
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_selectedStops),
            icon: const Icon(Icons.check, color: _primaryBlue),
            label: Text(
              'تم (${_selectedStops.length})',
              style: const TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCounterBar(),
            _buildInvalidBanner(placesCtrl),
            _buildTabBar(),
            Expanded(
              child: isLoading && placesCtrl.allPlacesRaw.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryBlue),
                    )
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
      ),
    );
  }

  Widget _buildCounterBar() {
    final pct = widget.maxStops > 0
        ? (_selectedStops.length / widget.maxStops).clamp(0.0, 1.0)
        : 0.0;
    final isOver = pct >= 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: isOver
          ? _amberWarning.withValues(alpha: 0.1)
          : _primaryBlue.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: _primaryBlue),
              const SizedBox(width: 6),
              Text(
                '${_selectedStops.length} من ${widget.maxStops}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isOver)
                const Text(
                  'وصلت الحد',
                  style: TextStyle(
                    color: _amberWarning,
                    fontSize: 11,
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
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                isOver ? _amberWarning : _primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidBanner(PlacesController ctrl) {
    if (ctrl.allPlacesRaw.isEmpty) return const SizedBox.shrink();
    final invalid = _invalidCoordsCount(ctrl);
    if (invalid == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _amberWarning.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: _amberWarning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$invalid مكان بدون إحداثيات صالحة — لن يظهر على الخريطة',
              style: const TextStyle(
                color: _amberWarning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
                    hasValidCoords: _hasValidCoords(places[i]),
                    categoryLabel: _categoryLabel(places[i].categoryId),
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
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'ابحث عن مكان...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: const Icon(Icons.search, color: _primaryBlue),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: Colors.white.withValues(alpha: 0.5)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
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
              selectedColor: _primaryBlue,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(
                color:
                    _selectedCategory == null ? Colors.white : Colors.white70,
                fontWeight: _selectedCategory == null ? FontWeight.bold : null,
              ),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: _selectedCategory == null
                    ? _primaryBlue
                    : Colors.white.withValues(alpha: 0.1),
              ),
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
                selectedColor: _primaryBlue,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                labelStyle: TextStyle(
                  color:
                      _selectedCategory == c.id ? Colors.white : Colors.white70,
                  fontWeight:
                      _selectedCategory == c.id ? FontWeight.bold : null,
                ),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: _selectedCategory == c.id
                      ? _primaryBlue
                      : Colors.white.withValues(alpha: 0.1),
                ),
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
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد أماكن في ${widget.governorateNameAr}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرّب محافظة أخرى من الخطوة 1',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    // NOTE: This is a summary view, not a real map. A proper map view
    // needs GoogleMap / flutter_map which are not integrated here.
    // The purpose of this tab is to offer directions to the first stop.
    if (_selectedStops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 72,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'أضف أماكن لعرض المسار عليها',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اذهب لتبويب "بطاقات" واضغط "أضف"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryBlue.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.map, size: 64, color: _primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'أنت اخترت ${_selectedStops.length} مكان',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (_selectedStops.isNotEmpty) {
                  MapService.openDirections(
                      _selectedStops.first.lat, _selectedStops.first.lng);
                }
              },
              icon: const Icon(Icons.navigation),
              label: const Text('ابدأ التوجيه إلى أول مكان'),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'لم تختر أماكن بعد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اذهب لتبويب "بطاقات" واضغط "أضف"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
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
          durationLabel: _arabicDuration(stop.plannedDurationMin ?? 0),
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
    required this.hasValidCoords,
    required this.categoryLabel,
    required this.onAdd,
  });

  final Place place;
  final bool isSelected;
  final bool hasValidCoords;
  final String categoryLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: hasValidCoords
                    ? _primaryBlue.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasValidCoords ? Icons.place : Icons.location_off,
                color: hasValidCoords ? _primaryBlue : Colors.redAccent,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        place.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!hasValidCoords)
                        const Text(
                          'بدون إحداثيات',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          categoryLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: (isSelected || !hasValidCoords) ? null : onAdd,
              icon: Icon(
                isSelected
                    ? Icons.check
                    : (!hasValidCoords ? Icons.block : Icons.add),
                size: 16,
              ),
              label: Text(
                isSelected ? 'مضاف' : (!hasValidCoords ? 'غير متاح' : 'أضف'),
              ),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    required this.durationLabel,
    required this.onRemove,
  });

  final int index;
  final TripStop stop;
  final String durationLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _primaryBlue,
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                stop.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.schedule, size: 12, color: _primaryBlue),
              const SizedBox(width: 2),
              Text(
                durationLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'حذف',
            onPressed: onRemove,
          ),
        ),
      ),
    );
  }
}
