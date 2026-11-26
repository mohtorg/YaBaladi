import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/core/services/qr_verification_service.dart';

void main() {
  group('QrVerificationService Tests', () {
    test('generatePlaceQrPayload generates correct standard format', () {
      final payload = QrVerificationService.generatePlaceQrPayload(
        placeId: 'port_said_lighthouse',
        governorate: 'port_said',
      );

      expect(payload, equals('YB-QR:v1:port_said:port_said_lighthouse'));
    });

    test('verifyQrPayload validates matching placeId correctly', () {
      const validPayload = 'YB-QR:v1:port_said:port_said_lighthouse';

      final isValid = QrVerificationService.verifyQrPayload(
        scannedPayload: validPayload,
        expectedPlaceId: 'port_said_lighthouse',
      );

      expect(isValid, isTrue);
    });

    test('verifyQrPayload rejects mismatched placeId', () {
      const validPayload = 'YB-QR:v1:port_said:port_said_lighthouse';

      final isValid = QrVerificationService.verifyQrPayload(
        scannedPayload: validPayload,
        expectedPlaceId: 'another_place_id',
      );

      expect(isValid, isFalse);
    });

    test('verifyQrPayload rejects malformed or empty payloads', () {
      expect(
        QrVerificationService.verifyQrPayload(
          scannedPayload: '',
          expectedPlaceId: 'p1',
        ),
        isFalse,
      );

      expect(
        QrVerificationService.verifyQrPayload(
          scannedPayload: 'RANDOM_TEXT_123',
          expectedPlaceId: 'p1',
        ),
        isFalse,
      );
    });
  });
}
