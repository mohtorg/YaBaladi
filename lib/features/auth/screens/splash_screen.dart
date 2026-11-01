// lib/features/auth/screens/splash_screen.dart
//
// [v1.2 — 2026-10-28] — Remove icon (failed to load), keep elegant text-only splash

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ═══════════════════════════════════════════════════════
                  // 1. اسم التطبيق - كبير وأنيق
                  // ═══════════════════════════════════════════════════════
                  Text(
                    'يا بلدي',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      fontSize: 56,
                      letterSpacing: 4,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ═══════════════════════════════════════════════════════
                  // 2. خط زخرفي تحت الاسم
                  // ═══════════════════════════════════════════════════════
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════════════════
                  // 3. الشعار الفرعي
                  // ═══════════════════════════════════════════════════════
                  Text(
                    'اكتشف جمال بلدك',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 72),

                  // ═══════════════════════════════════════════════════════
                  // 4. مؤشر التحميل
                  // ═══════════════════════════════════════════════════════
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════
                  // 5. عبارة الانتظار الأنيقة
                  // ═══════════════════════════════════════════════════════
                  Text(
                    'نجهّز لك أجمل التجارب...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
