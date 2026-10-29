// lib/features/trip/widgets/selection_card.dart
//
// [v1.0 — 2026-10-18] — Wave 5.2: Selection Card
//   - بطاقة كبيرة قابلة للنقر
//   - Icon/Emoji + Title + Tagline + Subtitle (اختياري)
//   - Animated selected state (scale + color + check)
//   - Haptic feedback
//   - Optional badge (recommended)
//
// يُستخدم في:
//   - Companions (5 بطاقات)
//   - Duration (3 بطاقات)
//   - Transport (3 بطاقات)
//   - Destination (27 محافظة — بـ grid 2 columns)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectionCard extends StatefulWidget {
  final String? emoji;
  final IconData? icon;

  final String title;
  final String? tagline;
  final String? subtitle;

  final bool isSelected;
  final VoidCallback onTap;

  /// لون مخصص (اختياري — يُستخدم في companions).
  final Color? accentColor;

  /// Badge (مثلاً "recommended").
  final String? badgeLabel;

  /// Compact mode (للـ grid 2 columns).
  final bool compact;

  const SelectionCard({
    super.key,
    this.emoji,
    this.icon,
    required this.title,
    this.tagline,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
    this.badgeLabel,
    this.compact = false,
  }) : assert(emoji != null || icon != null);

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _scaleController
      ..reverse()
      ..forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;
    final selected = widget.isSelected;

    final bgColor =
        selected ? accent.withValues(alpha: 0.12) : theme.colorScheme.surface;

    final borderColor = selected
        ? accent
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(widget.compact ? 12 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // ─── Content ───
                Column(
                  crossAxisAlignment: widget.compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji / Icon
                    if (widget.emoji != null)
                      Text(
                        widget.emoji!,
                        style: TextStyle(fontSize: widget.compact ? 32 : 40),
                      )
                    else
                      Icon(
                        widget.icon,
                        size: widget.compact ? 28 : 36,
                        color: selected
                            ? accent
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    SizedBox(height: widget.compact ? 8 : 12),

                    // Title
                    Text(
                      widget.title,
                      textAlign:
                          widget.compact ? TextAlign.center : TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (widget.compact
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.titleMedium)
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? accent : theme.colorScheme.onSurface,
                      ),
                    ),

                    // Tagline
                    if (widget.tagline != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.tagline!,
                        textAlign:
                            widget.compact ? TextAlign.center : TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],

                    // Subtitle
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle!,
                        textAlign:
                            widget.compact ? TextAlign.center : TextAlign.start,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: selected ? accent : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),

                // ─── Selected Check ───
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // ─── Badge (recommended) ───
                if (widget.badgeLabel != null && !selected)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.badgeLabel!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
