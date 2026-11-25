// lib/core/services/audit_log_service.dart
// [v3.0 — ENTERPRISE AUDIT MANAGEMENT]
//   - ADDED: Soft Delete, Archive, Restore, Hard Delete methods.
//   - ADDED: logSystemEvent() to track meta-actions (deletes, wipes).
//   - ADDED: clearAllLogs() for safe batch soft-deletion.
//   - KEPT: Original logAction signature & backward compatibility.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuditLogService {
  // ─── 1. تسجيل الإجراءات العادية ───
  static Future<void> logAction({
    required String action,
    required String adminName,
    String target = 'عام',
    String? details,
    String severity = 'medium',
    String actorRole = 'admin',
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': action,
        'targetName': target,
        'performedBy': adminName,
        'actorId': uid,
        'actorRole': actorRole,
        'severity': severity,
        'details': details ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isArchived': false,
        'isDeleted': false,
      });
    } catch (e) {
      debugPrint('Audit log failed: $e');
    }
  }

  // ─── 2. تسجيل أحداث النظام (سجل السجلات) ───
  static Future<void> logSystemEvent({
    required String action,
    required String adminName,
    String? details,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('system_events').add({
        'action': action,
        'performedBy': adminName,
        'actorId': uid,
        'details': details ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('System event log failed: $e');
    }
  }

  // ─── 3. الأرشفة ───
  static Future<void> archiveLog(String logId) async {
    await FirebaseFirestore.instance
        .collection('audit_logs')
        .doc(logId)
        .update({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── 4. إلغاء الأرشفة (استعادة من الأرشيف) ───
  static Future<void> unarchiveLog(String logId) async {
    await FirebaseFirestore.instance
        .collection('audit_logs')
        .doc(logId)
        .update({
      'isArchived': false,
      'archivedAt': FieldValue.delete(),
    });
  }

  // ─── 5. الحذف الناعم (نقل إلى سلة المهملات) ───
  static Future<void> softDeleteLog(String logId) async {
    await FirebaseFirestore.instance
        .collection('audit_logs')
        .doc(logId)
        .update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── 6. استعادة من سلة المهملات ───
  static Future<void> restoreLog(String logId) async {
    await FirebaseFirestore.instance
        .collection('audit_logs')
        .doc(logId)
        .update({
      'isDeleted': false,
      'deletedAt': FieldValue.delete(),
    });
  }

  // ─── 7. «الحذف النهائي» ───
  // [v3.1 — 2026-11-19] سجل التدقيق إضافة فقط: القواعد تمنع delete من أي دور.
  // تبقى الدالة للتوافق وتُبقي السجل في سلة المهملات (حذفاً ناعماً).
  static Future<void> hardDeleteLog(String logId) async {
    await softDeleteLog(logId);
  }

  // ─── 8. إفراغ السجل بالكامل (نقل كل السجلات النشطة لسلة المهملات) ───
  static Future<int> clearAllLogs() async {
    int count = 0;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('audit_logs')
          .where('isDeleted',
              isEqualTo: false) // لحماية السجلات المحذوفة مسبقاً
          .get();

      const batchSize = 500;
      for (var i = 0; i < snap.docs.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = snap.docs.skip(i).take(batchSize);
        for (final doc in chunk) {
          batch.update(doc.reference, {
            'isDeleted': true,
            'deletedAt': FieldValue.serverTimestamp(),
          });
          count++;
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Clear all logs failed: $e');
    }
    return count;
  }
}
