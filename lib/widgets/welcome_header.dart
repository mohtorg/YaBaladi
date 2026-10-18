// lib/widgets/welcome_header.dart
//
// [v2.0.4 — 2026-10-17] — Lint fixes + async safety
//   - FIX: unawaited(_fetchLocation()) في initState (unawaited_futures)
//   - FIX: unawaited() في Retry button (نفس التحذير)
//   - FIX: التقاط BrowsingLocationController قبل await
//          (يمنع use_build_context_synchronously)
//   - ADD: import 'dart:async' لـ unawaited()
//   - NOTE: RegExp deprecation متفق على تجاهله (SDK warning)
//
// [v2.0.3 — 2026-10-14] — Nominatim integration
//   - CHANGE: _GovernorateButton يستقبل `label` بدل `browsing`
//   - CHANGE: يعرض "بورسعيد - الشرق" عبر browsingShortLabel
//   - FIX: إزالة `_location` (غير مستخدم)
//   - CLEANUP: إزالة import egypt_governorates
//
// [v2.0.1 — 2026-10-14] — Type-safety fix
// [v2.0 — 2026-10-14] — G4.2-c-3: Governorate Switcher
// [v1.1 — 2026-10-13] — PostFrame deferral

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/location/browsing_location_controller.dart';
import '../core/location/governorate_picker_sheet.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../services/location_service.dart';
import '../theme/design_tokens.dart';

/// Header ترحيبي للشاشة الرئيسية.
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
  _LocState _state = _LocState.loading;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ✅ [v2.0.4] unawaited — fire-and-forget مُعلَن صراحةً
      unawaited(_fetchLocation());
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  /// [v2.0.4] — نلتقط Controller **قبل** await لتجنب
  /// use_build_context_synchronously.
  Future<void> _fetchLocation({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (_state != _LocState.loading) {
      setState(() => _state = _LocState.loading);
    }

    // ✅ التقاط Controller مبكراً
    final browsingCtrl = context.read<BrowsingLocationController>();

    if (forceRefresh) {
      await LocationService.clearCache();
    }

    final loc = await LocationService.getCurrentLocation(
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;

    setState(() {
      _state = loc == null ? _LocState.denied : _LocState.loaded;
    });

    if (loc != null) {
      browsingCtrl.setPhysicalLocation(
        loc.latitude,
        loc.longitude,
      );
      _waveController.forward();
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
                    // ─── زر تبديل المحافظة ───
                    if (_state == _LocState.denied)
                      TextButton.icon(
                        // ✅ [v2.0.4] unawaited — صريح
                        onPressed: () => unawaited(
                          _fetchLocation(forceRefresh: true),
                        ),
                        icon: const Icon(
                          Icons.location_off_outlined,
                          size: 14,
                        ),
                        label: const Text(
                          'تفعيل الموقع',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 20),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    else
                      _GovernorateButton(
                        label: browsingCtrl.browsingShortLabel,
                        isLoading: _state == _LocState.loading,
                        onTap: () => GovernoratePickerSheet.show(
                          context,
                          controller: browsingCtrl,
                        ),
                      ),
                    // ─── شارة "أنت في" ───
                    if (browsingCtrl.isBrowsingOtherGovernorate) ...[
                      const SizedBox(height: 4),
                      _PhysicalBadge(
                        physicalName: browsingCtrl.physical?.nameAr ?? '',
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
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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

enum _LocState { loading, loaded, denied }

// ═══════════════════════════════════════════════════════════════
// GOVERNORATE BUTTON
// ═══════════════════════════════════════════════════════════════

class _GovernorateButton extends StatelessWidget {
  const _GovernorateButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  /// نص جاهز من `BrowsingLocationController.browsingShortLabel`
  /// مثال: "بورسعيد - الشرق" أو "الإسكندرية".
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                isLoading ? 'جارٍ التحديد…' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHYSICAL BADGE
// ═══════════════════════════════════════════════════════════════

class _PhysicalBadge extends StatelessWidget {
  const _PhysicalBadge({required this.physicalName});

  final String physicalName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.my_location,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          'أنت في: $physicalName',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMART AVATAR
// ═══════════════════════════════════════════════════════════════

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

  /// ⚠️ RegExp deprecation — متفق على تجاهله (SDK warning).
  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '؟';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
