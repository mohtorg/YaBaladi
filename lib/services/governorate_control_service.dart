import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/egypt_governorates.dart';
import '../models/governorate_control.dart';

class GovernorateControlService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _governorates => _db.collection('governorates');

  static const featureDefinitions = <GovernorateFeatureDefinition>[
    GovernorateFeatureDefinition(id: 'places', nameAr: 'الأماكن', nameEn: 'Places', descriptionAr: 'دليل الأماكن والمنشآت', descriptionEn: 'Places directory'),
    GovernorateFeatureDefinition(id: 'events', nameAr: 'الفعاليات', nameEn: 'Events', descriptionAr: 'الفعاليات والأنشطة', descriptionEn: 'Events and activities'),
    GovernorateFeatureDefinition(id: 'offers', nameAr: 'العروض', nameEn: 'Offers', descriptionAr: 'العروض والخصومات', descriptionEn: 'Offers and discounts'),
    GovernorateFeatureDefinition(id: 'library', nameAr: 'المكتبة', nameEn: 'Library', descriptionAr: 'المحتوى الثقافي والبصري', descriptionEn: 'Cultural and visual content'),
    GovernorateFeatureDefinition(id: 'day_trip', nameAr: 'رحلة اليوم', nameEn: 'Day Trip', descriptionAr: 'اقتراحات رحلات اليوم', descriptionEn: 'Day trip suggestions'),
    GovernorateFeatureDefinition(id: 'rewards', nameAr: 'المكافآت', nameEn: 'Rewards', descriptionAr: 'النقاط والمكافآت', descriptionEn: 'Points and rewards'),
    GovernorateFeatureDefinition(id: 'nearby', nameAr: 'الأماكن القريبة', nameEn: 'Nearby', descriptionAr: 'اكتشاف الأماكن القريبة', descriptionEn: 'Nearby discovery'),
  ];

  Stream<List<GovernorateControl>> watchPublic() {
    return _governorates.where('enabled', isEqualTo: true).where('visible', isEqualTo: true).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => GovernorateControl.fromMap(doc.id, doc.data()))
          .where((gov) => gov.enabled && gov.visible)
          .toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Stream<List<GovernorateControl>> watchAll() {
    return _governorates.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => GovernorateControl.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Future<void> ensureDefaults() async {
    final refs = EgyptGovernorates.all.map((info) => _governorates.doc(info.id)).toList();
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));
    final batch = _db.batch();
    for (var i = 0; i < snapshots.length; i++) {
      if (snapshots[i].exists) continue;
      final info = EgyptGovernorates.all[i];
      final ref = refs[i];
      final isLaunch = info.id == EgyptGovernorates.activeGovernorateId;
      batch.set(ref, {
        'name_ar': info.nameAr,
        'name_en': info.nameEn,
        'status': isLaunch ? 'active' : 'draft',
        'enabled': isLaunch,
        'visible': isLaunch,
        'sortOrder': i,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
    }
    if (snapshots.any((snapshot) => !snapshot.exists)) await batch.commit();
  }

  Future<void> updateGovernorates({
    required Iterable<String> governorateIds,
    bool? enabled,
    bool? visible,
    GovernorateStatus? status,
  }) async {
    final ids = governorateIds.toSet().toList();
    if (ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      };
      if (enabled != null) data['enabled'] = enabled;
      if (visible != null) data['visible'] = visible;
      if (status != null) data['status'] = status.name;
      batch.set(_governorates.doc(id), data, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> setFeatureState({
    required Iterable<String> governorateIds,
    required String featureId,
    required FeatureState state,
  }) async {
    final ids = governorateIds.toSet().toList();
    if (ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      final ref = _governorates.doc(id).collection('feature_overrides').doc(featureId);
      if (state == FeatureState.inherit) {
        batch.delete(ref);
      } else {
        batch.set(ref, {
          'state': state.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid,
        }, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  Stream<Map<String, FeatureState>> watchEffectiveFeatureStates(String governorateId) {
    return watchFeatureOverrides(governorateId).map((overrides) {
      return {
        for (final feature in featureDefinitions)
          feature.id: overrides[feature.id] ??
              (feature.defaultEnabled ? FeatureState.enabled : FeatureState.disabled),
      };
    });
  }

  Stream<Map<String, FeatureState>> watchFeatureOverrides(String governorateId) {
    return _governorates.doc(governorateId).collection('feature_overrides').snapshots().map((snapshot) {
      return {
        for (final doc in snapshot.docs)
          doc.id: featureStateFromValue(doc.data()['state']?.toString()),
      };
    });
  }

  Stream<List<GovernorateGroup>> watchGroups() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const <GovernorateGroup>[]);

    return _db.collection('admin_profiles').doc(uid).snapshots().asyncExpand((profileSnapshot) async* {
      final profile = profileSnapshot.data();
      if (profile == null || profile['active'] != true) {
        yield const <GovernorateGroup>[];
        return;
      }

      final permissions = List<String>.from(profile['permissions'] ?? const <String>[]);
      final canRead = permissions.contains('*') || permissions.contains('governorates.read');
      if (!canRead) {
        yield const <GovernorateGroup>[];
        return;
      }

      final scope = Map<String, dynamic>.from(profile['scope'] ?? const <String, dynamic>{});
      final scopeAll = scope['all'] == true;
      final governorateIds = List<String>.from(scope['governorateIds'] ?? const <String>[]);

      final token = await _auth.currentUser?.getIdTokenResult();
      final isAdmin = token?.claims?['admin'] == true;

      Query<Map<String, dynamic>> query = _db.collection('governorate_groups');
      if (!isAdmin && !scopeAll) {
        if (governorateIds.isEmpty) {
          yield const <GovernorateGroup>[];
          return;
        }
        query = query.where('governorateIds', arrayContainsAny: governorateIds);
      }

      await for (final snapshot in query.snapshots()) {
        final list = snapshot.docs
            .map((doc) => GovernorateGroup.fromMap(doc.id, doc.data()))
            .toList();
        yield list;
      }
    });
  }

  Future<void> saveGroup({
    required String id,
    required String nameAr,
    required String nameEn,
    required List<String> governorateIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('يجب تسجيل الدخول لإدارة مجموعات المحافظات.');
    }

    final token = await user.getIdTokenResult();
    final isAdmin = token.claims?['admin'] == true;

    if (!isAdmin) {
      final profileSnapshot =
          await _db.collection('admin_profiles').doc(user.uid).get();
      final profile = profileSnapshot.data();
      if (profile == null || profile['active'] != true) {
        throw StateError('لا توجد صلاحية إدارية فعالة.');
      }

      final permissions =
          List<String>.from(profile['permissions'] ?? const <String>[]);
      final canWrite = permissions.contains('*') ||
          permissions.contains('governorates.write');
      if (!canWrite) {
        throw StateError('لا تملك صلاحية تعديل مجموعات المحافظات.');
      }

      final scope = Map<String, dynamic>.from(
        profile['scope'] ?? const <String, dynamic>{},
      );
      final scopeAll = scope['all'] == true;
      final allowedGovernorates =
          List<String>.from(scope['governorateIds'] ?? const <String>[]);

      if (!scopeAll &&
          (governorateIds.isEmpty ||
              !governorateIds
                  .every(allowedGovernorates.contains))) {
        throw StateError(
          'لا يمكن إنشاء أو تعديل مجموعة خارج نطاق المحافظات المصرح بها.',
        );
      }
    }

    await _db.collection('governorate_groups').doc(id).set({
      'name_ar': nameAr,
      'name_en': nameEn,
      'governorateIds': governorateIds.toSet().toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    });
  }
}
