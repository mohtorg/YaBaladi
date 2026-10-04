// main_seed.dart
// نقطة دخول مستقلة لزرع Firestore — لا تلمس main.dart الأصلي.
// التشغيل: flutter run -d web-server --web-port=8081 -t lib/main_seed.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/seed_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SeedApp());
}

class SeedApp extends StatelessWidget {
  const SeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SeedScreen(),
    );
  }
}

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  final _service = SeedService();
  final List<String> _log = [];
  bool _busy = false;

  void _add(String msg) {
    setState(() => _log.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)}  $msg'));
  }

  Future<void> _run(Future<void> Function() action, String label) async {
    if (_busy) return;
    setState(() => _busy = true);
    _add('▶ $label...');
    try {
      await action();
      _add('✅ $label — done');
    } catch (e, st) {
      _add('❌ $label — $e');
      debugPrint('$st');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌱 Firestore Seeder'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final n = await _service.seedAllCategories();
                            _add('📦 $n categories');
                          }, 'Seed Categories (9)'),
                  icon: const Icon(Icons.category),
                  label: const Text('Seed Categories'),
                ),
                ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final n = await _service.seedAllPlaces();
                            _add('📍 $n places');
                          }, 'Seed Places (12)'),
                  icon: const Icon(Icons.place),
                  label: const Text('Seed Places'),
                ),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final r = await _service.seedAll();
                            _add('🎉 ${r['categories']} cats + ${r['places']} places');
                          }, 'Seed ALL'),
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('SEED ALL'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() => _service.clearAll(), 'Clear All'),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear (dev only)'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _log.isEmpty
                    ? const Center(
                        child: Text('No operations yet',
                            style: TextStyle(color: Colors.white54)),
                      )
                    : ListView.builder(
                        itemCount: _log.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _log[i],
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (_busy) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}