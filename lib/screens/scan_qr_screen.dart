// screens/scan_qr_screen.dart
// شاشة مسح كود الزبون - خاصة بالتاجر بس
// بتفتح الكاميرا، تمسح الكود، وتأكّد الزيارة فورًا

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import '../l10n/locale_controller.dart';
import '../widgets/permission_explanation.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _isProcessing = false; // يمنع مسح نفس الكود أكتر من مرة بالغلط
  late final MobileScannerController _scannerController;
  bool _permissionFlowStarted = false;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_permissionFlowStarted) return;
    _permissionFlowStarted = true;
    _prepareScanner();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // نشرح سبب الكاميرا قبل تشغيل الماسح حتى تكون الصلاحية مرتبطة مباشرة بالوظيفة.
  Future<void> _prepareScanner() async {
    final lang = LocaleController.of(context).locale.languageCode;
    final allowed = await showPermissionExplanation(context: context, lang: lang, titleKey: 'permission_camera_title', bodyKey: 'permission_camera_body');
    if (!mounted) return;
    if (allowed) {
      // لا ننشئ Widget الكاميرا قبل موافقة المستخدم؛ بذلك لا تبدأ مكتبة
      // mobile_scanner تلقائيًا قبل شاشة الشرح. بعد الموافقة فقط نُظهر الماسح.
      if (mounted) setState(() => _cameraReady = true);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleScan(String requestId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final merchantId = AuthService().currentUser?.uid;
    if (merchantId == null) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    VisitConfirmationResult result;
    try {
      result = await VisitService().confirmVisitRequest(
        requestId: requestId,
        merchantId: merchantId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تأكيد الزيارة: $e')),
      );
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.success ? 'نجح ✅' : 'خطأ ❌'),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // يقفل الرسالة
              if (result.success) {
                Navigator.pop(context); // يرجع للوحة التاجر
              } else {
                setState(() => _isProcessing = false); // يسمح بمحاولة تانية
              }
            },
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح كود الزبون'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // قبل الموافقة لا نُنشئ MobileScanner أصلًا؛ هذا يضمن أن طلب الكاميرا
          // لا يظهر للمستخدم قبل الرسالة التي تشرح سبب استخدام الكاميرا.
          if (_cameraReady)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final value = barcodes.first.rawValue;
                  if (value != null) _handleScan(value);
                }
              },
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
