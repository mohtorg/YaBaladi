# Ya Baladi — Merchant Foundation G4

This artifact implements only the documented Merchant Lifecycle vocabulary.

Included:
- `lib/models/merchant_lifecycle.dart`
- `test/merchant_lifecycle_test.dart`

Intentionally NOT included:
- Firestore collections/rules
- Authentication claims
- Roles/permissions
- Merchant database schema
- State transition rules
- Admin/Supervisor UI
- Firebase writes

Reason:
The current clean rebuild does not yet contain an executable merchant layer or
Firestore Rules. The project security standard requires the actual current
rules/code to be inspected before defining ownership, permissions, or schema.

Next verification on the development machine:
1. Copy the two Dart files into `C:\ya_baladi_rebuild`.
2. Run:
   `flutter test test\merchant_lifecycle_test.dart`
3. Run:
   `flutter analyze lib\models\merchant_lifecycle.dart`
