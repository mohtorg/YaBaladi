// screens/my_qr_screen.dart
// ╪┤╪د╪┤╪ر ╪ز┘ê┘┘ّ╪» ┘ê╪ز╪╣╪▒╪╢ ┘â┘ê╪» QR ┘┘┘à╪│╪ز╪«╪»┘à ┘è┘ê╪▒┘è┘ç ┘┘╪ز╪د╪ش╪▒
// ╪د┘┘â┘ê╪» ╪╡╪د┘╪ص 10 ╪»┘é╪د╪خ┘é ╪ذ╪│╪î ┘ê┘┘à╪د ┘è╪ز┘à╪│╪ص ╪ذ┘è┘┘╪ز╪ص ╪ز┘┘é╪د╪خ┘è┘ï╪د ┘à╪│╪د╪▒ ╪د┘╪ز┘é┘è┘è┘à

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import '../models/place.dart';

class MyQrScreen extends StatefulWidget {
  final Place place;
  final String? existingRequestId;

  const MyQrScreen({super.key, required this.place, this.existingRequestId});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  String? _requestId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingRequestId != null && widget.existingRequestId!.trim().isNotEmpty) {
      _requestId = widget.existingRequestId;
      _isLoading = false;
    } else {
      _generateCode();
    }
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
        SnackBar(content: Text('╪ز╪╣╪░╪▒ ╪ح┘╪┤╪د╪ة ┘â┘ê╪» ╪د┘╪▓┘è╪د╪▒╪ر: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('┘â┘ê╪» ╪د┘╪▓┘è╪د╪▒╪ر'),
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
                      '┘ê╪▒┘è┘ّ ╪د┘┘â┘ê╪» ╪»┘ç ┘┘╪ز╪د╪ش╪▒ ╪╣╪┤╪د┘ ┘è┘ê╪س┘ّ┘é ╪▓┘è╪د╪▒╪ز┘â\n╪╡╪د┘╪ص ┘┘à╪»╪ر 10 ╪»┘é╪د╪خ┘é',
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
                      label: const Text('╪ز┘ê┘┘è╪» ┘â┘ê╪» ╪ش╪»┘è╪»'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
