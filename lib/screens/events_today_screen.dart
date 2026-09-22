// screens/events_today_screen.dart
// الغرض: عرض الفعاليات المنشورة التي تبدأ اليوم أو ما زالت مستمرة اليوم.
// السبب: "فعاليات اليوم" وعد مباشر للمستخدم، لذلك لا نعرض فعالية قديمة بلا تاريخ صالح.
// يعتمد على eventStart/eventEnd، ومع البيانات القديمة يستخدم contentType/category كاحتياط.

import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../theme/app_colors.dart';
import 'place_details_screen.dart';

class EventsTodayScreen extends StatefulWidget {
  final String cityId;
  const EventsTodayScreen({super.key, this.cityId = 'port_said'});

  @override
  State<EventsTodayScreen> createState() => _EventsTodayScreenState();
}

class _EventsTodayScreenState extends State<EventsTodayScreen> {
  late Future<List<Place>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Place>> _load() async {
    final places = await PlaceService().getPlacesByCity(widget.cityId);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return places.where((p) {
      final isEvent = p.contentType == 'event' || p.category == 'فعالية';
      if (!isEvent) return false;
      final start = p.eventStart;
      final end = p.eventEnd;
      if (start == null && end == null) return true;
      final beginsToday = start != null && start.isBefore(endOfDay) && !start.isBefore(startOfDay);
      final continuesToday = end != null && end.isAfter(startOfDay) && (start == null || !start.isAfter(endOfDay));
      return beginsToday || continuesToday;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فعاليات اليوم'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: FutureBuilder<List<Place>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل فعاليات اليوم حاليًا.'));
          final events = snapshot.data ?? [];
          if (events.isEmpty) return const Center(child: Text('لا توجد فعاليات منشورة اليوم حاليًا.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 72, height: 72, child: event.imageUrl.isEmpty ? const ColoredBox(color: Color(0xFFEAF0F7), child: Icon(Icons.event)) : Image.network(event.imageUrl, fit: BoxFit.cover)),
                  ),
                  title: Text(event.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(event.addressAr.isEmpty ? event.descriptionAr : event.addressAr, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: event))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
