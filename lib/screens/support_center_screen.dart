// screens/support_center_screen.dart
// ============================================================
// الفكرة:
// مركز الدعم يظهر للمستخدم الآن بصورة مكتملة بصريًا، لكن الخدمات التي
// تحتاج فريق دعم بشري (مثل المحادثة المباشرة) تحمل حالة «قريبًا» بدل
// فتح قناة غير جاهزة. أما الشكاوى والمقترحات فتظل متاحة من نفس المركز.
// لا نطلب أي صلاحيات جديدة ولا نضيف بيانات حساسة إلى تذكرة الدعم.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    final ar = lang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of('support_center', lang)),
        backgroundColor: const Color(0xFF1454A3),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1454A3), Color(0xFF1E73BE)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 42),
                const SizedBox(height: 14),
                Text(
                  AppStrings.of('support_coming_soon_title', lang),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.of('support_coming_soon_body', lang),
                  style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 15),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    AppStrings.of('support_badge_soon', lang),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SupportActionCard(
            icon: Icons.feedback_outlined,
            title: AppStrings.of('complaints', lang),
            subtitle: AppStrings.of('support_ticket_subtitle', lang),
            enabled: true,
            onTap: () => _showTicketForm(context, lang),
          ),
          _SupportActionCard(
            icon: Icons.chat_bubble_outline,
            title: AppStrings.of('support_live_chat', lang),
            subtitle: AppStrings.of('support_live_chat_soon', lang),
            enabled: false,
            onTap: null,
          ),
          _SupportActionCard(
            icon: Icons.menu_book_outlined,
            title: AppStrings.of('support_faq', lang),
            subtitle: AppStrings.of('support_faq_subtitle', lang),
            enabled: true,
            onTap: () => _showFaq(context, lang),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.of('support_faq_title', lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _FaqTile(question: ar ? 'كيف أستخدم الأماكن القريبة؟' : 'How do I use Nearby Places?', answer: ar ? 'افتح ميزة الأماكن القريبة واسمح بالموقع التقريبي عند الطلب. لا يحتاج التطبيق إلى تتبع موقعك في الخلفية.' : 'Open Nearby Places and allow approximate location when requested. The app does not need background location tracking.'),
          _FaqTile(question: ar ? 'هل أحتاج إلى السماح بالكاميرا؟' : 'Do I need to allow camera access?', answer: ar ? 'الكاميرا مطلوبة للتاجر عند استخدام مسح QR فقط.' : 'Camera access is needed for merchants only when QR scanning is used.'),
          _FaqTile(question: ar ? 'كيف أرسل مشكلة؟' : 'How do I report a problem?', answer: ar ? 'من الإعدادات اختر «الشكاوى والمقترحات». سيتم إنشاء تذكرة دعم يمكن لفريق الإدارة متابعتها.' : 'From Settings choose Complaints & Suggestions. A support ticket is created for the team to follow up.'),
        ],
      ),
    );
  }

  Future<void> _showTicketForm(BuildContext context, String lang) async {
    final subject = TextEditingController();
    final details = TextEditingController();
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final sent = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(AppStrings.of('complaints', lang)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: subject, decoration: InputDecoration(labelText: AppStrings.of('subject', lang))),
        const SizedBox(height: 10),
        TextField(controller: details, maxLines: 5, decoration: InputDecoration(labelText: AppStrings.of('details', lang))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.of('cancel', lang))),
        FilledButton(onPressed: () => Navigator.pop(ctx, subject.text.trim().isNotEmpty && details.text.trim().isNotEmpty), child: Text(AppStrings.of('send', lang))),
      ],
    ));
    if (sent == true) {
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': uid,
        'subject': subject.text.trim(),
        'details': details.text.trim(),
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.of('support_sent_message', lang))));
      }
    }
    subject.dispose();
    details.dispose();
  }

  void _showFaq(BuildContext context, String lang) {
    final ar = lang == 'ar';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.of('support_faq_title', lang), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _FaqTile(question: ar ? 'كيف أرسل مشكلة؟' : 'How do I report a problem?', answer: ar ? 'من الإعدادات اختر «الشكاوى والمقترحات».' : 'From Settings choose Complaints & Suggestions.'),
            _FaqTile(question: ar ? 'متى يتوفر الدعم المباشر؟' : 'When will live support be available?', answer: AppStrings.of('support_live_chat_soon', lang)),
          ],
        ),
      ),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _SupportActionCard({required this.icon, required this.title, required this.subtitle, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1454A3).withValues(alpha: .10),
          child: Icon(icon, color: const Color(0xFF1454A3)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (!enabled) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
              child: Text(AppStrings.of('support_coming_soon_short', LocaleController.of(context).locale.languageCode), style: TextStyle(color: Colors.orange[800], fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: Icon(enabled ? Icons.chevron_left : Icons.lock_outline, color: enabled ? null : Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [Text(answer, style: const TextStyle(height: 1.5))],
        ),
      );
}
