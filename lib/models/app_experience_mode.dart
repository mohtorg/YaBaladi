// models/app_experience_mode.dart
//
// الغرض: فصل "طريقة استخدام التطبيق" عن "دور الحساب".
// resident/visitor كلاهما حساب مستخدم عادي، لكن لكل وضع تجربة مختلفة.
// merchant يظل role مستقلًا ولا يستخدم هذا الـ mode لفتح لوحة مقدم الخدمة.
// لا تغيّر قيم التخزين (resident / visitor) عشوائيًا؛ لأنها جزء من بيانات المستخدم.

enum AppExperienceMode {
  resident,
  visitor,
}

extension AppExperienceModeX on AppExperienceMode {
  String get value {
    switch (this) {
      case AppExperienceMode.resident:
        return 'resident';
      case AppExperienceMode.visitor:
        return 'visitor';
    }
  }

  String labelAr() {
    switch (this) {
      case AppExperienceMode.resident:
        return 'مقيم';
      case AppExperienceMode.visitor:
        return 'زائر';
    }
  }

  String labelEn() {
    switch (this) {
      case AppExperienceMode.resident:
        return 'Resident';
      case AppExperienceMode.visitor:
        return 'Visitor';
    }
  }

  static AppExperienceMode? fromValue(String? value) {
    switch (value) {
      case 'resident':
        return AppExperienceMode.resident;
      case 'visitor':
        return AppExperienceMode.visitor;
      default:
        return null;
    }
  }
}
