import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/models/merchant_lifecycle.dart';

void main() {
  test('Merchant lifecycle vocabulary contains the eight documented states', () {
    expect(MerchantLifecycleStatus.values, hasLength(8));

    expect(MerchantLifecycleStatus.pending.value, 'Pending');
    expect(MerchantLifecycleStatus.approved.value, 'Approved');
    expect(
      MerchantLifecycleStatus.needsRevision.value,
      'Needs Revision',
    );
    expect(MerchantLifecycleStatus.rejected.value, 'Rejected');
    expect(MerchantLifecycleStatus.unverified.value, 'Unverified');
    expect(MerchantLifecycleStatus.underReview.value, 'Under Review');
    expect(MerchantLifecycleStatus.verified.value, 'Verified');
    expect(MerchantLifecycleStatus.published.value, 'Published');
  });

  test('Unknown lifecycle value is not silently converted', () {
    expect(
      MerchantLifecycleStatusX.fromValue('Unknown'),
      isNull,
    );
  });

  test('Documented lifecycle values round-trip', () {
    for (final status in MerchantLifecycleStatus.values) {
      expect(
        MerchantLifecycleStatusX.fromValue(status.value),
        status,
      );
    }
  });
}
