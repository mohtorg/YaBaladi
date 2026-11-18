// lib/features/legal/screens/legal_page_screen.dart
// [v1.0 — 2026-11-03] — NEW: Legal pages (Privacy & Terms) with real Arabic content.

import 'package:flutter/material.dart';

enum LegalType { privacy, terms }

class LegalPageScreen extends StatelessWidget {
  final LegalType type;
  const LegalPageScreen({super.key, required this.type});

  String get _title =>
      type == LegalType.privacy ? 'سياسة الخصوصية' : 'شروط الاستخدام';

  String get _content {
    if (type == LegalType.privacy) {
      return '''
آخر تحديث: نوفمبر 2026

نحن في "يا بلدي" نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح هذه السياسة أنواع البيانات التي نجمعها وكيفية استخدامها.

**1. البيانات التي نجمعها:**
• معلومات الحساب (الاسم، البريد الإلكتروني، الصورة الشخصية).
• بيانات الموقع الجغرافي (للعثور على الأماكن القريبة منك فقط).
• تفاعلاتك (التقييمات، المفضلة، الرحلات).

**2. كيف نستخدم بياناتك:**
• تحسين تجربتك في التطبيق.
• عرض الأماكن والعروض القريبة منك.
• إرسال الإشعارات المهمة (يمكنك تعطيلها من الإعدادات).

**3. مشاركة البيانات:**
نحن لا نبيع بياناتك لأي طرف ثالث. قد نشارك بيانات مجهولة الهوية (إحصاءات) مع شركائنا لتحسين الخدمة.

**4. أمان البيانات:**
نستخدم تشفير SSL وتقنيات Firebase الآمنة لحماية بياناتك.

**5. حقوقك:**
• حذف حسابك في أي وقت.
• تصدير بياناتك.
• الاعتراض على معالجة بياناتك.

**6. التواصل:**
لأي استفسار: mohtorg1971@gmail.com
''';
    }
    return '''
مرحباً بك في "يا بلدي". باستخدامك للتطبيق، فإنك توافق على الشروط التالية:

**1. استخدام التطبيق:**
• يجب أن تكون بعمر 13 عاماً على الأقل.
• لا يجوز استخدام التطبيق لأي نشاط غير قانوني.
• لا يجوز انتحال شخصية الآخرين أو نشر محتوى مسيء.

**2. المحتوى الذي ينشره المستخدم:**
• التقييمات والتعليقات يجب أن تكون صادقة ومحترمة.
• نحتفظ بالحق في حذف أي محتوى مخالف.
• أنت مسؤول عن دقة المعلومات التي تنشرها.

**3. حسابات التجار:**
• يجب تقديم معلومات صحيحة ودقيقة.
• العروض المقدمة يجب أن تكون حقيقية وملزمة.
• التلاعب بالأسعار أو العروض يعرض حسابك للإيقاف.

**4. الملكية الفكرية:**
جميع حقوق التطبيق وتصميمه وشعاره محفوظة لـ "يا بلدي".

**5. إخلاء المسؤولية:**
التطبيق وسيط لعرض الأماكن، ولا نتحمل مسؤولية أي تعامل مباشر بينك وبين التجار.

**6. التعديلات:**
نحتفظ بالحق في تعديل هذه الشروط. استمرارك في الاستخدام يعني الموافقة على التعديلات.

**7. إنهاء الخدمة:**
يحق لنا إيقاف حسابك في حالة مخالفة الشروط.

للاستفسار: mohtorg1971@gmail.com
''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    type == LegalType.privacy
                        ? Icons.shield_outlined
                        : Icons.gavel,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      type == LegalType.privacy
                          ? 'خصوصيتك أولويتنا. هذه السياسة توضح التزامنا بحماية بياناتك.'
                          : 'باستخدامك التطبيق، أنت توافق على هذه الشروط. يرجى قراءتها بعناية.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}
