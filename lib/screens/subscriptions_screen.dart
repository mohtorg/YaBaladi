// screens/subscriptions_screen.dart
// عرض باقات الاشتراك للمستخدم/مقدم الخدمة وبيان الاشتراك الحالي.
// لا تتم أي عملية دفع أو تفعيل من العميل؛ التفعيل الحقيقي يحتاج Backend موثوق.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});
  @override Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    final ar = lang == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of('subscriptions', lang)), backgroundColor: const Color(0xFF1454A3), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
        stream: FirebaseFirestore.instance.collection('subscription_plans').where('active', isEqualTo: true).snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text(ar ? 'تعذر تحميل الباقات' : 'Unable to load plans'));
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) return Center(child: Text(ar ? 'لا توجد باقات متاحة حاليًا' : 'No plans are currently available'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (_, i) {
            final d=docs[i].data(); final name=ar?(d['nameAr']??d['name_ar']??'باقة'):(d['nameEn']??d['name_en']??'Plan');
            final desc=ar?(d['descriptionAr']??d['description_ar']??''):(d['descriptionEn']??d['description_en']??'');
            return Card(child: ListTile(title: Text('$name'), subtitle: Text('$desc\n${d['price']??''} ${d['currency']??'EGP'}'), isThreeLine: true, trailing: const Icon(Icons.chevron_left)));
          });
        },
      ),
    );
  }
}
