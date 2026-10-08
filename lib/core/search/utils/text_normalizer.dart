// lib/core/search/utils/text_normalizer.dart

/// تطبيع النص العربي والإنجليزي للبحث الموحد.
///
/// المهام:
/// - إزالة التشكيل (fatha, damma, kasra, shadda, sukun)
/// - توحيد الألف (أ إ آ ٱ → ا)
/// - توحيد التاء المربوطة (ة → ه)
/// - توحيد الياء (ى → ي)
/// - توحيد الهمزات (ؤ → و، ئ → ي)
/// - تصغير الأحرف الإنجليزية
/// - إزالة المسافات الزائدة
class TextNormalizer {
  TextNormalizer._();

  static final RegExp _diacritics = RegExp(
    r'[\u064B-\u0652\u0670\u0640]',
  );

  static final RegExp _whitespace = RegExp(r'\s+');

  /// يطبّع النص للبحث.
  ///
  /// مثال:
  ///   'مطعم البَيْك' → 'مطعم البيك'
  ///   'أحمد'         → 'احمد'
  ///   'قهوة'         → 'قهوه'
  static String normalize(String input) {
    if (input.isEmpty) return '';
    var text = input.trim();
    text = text.replaceAll(_diacritics, '');
    text = text.replaceAll(RegExp('[أإآٱ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll('ؤ', 'و');
    text = text.replaceAll('ئ', 'ي');
    text = text.toLowerCase();
    text = text.replaceAll(_whitespace, ' ');
    return text.trim();
  }

  /// يقطّع النص إلى كلمات مطبّعة.
  ///
  /// مثال: 'مطعم البيك' → ['مطعم', 'البيك']
  static List<String> tokenize(String input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) return const [];
    return normalized
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
  }

  /// يفحص هل النص `text` يطابق `query`؟
  ///
  /// المنطق:
  /// 1. query فارغ → تطابق دائم.
  /// 2. مطابقة جزئية: query كامل موجود داخل text.
  /// 3. مطابقة كلمات: كل كلمة في query موجودة في text (بأي ترتيب).
  static bool matches(String text, String query) {
    if (query.isEmpty) return true;
    final normText = normalize(text);
    final normQuery = normalize(query);
    if (normQuery.isEmpty) return true;
    if (normText.contains(normQuery)) return true;

    final tokens = normQuery.split(' ').where((t) => t.isNotEmpty);
    if (tokens.length <= 1) return false;

    for (final token in tokens) {
      if (!normText.contains(token)) return false;
    }
    return true;
  }

  /// يفحص هل النص يحتوي على query في أحد الحقول المتعددة.
  ///
  /// مفيد للبحث في nameAr + nameEn + description + tags.
  static bool matchesAny(Iterable<String> texts, String query) {
    if (query.isEmpty) return true;
    return texts.any((text) => matches(text, query));
  }
}
