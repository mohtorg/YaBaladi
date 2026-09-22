import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  Future<int> _count(String collection, {String? field, dynamic value}) async {
    var query = FirebaseFirestore.instance.collection(collection);
    final result = field == null
        ? await query.count().get()
        : await query.where(field, isEqualTo: value).count().get();
    return result.count ?? 0;
  }

  Future<int> _myActivityCount() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return 0;
    final result = await FirebaseFirestore.instance
        .collection('audit_logs')
        .where('actorUid', isEqualTo: uid)
        .count()
        .get();
    return result.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات الفريق'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService().getModeratorProfile(),
        builder: (context, profile) {
          if (profile.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<bool>(
            future: AuthService().hasAdminClaim(),
            builder: (context, claim) {
              if (claim.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final isAdmin = claim.data == true;
              final permissions =
                  List<String>.from(profile.data?['permissions'] ?? const []);
              final can = (String p) =>
                  isAdmin || permissions.contains('*') || permissions.contains(p);
              if (!can('analytics.read')) {
                return const Center(child: Text('لا تملك صلاحية مشاهدة الإحصائيات.'));
              }

              return FutureBuilder<List<int>>(
                future: Future.wait([
                  _count('places'),
                  _count('events', field: 'isPublished', value: true),
                  _count('offers', field: 'active', value: true),
                  _count('rewards', field: 'active', value: true),
                  if (isAdmin || can('team.read')) TeamService().countMembers(),
                  if (isAdmin || can('audit.read')) _myActivityCount(),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final values = snapshot.data!;
                  final titles = <String>[
                    'الأماكن',
                    'الفعاليات',
                    'العروض',
                    'المكافآت',
                    if (isAdmin || can('team.read')) 'أعضاء الفريق',
                    if (isAdmin || can('audit.read')) 'نشاط حسابك',
                  ];
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: values.length,
                    itemBuilder: (_, index) => Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${values[index]}',
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(titles[index]),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
