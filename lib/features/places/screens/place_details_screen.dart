// lib/features/places/screens/place_details_screen.dart
//
// [v2.4 — 2026-10-20] — Zero Internal Maps + Real External Actions
//   - FIX: Removed placeMapPath (fixed 404 error).
//   - FIX: Removed duplicate Directions button.
//   - NEW: Integrated LocationActions widget for the map.
//   - NEW: Enabled Phone & WhatsApp using url_launcher.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/favorites/controllers/favorites_controller.dart';
import '../../../features/reviews/controllers/reviews_controller.dart';
import '../../../features/reviews/widgets/add_review_sheet.dart';
import '../../../features/reviews/widgets/reviews_section.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';
import '../../../theme/design_tokens.dart';
import '../../../widgets/location_actions.dart'; // ✅ استدعاء الزر الأنيق
import '../../../widgets/login_required_dialog.dart';

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({super.key, required this.placeId});
  final String placeId;

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final _repo = PlacesRepository();
  late Future<Place?> _future;
  late final ReviewsController _reviewsCtrl;

  @override
  void initState() {
    super.initState();
    _future = _repo.getById(widget.placeId);
    _reviewsCtrl = ReviewsController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthController>().uid;
      if (uid != null) {
        context.read<FavoritesController>().load(uid, widget.placeId);
      }
      _reviewsCtrl.load(widget.placeId);
    });
  }

  @override
  void dispose() {
    _reviewsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ChangeNotifierProvider<ReviewsController>.value(
      value: _reviewsCtrl,
      child: Scaffold(
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

        // ─── Reviews ───
        const Divider(),
        const SizedBox(height: YaBaladiDesignTokens.space3),
        _ReviewsBlock(place: place),

        const SizedBox(height: YaBaladiDesignTokens.space6),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REVIEWS BLOCK
// ═══════════════════════════════════════════════════════════════

class _ReviewsBlock extends StatefulWidget {
  const _ReviewsBlock({required this.place});
  final Place place;

  @override
  State<_ReviewsBlock> createState() => _ReviewsBlockState();
}

class _ReviewsBlockState extends State<_ReviewsBlock> {
  Future<void> _handleAddReview() async {
    final auth = context.read<AuthController>();
    final ctrl = context.read<ReviewsController>();
    final messenger = ScaffoldMessenger.of(context);

    if (auth.uid == null) {
      await showLoginRequiredDialog(context, featureName: 'المراجعات');
      return;
    }

    if (!mounted) return;

    if (ctrl.hasReviewed(auth.uid!)) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('لديك مراجعة على هذا المكان بالفعل'),
            duration: Duration(seconds: 3),
          ),
        );
      return;
    }

    final submitted = await AddReviewSheet.show(
      context,
      controller: ctrl,
      placeId: widget.place.id,
      userId: auth.uid!,
      userName: auth.displayName ?? 'مستخدم',
      userPhotoUrl: auth.photoUrl ?? '',
    );

    if (!mounted) return;

    if (submitted == true) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('شكراً على مشاركة تجربتك!'),
            duration: Duration(seconds: 3),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return ReviewsSection(
      currentUserId: auth.uid,
      onAddReview: _handleAddReview,
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
    final messenger = ScaffoldMessenger.of(context);
    final fav = context.read<FavoritesController>();

    if (uid == null) {
      await showLoginRequiredDialog(context, featureName: 'المفضلة');
      return;
    }

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
    } on Exception catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('تعذّر تحديث المفضلة: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTION BUTTONS (Clean & Functional)
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
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('اتصال'),
          ),
        if (place.whatsapp.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _launchWhatsApp(context, place.whatsapp),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('واتساب'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        // ✅ زر الخريطة الأنيق (الوحيد)
        if (place.location != null)
          LocationActions(
            lat: place.location!.latitude,
            lng: place.location!.longitude,
            large: true,
          ),
      ],
    );
  }

  Future<void> _launchCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الهاتف')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب')),
        );
      }
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
