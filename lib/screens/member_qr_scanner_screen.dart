// screens/member_qr_scanner_screen.dart
// ┘à╪د╪│╪ص QR ┘┘╪╣╪╢┘ê: ┘è┘à╪│╪ص ┘â┘ê╪» ╪د┘┘à┘â╪د┘ ┘╪ذ╪»╪ة ┘à╪│╪د╪▒ ╪د┘╪▓┘è╪د╪▒╪ر ╪د┘┘à┘ê╪س┘é╪ر╪î
// ╪س┘à ┘è╪╣╪▒╪╢ ┘â┘ê╪» ╪د┘╪▓┘è╪د╪▒╪ر ┘┘╪ز╪د╪ش╪▒. ┘ç╪░╪د ┘ç┘ê ╪د┘┘à╪»╪«┘ ╪د┘┘à╪ذ╪د╪┤╪▒ ┘┘à╪│╪د╪▒ ╪د┘╪▓┘è╪د╪▒╪ر
// ╪د┘╪░┘è ┘è╪ز┘è╪ص ╪د┘╪ز┘é┘è┘è┘à ┘ê╪د┘┘à┘â╪د┘╪ث╪ر ╪ذ╪╣╪» ╪ز╪ث┘â┘è╪» ╪د┘╪ز╪د╪ش╪▒.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../services/auth_service.dart';
import '../services/place_service.dart';
import '../services/visit_service.dart';
import 'my_qr_screen.dart';

class MemberQrScannerScreen extends StatefulWidget {
  const MemberQrScannerScreen({super.key});

  @override
  State<MemberQrScannerScreen> createState() => _MemberQrScannerScreenState();
}

class _MemberQrScannerScreenState extends State<MemberQrScannerScreen> {
  late final MobileScannerController _controller;
  bool _cameraReady = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String value) async {
    if (_processing) return;
    final prefix = 'yb://place/';
    if (!value.startsWith(prefix)) {
      await _showMessage('qr_not_supported');
      return;
    }

    final placeId = value.substring(prefix.length).trim();
    if (placeId.isEmpty) {
      await _showMessage('qr_invalid');
      return;
    }

    setState(() => _processing = true);
    _controller.stop();

    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) {
        await _showMessage('qr_sign_in_required');
        return;
      }

      final place = await PlaceService().getPlaceById(placeId);
      if (place == null) {
        await _showMessage('qr_place_not_found');
        return;
      }

      final requestId = await VisitService().createVisitRequest(place.id, uid);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MyQrScreen(place: place, existingRequestId: requestId)),
      );
    } catch (e) {
      await _showMessage('qr_scan_error');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showMessage(String key) async {
    if (!mounted) return;
    final lang = LocaleController.of(context).locale.languageCode;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.of('qr_scan_title', lang)),
        content: Text(AppStrings.of(key, lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of('close', lang)),
          ),
        ],
      ),
    );
    if (mounted && !_processing) _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of('member_scan_qr', lang)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_cameraReady)
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final value = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
                if (value != null) _handleScan(value);
              },
            )
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                AppStrings.of('member_scan_qr_hint', lang),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
