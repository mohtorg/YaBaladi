import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  placeBlocked,
  placeUnblocked,
  supportReply,
  merchantApproved,
  merchantRejected,
  newOffer,
  newReview,
  systemAnnouncement,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      title: d['title']?.toString() ?? 'إشعار',
      body: d['body']?.toString() ?? '',
      type: _parseType(d['type']?.toString() ?? 'systemAnnouncement'),
      data: d['data'] is Map
          ? Map<String, dynamic>.from(d['data'] as Map)
          : <String, dynamic>{},
      isRead: d['isRead'] == true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static NotificationType _parseType(String s) {
    switch (s) {
      case 'placeBlocked':
        return NotificationType.placeBlocked;
      case 'placeUnblocked':
        return NotificationType.placeUnblocked;
      case 'supportReply':
        return NotificationType.supportReply;
      case 'merchantApproved':
        return NotificationType.merchantApproved;
      case 'merchantRejected':
        return NotificationType.merchantRejected;
      case 'newOffer':
        return NotificationType.newOffer;
      case 'newReview':
        return NotificationType.newReview;
      default:
        return NotificationType.systemAnnouncement;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.placeBlocked:
        return Icons.block;
      case NotificationType.placeUnblocked:
        return Icons.lock_open;
      case NotificationType.supportReply:
        return Icons.support_agent;
      case NotificationType.merchantApproved:
        return Icons.verified;
      case NotificationType.merchantRejected:
        return Icons.cancel;
      case NotificationType.newOffer:
        return Icons.local_offer;
      case NotificationType.newReview:
        return Icons.star;
      case NotificationType.systemAnnouncement:
        return Icons.campaign;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.placeBlocked:
        return Colors.red;
      case NotificationType.placeUnblocked:
        return Colors.green;
      case NotificationType.supportReply:
        return Colors.blue;
      case NotificationType.merchantApproved:
        return Colors.green;
      case NotificationType.merchantRejected:
        return Colors.orange;
      case NotificationType.newOffer:
        return Colors.purple;
      case NotificationType.newReview:
        return Colors.amber;
      case NotificationType.systemAnnouncement:
        return Colors.teal;
    }
  }
}
