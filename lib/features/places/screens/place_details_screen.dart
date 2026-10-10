import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/favorites/controllers/favorites_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';
import '../../../theme/design_tokens.dart';
import '../../../widgets/login_required_dialog.dart';

/// شاشة تفاصيل المكان.
class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({super.key, required this.placeId});

  final String placeId;

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final _repo = PlacesRepository();
  late Future<Place?> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getById(widget.placeId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().uid;
      if (uid != null) {
        context.read<FavoritesController>().load(uid, widget.placeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
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
      ),
      body: FutureBuilder<Place?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(message: snap.error.toString());
          }
          final place = snap.data;
          if (place == null) {
            return const _EmptyView();
          }
          return _PlaceBody(place: place);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BODY
// ═══════════════════════════════════════════════════════════════

class _PlaceBody extends StatelessWidget {
  const _PlaceBody({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? place.nameAr : place.nameEn;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderImage(imageUrls: place.imageUrls),
        const SizedBox(height: YaBaladiDesignTokens.space4),

        // ─── Name + Favorite ───
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _FavoriteButton(placeId: place.id),
          ],
        ),

        const SizedBox(height: 8),
        _RatingRow(
          rating: place.averageRating,
          count: place.reviewCount,
        ),

        const SizedBox(height: YaBaladiDesignTokens.space4),

        // ─── Description ───
        if (place.description.isNotEmpty) ...[
          Text(
            place.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: YaBaladiDesignTokens.space4),
        ],

        // ─── Address ───
        if (place.address.isNotEmpty || place.city.isNotEmpty)
          _InfoTile(
            icon: Icons.location_on_outlined,
            title: 'العنوان',
            value: [
              place.address,
              place.city,
              place.governorate,
            ].where((s) => s.isNotEmpty).join(', '),
          ),

        // ─── Contact ───
        if (place.phone.isNotEmpty)
          _InfoTile(
            icon: Icons.phone_outlined,
            title: 'الهاتف',
            value: place.phone,
          ),

        const SizedBox(height: YaBaladiDesignTokens.space4),

        // ─── Action Buttons ───
        _ActionButtons(place: place),

        const SizedBox(height: YaBaladiDesignTokens.space4),

        // ─── Reviews teaser ───
        const Divider(),
        const SizedBox(height: YaBaladiDesignTokens.space2),
        Center(
          child: Text(
            'المراجعات قادمة قريبًا',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: YaBaladiDesignTokens.space6),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER IMAGE
// ═══════════════════════════════════════════════════════════════

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrls.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: PageView.builder(
          itemCount: imageUrls.length,
          itemBuilder: (_, i) => Image.network(
            imageUrls[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RATING
// ═══════════════════════════════════════════════════════════════

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          return Icon(
            filled ? Icons.star : Icons.star_border,
            size: 20,
            color: Colors.amber.shade700,
          );
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INFO TILE
// ═══════════════════════════════════════════════════════════════

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FAVORITE BUTTON
// ═══════════════════════════════════════════════════════════════

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final isFav = favorites.isFavorite(placeId);
    final isBusy = favorites.isBusy(placeId);

    return IconButton(
      onPressed: isBusy ? null : () => _toggle(context),
      icon: isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : null,
            ),
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final auth = context.read<AuthController>();
    final uid = auth.uid;

    if (uid == null) {
      await showLoginRequiredDialog(context, featureName: 'المفضلة');
      return;
    }

    // ✅ نلتقط messenger قبل await
    final messenger = ScaffoldMessenger.of(context);
    final fav = context.read<FavoritesController>();

    try {
      final newState = await fav.toggle(uid, placeId);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              newState ? 'أُضيف إلى المفضلة' : 'أُزيل من المفضلة',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تعذّر تحديث المفضلة')),
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTION BUTTONS (Call + WhatsApp + Map + Directions)
// ═══════════════════════════════════════════════════════════════

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (place.phone.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _launchCall(context, place.phone),
            icon: const Icon(Icons.phone),
            label: const Text('اتصال'),
          ),
        if (place.whatsapp.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _launchWhatsApp(context, place.whatsapp),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('واتساب'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        if (place.location != null) ...[
          FilledButton.icon(
            onPressed: () => context.go(RoutePaths.placeMapPath(place.id)),
            icon: const Icon(Icons.map_outlined),
            label: const Text('عرض على الخريطة'),
          ),
          OutlinedButton.icon(
            onPressed: () => _openInMaps(context, place),
            icon: const Icon(Icons.directions_outlined),
            label: const Text('الاتجاهات'),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CALL
  // ═══════════════════════════════════════════════════════════════
  Future<void> _launchCall(BuildContext context, String phone) async {
    // ✅ نلتقط messenger قبل أي await
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(scheme: 'tel', path: phone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError(messenger, 'تعذّر فتح تطبيق الاتصال');
      }
    } catch (e) {
      _showError(messenger, 'تعذّر الاتصال');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WHATSAPP
  // ═══════════════════════════════════════════════════════════════
  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    // ✅ نلتقط messenger قبل أي await
    final messenger = ScaffoldMessenger.of(context);
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError(messenger, 'تعذّر فتح واتساب');
      }
    } catch (e) {
      _showError(messenger, 'تعذّر فتح واتساب');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DIRECTIONS (Multi-platform: Android / iOS / Web)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _openInMaps(BuildContext context, Place place) async {
    // ✅ نلتقط messenger قبل أي await
    final messenger = ScaffoldMessenger.of(context);

    final lat = place.location!.latitude;
    final lng = place.location!.longitude;
    final name = Uri.encodeComponent(place.nameAr);

    final Uri uri;
    final LaunchMode mode;

    if (kIsWeb) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      mode = LaunchMode.platformDefault;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
          mode = LaunchMode.externalApplication;
          break;
        case TargetPlatform.iOS:
          uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&q=$name');
          mode = LaunchMode.externalApplication;
          break;
        default:
          uri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          );
          mode = LaunchMode.platformDefault;
      }
    }

    try {
      if (!await canLaunchUrl(uri)) {
        final fallback = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        );
        if (await canLaunchUrl(fallback)) {
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
          return;
        }
        _showError(messenger, 'تعذّر فتح تطبيق الخرائط');
        return;
      }

      await launchUrl(uri, mode: mode);
    } catch (e) {
      _showError(messenger, 'تعذّر فتح الخرائط');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR HELPER (يستقبل ScaffoldMessengerState مباشرة)
  // ═══════════════════════════════════════════════════════════════
  void _showError(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY / ERROR
// ═══════════════════════════════════════════════════════════════

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('هذا المكان غير موجود'));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

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
          ],
        ),
      ),
    );
  }
}
