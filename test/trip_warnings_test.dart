// test/trip_warnings_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/models/trip_warnings.dart';

void main() {
  group('TripWarnings — classification', () {
    test('hasAny + hasCritical', () {
      const w = TripWarnings(
        warnings: [
          TripWarning(
            code: 'w1',
            messageAr: 'تحذير',
            severity: TripWarningSeverity.warning,
          ),
        ],
      );
      expect(w.hasAny, isTrue);
      expect(w.hasCritical, isFalse);
    });

    test('hasCritical عند وجود خطأ حرِج', () {
      const w = TripWarnings(
        warnings: [
          TripWarning(
            code: 'e1',
            messageAr: 'خطأ',
            severity: TripWarningSeverity.critical,
          ),
        ],
      );
      expect(w.hasCritical, isTrue);
    });

    test('filterBy + countBySeverity', () {
      const w = TripWarnings(
        warnings: [
          TripWarning(
            code: 'a',
            messageAr: 'A',
            severity: TripWarningSeverity.info,
          ),
          TripWarning(
            code: 'b',
            messageAr: 'B',
            severity: TripWarningSeverity.warning,
          ),
          TripWarning(
            code: 'c',
            messageAr: 'C',
            severity: TripWarningSeverity.warning,
          ),
        ],
      );
      expect(w.countBySeverity(TripWarningSeverity.warning), 2);
      expect(w.filterBy(TripWarningSeverity.warning).length, 2);
      expect(w.filterBy(TripWarningSeverity.info).first.code, 'a');
    });
  });

  group('TripWarnings — empty', () {
    test('empty لها hasAny = false', () {
      expect(TripWarnings.empty.hasAny, isFalse);
      expect(TripWarnings.empty.hasCritical, isFalse);
    });
  });
}
