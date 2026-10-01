/// Merchant lifecycle vocabulary defined by Ya Baladi project documents.
///
/// This layer is intentionally independent from Firestore, Authentication,
/// permissions, and database schema. It does not perform any state transition.
enum MerchantLifecycleStatus {
  pending,
  approved,
  needsRevision,
  rejected,
  unverified,
  underReview,
  verified,
  published,
}

extension MerchantLifecycleStatusX on MerchantLifecycleStatus {
  /// Canonical persisted/document terminology from the project documents.
  String get value => switch (this) {
        MerchantLifecycleStatus.pending => 'Pending',
        MerchantLifecycleStatus.approved => 'Approved',
        MerchantLifecycleStatus.needsRevision => 'Needs Revision',
        MerchantLifecycleStatus.rejected => 'Rejected',
        MerchantLifecycleStatus.unverified => 'Unverified',
        MerchantLifecycleStatus.underReview => 'Under Review',
        MerchantLifecycleStatus.verified => 'Verified',
        MerchantLifecycleStatus.published => 'Published',
      };

  static MerchantLifecycleStatus? fromValue(String value) {
    for (final status in MerchantLifecycleStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}
