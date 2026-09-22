// screens/my_qr_screen.dart
// شاشة تولّد وتعرض كود QR للمستخدم يوريه للتاجر
// الكود صالح 10 دقائق بس، ولما يتمسح بينفتح تلقائيًا مسار التقييم

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import '../models/place.dart';

class MyQrScreen extends StatefulWidget {
  final Place place;

  const MyQrScreen({super.key, required this.place});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  String? _requestId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  Future<void> _generateCode() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final requestId = await VisitService().createVisitRequest(widget.place.id, uid);
      if (!mounted) return;
      setState(() {
        _requestId = requestId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء كود الزيارة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كود الزيارة'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.place.nameAr,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                        ],
                      ),
                      child: QrImageView(
                        data: _requestId ?? '',
                        size: 220,
                        version: QrVersions.auto,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'وريّ الكود ده للتاجر عشان يوثّق زيارتك\nصالح لمدة 10 دقائق',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _generateCode();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('توليد كود جديد'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
