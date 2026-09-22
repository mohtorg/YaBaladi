// models/task_model.dart
// نموذج مهمة شخصية للمستخدم. المهمة ليست إشعارًا؛ الإشعار هو وسيلة التنبيه،
// بينما هذا المستند يمثل الشيء الذي يريد المستخدم تنفيذه وموعده.
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTask {
  final String id;
  final String userId;
  final String title;
  final DateTime scheduledAt;
  final bool completed;
  const UserTask({required this.id, required this.userId, required this.title, required this.scheduledAt, this.completed=false});
  factory UserTask.fromMap(String id, Map<String,dynamic> m) => UserTask(
    id:id,userId:m['userId']??'',title:m['title']??'',
    scheduledAt:(m['scheduledAt'] is Timestamp)?(m['scheduledAt'] as Timestamp).toDate():DateTime.now(),
    completed:m['completed']??false,
  );
}
