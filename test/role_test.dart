// test/role_test.dart
//
// اختبارات Wave 1a: AUTH-BUG-1 fix
//   - roleFromCode يقبل 'user' كمرادف لـ 'member'

import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/core/auth/role.dart';

void main() {
  group('roleFromCode — v1.1 aliases', () {
    test("'user' → UserRole.member (المرادف الجديد)", () {
      expect(roleFromCode('user'), UserRole.member);
    });

    test("'member' → UserRole.member (الأصلي)", () {
      expect(roleFromCode('member'), UserRole.member);
    });

    test("'user' و 'member' يعطيان نفس النتيجة", () {
      expect(roleFromCode('user'), roleFromCode('member'));
    });
  });

  group('roleFromCode — كل الأدوار', () {
    test("'visitor' → UserRole.visitor", () {
      expect(roleFromCode('visitor'), UserRole.visitor);
    });

    test("'merchant' → UserRole.merchant", () {
      expect(roleFromCode('merchant'), UserRole.merchant);
    });

    test("'team' → UserRole.team", () {
      expect(roleFromCode('team'), UserRole.team);
    });

    test("'moderator' → UserRole.moderator", () {
      expect(roleFromCode('moderator'), UserRole.moderator);
    });

    test("'manager' → UserRole.manager", () {
      expect(roleFromCode('manager'), UserRole.manager);
    });

    test("'admin' → UserRole.admin", () {
      expect(roleFromCode('admin'), UserRole.admin);
    });
  });

  group('roleFromCode — defensive fallbacks', () {
    test('null → UserRole.member', () {
      expect(roleFromCode(null), UserRole.member);
    });

    test('نص فارغ → UserRole.member', () {
      expect(roleFromCode(''), UserRole.member);
    });

    test('نص غير معروف → UserRole.member', () {
      expect(roleFromCode('unknown_role'), UserRole.member);
    });

    test('حالة أحرف مختلفة (User) → UserRole.member', () {
      expect(roleFromCode('User'), UserRole.member);
    });
  });
}
