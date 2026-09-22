// شاشة "حسابي" هي مركز النشاط الشخصي، وليست مكانًا لتسجيل الخروج.
// الخروج موجود في الإعدادات فقط كما تم الاتفاق.
// صورة Google/Firebase تستخدم أولًا، ثم صورة الحرف كبديل آمن إذا لم توجد صورة.
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import 'rewards_screen.dart';
import 'notifications_screen.dart';
import 'tasks_screen.dart';
import 'pending_ratings_screen.dart';
import 'my_ratings_screen.dart';
import 'my_visits_screen.dart';
import 'subscriptions_screen.dart';
import 'settings_tab_screen.dart';
import '../theme/app_colors.dart';

class AccountTabScreen extends StatelessWidget {
  const AccountTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    final firebaseUser = AuthService().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of('account', lang)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<AppUser?>(
        stream: AuthService().currentAppUserStream,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = (user?.fullName.trim().isNotEmpty ?? false)
              ? user!.fullName.trim()
              : (firebaseUser?.displayName ?? '');
          final photoUrl = firebaseUser?.photoURL;
          final firstLetter = name.isNotEmpty ? name.substring(0, 1) : '؟';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primary,
                  backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
                  child: photoUrl == null
                      ? Text(firstLetter, style: const TextStyle(color: Colors.white, fontSize: 30))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(name.isEmpty ? AppStrings.of('welcome', lang) : name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              if ((user?.email ?? firebaseUser?.email ?? '').isNotEmpty)
                Center(child: Text(user?.email ?? firebaseUser!.email!, style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 18),
              _AccountTile(icon: Icons.card_giftcard, title: AppStrings.of('rewards', lang), onTap: () => _push(context, const RewardsScreen())),
              _AccountTile(icon: Icons.notifications, title: AppStrings.of('notification_history', lang), onTap: () => _push(context, const NotificationsScreen())),
              _AccountTile(icon: Icons.event_note, title: AppStrings.of('tasks', lang), onTap: () => _push(context, const TasksScreen())),
              _AccountTile(icon: Icons.star, title: AppStrings.of('rating_history', lang), onTap: () => _push(context, const MyRatingsScreen())),
              _AccountTile(icon: Icons.rate_review_outlined, title: AppStrings.of('pending_ratings', lang), onTap: () => _push(context, const PendingRatingsScreen())),
              _AccountTile(icon: Icons.location_history, title: AppStrings.of('visit_history', lang), onTap: () => _push(context, const MyVisitsScreen())),
              _AccountTile(icon: Icons.card_membership, title: AppStrings.of('subscriptions', lang), onTap: () => _push(context, const SubscriptionsScreen())),
              const SizedBox(height: 8),
              _AccountTile(icon: Icons.settings_outlined, title: 'الإعدادات', onTap: () => _push(context, const SettingsTabScreen())),
            ],
          );
        },
      ),
    );
  }

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _AccountTile({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(title), trailing: const Icon(Icons.chevron_left), onTap: onTap));
}
