import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String errorCode;
  final String errorMessage;
  final String? stackTrace;
  final String appVersion;
  final String platform;
  final String status; // 'open' | 'in_progress' | 'resolved'
  final DateTime? createdAt;
  final String? adminNote;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.errorCode,
    required this.errorMessage,
    this.stackTrace,
    required this.appVersion,
    required this.platform,
    required this.status,
    this.createdAt,
    this.adminNote,
  });

  /// ✅ Factory آمن: يتعامل مع البيانات الناقصة أو التالفة بدون رمي استثناءات
  factory SupportTicket.fromDoc(DocumentSnapshot doc) {
    // حماية: إذا كان المستند بلا بيانات، نستخدم خريطة فارغة
    final d = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    return SupportTicket(
      id: doc.id,
      userId: (d['userId'] ?? 'anonymous').toString(),
      userName: (d['userName'] ?? 'مستخدم مجهول').toString(),
      userEmail: (d['userEmail'] ?? '').toString(),
      errorCode: (d['errorCode'] ?? 'UNKNOWN').toString(),
      errorMessage: (d['errorMessage'] ?? '').toString(),
      stackTrace: d['stackTrace'] as String?,
      appVersion: (d['appVersion'] ?? '1.0.0').toString(),
      platform: (d['platform'] ?? 'unknown').toString(),
      // ✅ تحويل آمن للحالة لضمان عدم حدوث خطأ إذا كانت القيمة غير نصية
      status: (d['status'] ?? 'open').toString(),
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
      adminNote: d['adminNote'] as String?,
    );
  }

  // ─── Convenience Getters (تسهل كتابة الشاشات) ───
  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'جديد';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      default:
        return status;
    }
  }

  /// ✅ copyWith لسهولة تحديث الكائن محلياً (إن احتجته لاحقاً)
  SupportTicket copyWith({
    String? status,
    String? adminNote,
  }) {
    return SupportTicket(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      errorCode: errorCode,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      appVersion: appVersion,
      platform: platform,
      status: status ?? this.status,
      createdAt: createdAt,
      adminNote: adminNote ?? this.adminNote,
    );
  }

  /// ✅ toMap للاختبارات أو إعادة الإرسال
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'appVersion': appVersion,
        'platform': platform,
        'status': status,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'adminNote': adminNote,
      };
}
