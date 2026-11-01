// lib/features/trip/widgets/wizard_progress_bar.dart
//
// [v1.0 — 2026-10-18] — Wave 5.2: Wizard Progress Bar
//   - 6 steps with icons
//   - Current step pulses (AnimationController)
//   - Completed steps green + check
//   - Future steps gray
//   - Connectors between dots
//   - Optional labels (Arabic)
//   - Accessibility (semantics)
import 'package:flutter/material.dart';

class WizardProgressBar extends StatefulWidget {
  /// الـ steps (الحد الأقصى 6).
  final List<WizardStepConfig> steps;

  /// الـ index الحالي (0-based).
  final int currentIndex;

  /// هل نعرض التسميات؟
  final bool showLabels;

  const WizardProgressBar({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.showLabels = false,
  })  : assert(steps.length > 0, 'At least 1 step required'),
        assert(currentIndex >= 0 && currentIndex < steps.length);

  @override
  State<WizardProgressBar> createState() => _WizardProgressBarState();
}

class _WizardProgressBarState extends State<WizardProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'الخطوة ${widget.currentIndex + 1} من ${widget.steps.length}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Row(
              children: List.generate(widget.steps.length, (i) {
                final isDone = i < widget.currentIndex;
                final isCurrent = i == widget.currentIndex;

                return Expanded(
                  child: Row(
                    children: [
                      // ─── Step dot ───
                      _StepDot(
                        config: widget.steps[i],
                        isDone: isDone,
                        isCurrent: isCurrent,
                        pulseAnimation: isCurrent ? _pulseController : null,
                      ),
                      // ─── Connector ───
                      if (i < widget.steps.length - 1)
                        Expanded(
                          child: _Connector(
                            isActive: isDone,
                            theme: theme,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            // ─── Labels row (اختياري) ───
            if (widget.showLabels) ...[
              const SizedBox(height: 6),
              Row(
                children: List.generate(widget.steps.length, (i) {
                  return Expanded(
                    child: Text(
                      widget.steps[i].labelAr,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: i <= widget.currentIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: i == widget.currentIndex
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP CONFIG
// ═══════════════════════════════════════════════════════════════

class WizardStepConfig {
  final String labelAr;
  final IconData icon;

  const WizardStepConfig({
    required this.labelAr,
    required this.icon,
  });
}

// ═══════════════════════════════════════════════════════════════
// STEP DOT
// ═══════════════════════════════════════════════════════════════

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.config,
    required this.isDone,
    required this.isCurrent,
    this.pulseAnimation,
  });

  final WizardStepConfig config;
  final bool isDone;
  final bool isCurrent;
  final Animation<double>? pulseAnimation;

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bgColor;
    final Color fgColor;
    final IconData icon;

    if (isDone) {
      bgColor = Colors.green;
      fgColor = Colors.white;
      icon = Icons.check;
    } else if (isCurrent) {
      bgColor = theme.colorScheme.primary;
      fgColor = theme.colorScheme.onPrimary;
      icon = config.icon;
    } else {
      bgColor = theme.colorScheme.surfaceContainerHighest;
      fgColor = theme.colorScheme.onSurfaceVariant;
      icon = config.icon;
    }

    final dot = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: isDone ? 18 : 16,
        color: fgColor,
      ),
    );

    if (isCurrent && pulseAnimation != null) {
      return AnimatedBuilder(
        animation: pulseAnimation!,
        builder: (context, child) {
          final scale = 1.0 + (pulseAnimation!.value * 0.12);
          return Transform.scale(scale: scale, child: child);
        },
        child: dot,
      );
    }

    return dot;
  }
}

// ═══════════════════════════════════════════════════════════════
// CONNECTOR
// ═══════════════════════════════════════════════════════════════

class _Connector extends StatelessWidget {
  const _Connector({required this.isActive, required this.theme});

  final bool isActive;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
