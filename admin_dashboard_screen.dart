// screens/admin/admin_dashboard_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// نقطة الدخول الرئيسية للأدمن - بتعرض إحصائيات سريعة (عدد الأماكن،
// التجار، المستخدمين) وأزرار تودّي لباقي شاشات الإدارة التفصيلية.
// الوصول لهذه الشاشة لا يتم من اختيار عام داخل التطبيق؛ AuthGate يفتحها فقط
// عند ثبوت Custom Claim للأدمن الأعلى أو ملف مشرف إداري مفعّل.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'admin_places_screen.dart';
import 'admin_merchants_screen.dart';
import 'admin_featured_requests_screen.dart';
import 'admin_rewards_screen.dart';
import 'admin_permissions_screen.dart';
import 'admin_governorate_visuals_screen.dart';
import 'admin_support_tickets_screen.dart';
import 'admin_content_library_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // ------------------------------------------------------------
  // الفكرة: بدل ما نجيب كل المستندات ونعدّهم يدويًا (مكلف وبطيء)،
  // بنستخدم count() aggregate query من Firestore - بيرجع الرقم
  // مباشرة من السيرفر من غير ما ينزّل البيانات نفسها كلها للموبايل
  // ------------------------------------------------------------
  Future<int> _getCount(String collection) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).count().get();
    return snapshot.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: AuthService().hasAdminClaim(),
        builder: (context, claimSnapshot) {
          if (claimSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService().getModeratorProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final isSuperAdmin = claimSnapshot.data == true;
              final profile = profileSnapshot.data;
              final permissions = List<String>.from(profile?['permissions'] ?? const []);
              bool can(String permission) => isSuperAdmin || permissions.contains('*') || permissions.contains(permission);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
          // ------------------------------------------------------------
          // الفكرة: صف بطاقات إحصائية - كل بطاقة بتجيب عددها بشكل مستقل
          // (FutureBuilder منفصل لكل رقم) عشان لو واحد بطيء متأخرش الباقي
          // ------------------------------------------------------------
          if (isSuperAdmin || can('places.read'))
            Row(
              children: [
                Expanded(child: _StatCard(title: 'الأماكن', collection: 'places', getCount: _getCount, icon: Icons.place)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'التجار', collection: 'merchants', getCount: _getCount, icon: Icons.store)),
              ],
            ),
          if (isSuperAdmin || can('users.read')) const SizedBox(height: 12),
          if (isSuperAdmin || can('users.read'))
            Row(
              children: [
                Expanded(child: _StatCard(title: 'المستخدمين', collection: 'users', getCount: _getCount, icon: Icons.people)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'التقييمات', collection: 'ratings', getCount: _getCount, icon: Icons.star)),
              ],
            ),
          const SizedBox(height: 32),

          // ------------------------------------------------------------
          // الفكرة: أزرار وصول سريع لكل شاشات الإدارة التفصيلية
          // ------------------------------------------------------------
          if (isSuperAdmin || can('places.write')) _AdminMenuButton(
            title: 'إدارة الأماكن',
            subtitle: 'إضافة، تعديل، حذف الأماكن في كل المحافظات',
            icon: Icons.place,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AdminPlacesScreen())),
          ),
          if (isSuperAdmin || can('merchants.write')) _AdminMenuButton(
            title: 'إدارة التجار',
            subtitle: 'مراجعة وتوثيق حسابات التجار',
            icon: Icons.store,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AdminMerchantsScreen())),
          ),
          if (isSuperAdmin || can('places.write')) _AdminMenuButton(
            title: 'طلبات التميّز',
            subtitle: 'مراجعة طلبات التجار لظهور أماكنهم كمميزة',
            icon: Icons.star_rate,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AdminFeaturedRequestsScreen())),
          ),
          if (isSuperAdmin) _AdminMenuButton(
            title: 'صور المحافظات والهوية المحلية',
            subtitle: 'إدارة صور الغلاف ومصادرها وحقوق استخدامها لكل محافظة',
            icon: Icons.photo_library_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminGovernorateVisualsScreen())),
          ),
          if (isSuperAdmin) _AdminMenuButton(
            title: 'مكتبة يا بلدي',
            subtitle: 'إدارة الصور والفيديوهات والحكايات والمعالم والأطعمة والتراث والفعاليات ورحلة اليوم',
            icon: Icons.collections_bookmark_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminContentLibraryScreen())),
          ),
          if (isSuperAdmin) _AdminMenuButton(
            title: 'الصلاحيات والمشرفون',
            subtitle: 'إنشاء أدوار إدارية وتحديد صلاحيات كل مشرف',
            icon: Icons.admin_panel_settings,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPermissionsScreen())),
          ),
          if (isSuperAdmin || can('support.read')) _AdminMenuButton(
            title: 'دعم المستخدمين',
            subtitle: 'متابعة الشكاوى والمقترحات وحالات تذاكر الدعم',
            icon: Icons.support_agent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSupportTicketsScreen())),
          ),
          if (isSuperAdmin || can('rewards.write')) _AdminMenuButton(
            title: 'إدارة المكافآت',
            subtitle: 'تعريف المكافآت وتكلفة النقاط وربطها بالكوبونات',
            icon: Icons.card_giftcard,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AdminRewardsScreen())),
          ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// الفكرة: widget صغير قابل لإعادة الاستخدام لعرض رقم إحصائي واحد
// بيتولى بنفسه انتظار النتيجة وعرض دائرة تحميل لحد ما توصل
// ------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String collection;
  final Future<int> Function(String) getCount;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.collection,
    required this.getCount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1A237E), size: 28),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: getCount(collection),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return Text(
                  '${snapshot.data}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// الفكرة: زرار قائمة موحّد الشكل لكل خيارات لوحة الأدمن
// عشان نتجنب تكرار نفس الكود البصري 3-4 مرات
// ------------------------------------------------------------
class _AdminMenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminMenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF1A237E)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
