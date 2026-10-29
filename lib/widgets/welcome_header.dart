// lib/widgets/welcome_header.dart
//
// [v3.0 — 2026-10-19] — Wave 5.5c: Location on Demand (ADR-6)
//   - NO auto-fetch in initState
//   - Reads cache via LocationCacheService
//   - Opens LocationSourceSheet on tap

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/location/browsing_location_controller.dart';
import '../core/location/location_source_sheet.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../services/location_cache_service.dart';
import '../services/location_service.dart';
import '../theme/design_tokens.dart';

class WelcomeHeader extends StatefulWidget {
  const WelcomeHeader({
    super.key,
    this.onSearchTap,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  @override
  State<WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<WelcomeHeader>
    with SingleTickerProviderStateMixin {
  _LocState _state = _LocState.idle;
  String? _gpsPlaceName;
  LocationData? _lastLocation;

  late final AnimationController _waveController;
  late final Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _waveAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: -0.25), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.25, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // ⭐ [v3.0] يقرأ cache فقط
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadCachedLocation());
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedLocation() async {
    if (!mounted) return;
    final browsingCtrl = context.read<BrowsingLocationController>();

    try {
      final cached = await LocationCacheService.load();
      if (!mounted) return;

      if (cached != null) {
        setState(() {
          _gpsPlaceName = cached.nameAr;
          _lastLocation = cached;
          _state = _LocState.loaded;
        });
        browsingCtrl.setPhysicalLocation(
          cached.latitude,
          cached.longitude,
          placeName: cached.nameAr,
        );
      } else {
        setState(() => _state = _LocState.idle);
      }
    } on Exception catch (e) {
      debugPrint('loadCachedLocation failed: $e');
      if (!mounted) return;
      setState(() => _state = _LocState.idle);
    }
  }

  Future<void> _openLocationSourceSheet(
    BrowsingLocationController ctrl,
  ) async {
    final loc = await LocationSourceSheet.show(
      context,
      controller: ctrl,
      currentLocation: _lastLocation,
    );

    if (!mounted) return;

    if (loc != null) {
      await LocationCacheService.save(loc);
      if (!mounted) return;
      setState(() {
        _gpsPlaceName = loc.nameAr;
        _lastLocation = loc;
        _state = _LocState.loaded;
      });
      unawaited(_waveController.forward());
    }
  }

  String get _buttonLabel {
    switch (_state) {
      case _LocState.idle:
        return 'اختر موقعك';
      case _LocState.loading:
        return 'جارٍ التحديد…';
      case _LocState.loaded:
        return context.read<BrowsingLocationController>().browsingShortLabel;
    }
  }

  String _greeting(String? name, bool isGuest) {
    if (isGuest || name == null || name.trim().isEmpty) {
      return 'أهلاً بك';
    }
    return 'أهلاً يا $name';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final browsingCtrl = context.watch<BrowsingLocationController>();
    final isGuest = auth.isGuest;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SmartAvatar(
                photoUrl: auth.photoUrl,
                displayName: auth.displayName,
                isGuest: isGuest,
                onTap: widget.onAvatarTap,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _greeting(auth.displayName, isGuest),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedBuilder(
                          animation: _waveAnim,
                          builder: (_, child) => Transform.rotate(
                            angle: _waveAnim.value,
                            child: child,
                          ),
                          child: const Text(
                            '👋',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _GovernorateButton(
                      label: _buttonLabel,
                      isLoading: _state == _LocState.loading,
                      isIdle: _state == _LocState.idle,
                      onTap: () => _openLocationSourceSheet(browsingCtrl),
                    ),
                    if (browsingCtrl.isBrowsingOtherGovernorate) ...[
                      const SizedBox(height: 4),
                      _PhysicalBadge(
                        physicalName: _gpsPlaceName ??
                            browsingCtrl.physical?.nameAr ??
                            '',
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onNotificationsTap,
                icon: const Icon(Icons.notifications_outlined, size: 22),
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: 'الإشعارات',
              ),
            ],
          ),
          const SizedBox(height: YaBaladiDesignTokens.space3),
          GestureDetector(
            onTap: widget.onSearchTap,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ابحث عن مكان، مطعم، كافيه...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LocState { idle, loaded, loading }

// ═══════════════════════════════════════════════════════════════
// GOVERNORATE BUTTON
// ═══════════════════════════════════════════════════════════════

class _GovernorateButton extends StatelessWidget {
  const _GovernorateButton({
    required this.label,
    required this.isLoading,
    required this.isIdle,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final bool isIdle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color =
        isIdle ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary;
    final IconData icon = isLoading
        ? Icons.location_searching
        : (isIdle ? Icons.add_location_alt_outlined : Icons.location_on);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

class _PhysicalBadge extends StatelessWidget {
  const _PhysicalBadge({required this.physicalName});

  final String physicalName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (physicalName.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.my_location,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'أنت في: $physicalName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmartAvatar extends StatelessWidget {
  const _SmartAvatar({
    required this.photoUrl,
    required this.displayName,
    required this.isGuest,
    this.onTap,
  });

  final String? photoUrl;
  final String? displayName;
  final bool isGuest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 40.0;

    final hasPhoto =
        !isGuest && photoUrl != null && photoUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: hasPhoto
            ? ClipOval(
                child: Image.network(
                  photoUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _fallbackAvatar(theme, isGuest, displayName),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return _fallbackAvatar(theme, isGuest, displayName);
                  },
                ),
              )
            : _fallbackAvatar(theme, isGuest, displayName),
      ),
    );
  }

  Widget _fallbackAvatar(
    ThemeData theme,
    bool isGuest,
    String? displayName,
  ) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isGuest
          ? Icon(
              Icons.person_outline,
              size: 22,
              color: theme.colorScheme.onPrimaryContainer,
            )
          : Text(
              _initials(displayName),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '؟';
    // ignore: deprecated_member_use
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
