import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../services/location_service.dart';
import '../theme/design_tokens.dart';

/// Header ترحيبي نظيف للشاشة الرئيسية.
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
  LocationData? _location;
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

    _fetchLocation();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation({bool forceRefresh = false}) async {
    setState(() => _state = _LocState.loading);

    if (forceRefresh) {
      await LocationService.clearCache();
    }

    final loc = await LocationService.getCurrentLocation(
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;

    setState(() {
      _location = loc;
      _state = loc == null ? _LocState.denied : _LocState.loaded;
    });

    if (loc != null) _waveController.forward();
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
    final isGuest = auth.isGuest;

    final locationText = switch (_state) {
      _LocState.loading => 'جارٍ تحديد الموقع…',
      _LocState.denied => 'الموقع غير مفعّل',
      _LocState.loaded => _location?.governorateAr ?? '',
    };

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
                          child:
                              const Text('👋', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (_state == _LocState.denied)
                      TextButton.icon(
                        onPressed: () => _fetchLocation(forceRefresh: true),
                        icon: const Icon(Icons.location_off_outlined, size: 14),
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
                      Text(
                        '📍 $locationText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
// SMART AVATAR (بدون CircleAvatar — يتفادى assertion)
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
