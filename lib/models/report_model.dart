class ReportMetric {
  final String key;
  final String titleAr;
  final String titleEn;
  final int value;

  const ReportMetric({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.value,
  });

  String title(bool arabic) => arabic ? titleAr : titleEn;
}
