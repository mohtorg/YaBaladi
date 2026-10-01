enum YaBaladiFilterLayer { basic, more, sorting }

class YaBaladiFilterDefinition {
  final String id;
  final String group;
  final String labelAr;
  final YaBaladiFilterLayer layer;
  final bool documentedOnly;

  const YaBaladiFilterDefinition({
    required this.id,
    required this.group,
    required this.labelAr,
    required this.layer,
    required this.documentedOnly,
  });
}

class FilterRegistry {
  static const filters = <YaBaladiFilterDefinition>[
    YaBaladiFilterDefinition(id: 'FIL-001', group: 'الموقع والمسافة', labelAr: 'قريب مني', layer: YaBaladiFilterLayer.basic, documentedOnly: true),
    YaBaladiFilterDefinition(id: 'FIL-002', group: 'الموقع والمسافة', labelAr: 'نطاق المسافة', layer: YaBaladiFilterLayer.more, documentedOnly: true),
    YaBaladiFilterDefinition(id: 'FIL-003', group: 'الموقع', labelAr: 'الحي / المدينة / المحافظة', layer: YaBaladiFilterLayer.basic, documentedOnly: true),
    YaBaladiFilterDefinition(id: 'FIL-004', group: 'الفئة', labelAr: 'نوع المكان', layer: YaBaladiFilterLayer.basic, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-005', group: 'الحالة', labelAr: 'مفتوح الآن', layer: YaBaladiFilterLayer.basic, documentedOnly: true),
    YaBaladiFilterDefinition(id: 'FIL-006', group: 'السعر', labelAr: 'نطاق السعر', layer: YaBaladiFilterLayer.basic, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-007', group: 'التقييم', labelAr: 'التقييم', layer: YaBaladiFilterLayer.basic, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-008', group: 'الجمهور', labelAr: 'الجمهور المستهدف', layer: YaBaladiFilterLayer.basic, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-009', group: 'المواقف', labelAr: 'المواقف', layer: YaBaladiFilterLayer.more, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-010', group: 'دورات المياه', labelAr: 'دورات المياه', layer: YaBaladiFilterLayer.more, documentedOnly: true),
    YaBaladiFilterDefinition(id: 'FIL-011', group: 'Wi-Fi', labelAr: 'Wi-Fi', layer: YaBaladiFilterLayer.more, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-012', group: 'الدفع', labelAr: 'طرق الدفع', layer: YaBaladiFilterLayer.more, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-013', group: 'الخدمات الإسلامية', labelAr: 'ملائم للمسلمين / حلال', layer: YaBaladiFilterLayer.more, documentedOnly: true),
    YaBaladiFilterDefinition(id: 'FIL-014', group: 'العائلات والأطفال', labelAr: 'العائلات والأطفال', layer: YaBaladiFilterLayer.more, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-015', group: 'النساء والرجال', labelAr: 'النساء / الرجال', layer: YaBaladiFilterLayer.more, documentedOnly: true),
    YaBaladiFilterDefinition(id: 'FIL-016', group: 'إمكانية الوصول', labelAr: 'إمكانية الوصول', layer: YaBaladiFilterLayer.more, documentedOnly: true),
    YaBaladiFilterDefinition(id: 'FIL-017', group: 'الحجز', labelAr: 'الحجز', layer: YaBaladiFilterLayer.more, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-018', group: 'التوصيل والاستلام', labelAr: 'التوصيل / الاستلام', layer: YaBaladiFilterLayer.more, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-019', group: 'العروض', labelAr: 'العروض', layer: YaBaladiFilterLayer.basic, documentedOnly: false),
    YaBaladiFilterDefinition(id: 'FIL-020', group: 'الترتيب', labelAr: 'الأقرب / الأعلى تقييمًا / الأكثر شعبية', layer: YaBaladiFilterLayer.sorting, documentedOnly: true),
  ];

  static List<YaBaladiFilterDefinition> get basic =>
      filters.where((f) => f.layer == YaBaladiFilterLayer.basic).toList(growable: false);

  static List<YaBaladiFilterDefinition> get more =>
      filters.where((f) => f.layer == YaBaladiFilterLayer.more).toList(growable: false);

  static List<YaBaladiFilterDefinition> get sorting =>
      filters.where((f) => f.layer == YaBaladiFilterLayer.sorting).toList(growable: false);
}