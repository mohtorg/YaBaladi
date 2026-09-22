// المهام منفصلة عن الإشعارات: المهمة هي ما يريد المستخدم تنفيذه،
// والإشعار هو وسيلة تذكيره بها. لذلك لا نخلط collection tasks مع notifications.
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  Future<void> _add(BuildContext context, String lang) async {
    final c = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(hours: 1));
    final now = DateTime.now();
    final quick = [
      ('today', DateTime(now.year, now.month, now.day, 18)),
      ('tomorrow', DateTime(now.year, now.month, now.day + 1, 18)),
      ('next_week', DateTime(now.year, now.month, now.day + 7, 18)),
    ];
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      title: Text(AppStrings.of('new_task', lang)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, decoration: InputDecoration(labelText: AppStrings.of('task_title', lang))),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: quick.map((q) => ActionChip(label: Text(AppStrings.of(q.$1, lang)), onPressed: () => setState(() => when = q.$2))).toList()),
        ListTile(title: Text(AppStrings.of('scheduled_time', lang)), subtitle: Text(_format(when)), trailing: const Icon(Icons.event), onTap: () async {
          final d = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: when.isBefore(DateTime.now()) ? DateTime.now() : when);
          if (d == null || !ctx.mounted) return;
          final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(when));
          if (t != null) setState(() => when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
        }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.of('cancel', lang))), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim().isNotEmpty), child: Text(AppStrings.of('save', lang)))],
    )));
    if (ok == true) await TaskService().add(c.text, when);
    c.dispose();
  }

  static String _format(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of('tasks', lang)), backgroundColor: const Color(0xFF1454A3), foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: () => _add(context, lang), child: const Icon(Icons.add)),
      body: StreamBuilder(stream: TaskService().watchMine(), builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) return Center(child: Text(AppStrings.of('no_tasks', lang)));
        return ListView.builder(itemCount: tasks.length, itemBuilder: (context, i) {
          final t = tasks[i];
          return Dismissible(key: ValueKey(t.id), background: Container(color: Colors.red), onDismissed: (_) => TaskService().delete(t.id), child: CheckboxListTile(value: t.completed, onChanged: (v) => TaskService().setCompleted(t.id, v ?? false), title: Text(t.title, style: TextStyle(decoration: t.completed ? TextDecoration.lineThrough : null)), subtitle: Text(_format(t.scheduledAt))));
        });
      }),
    );
  }
}

