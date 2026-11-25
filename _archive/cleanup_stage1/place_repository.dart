import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';

/// كلاس لتغليف نتيجة عملية الرفع المجمع
class BulkUploadResult {
  final int successCount;
  final int duplicateCount;
  final List<String> errors;

  BulkUploadResult({
    required this.successCount,
    required this.duplicateCount,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

class PlaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'places';

  Future<BulkUploadResult> bulkUploadPlaces(List<PlaceModel> places) async {
    int successCount = 0;
    int duplicateCount = 0;
    final List<String> errors = [];

    if (places.isEmpty) {
      return BulkUploadResult(
        successCount: 0,
        duplicateCount: 0,
        errors: ['لا توجد بيانات صالحة للرفع.'],
      );
    }

    try {
      final newNames = places.map((p) => p.nameAr).toList();
      final Set<String> existingNames = {};

      for (int i = 0; i < newNames.length; i += 10) {
        final end = (i + 10 < newNames.length) ? i + 10 : newNames.length;
        final chunk = newNames.sublist(i, end);

        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('name_ar', whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          existingNames.add(doc.data()['name_ar']?.toString().trim() ?? '');
        }
      }

      final List<PlaceModel> placesToUpload = [];
      final Set<String> pendingNames = {};

      for (final place in places) {
        final cleanName = place.nameAr.trim();

        if (existingNames.contains(cleanName) ||
            pendingNames.contains(cleanName)) {
          duplicateCount++;
        } else {
          placesToUpload.add(place);
          pendingNames.add(cleanName);
        }
      }

      if (placesToUpload.isEmpty) {
        return BulkUploadResult(
          successCount: 0,
          duplicateCount: duplicateCount,
          errors: [
            'كل المعالم الموجودة في الملف مسجلة مسبقاً في قاعدة البيانات أو مكررة داخل الملف.'
          ],
        );
      }

      const int batchSize = 400;

      for (int i = 0; i < placesToUpload.length; i += batchSize) {
        final WriteBatch batch = _firestore.batch();

        final end = (i + batchSize < placesToUpload.length)
            ? i + batchSize
            : placesToUpload.length;

        final currentBatch = placesToUpload.sublist(i, end);

        for (final place in currentBatch) {
          final DocumentReference docRef =
              _firestore.collection(_collectionName).doc();
          batch.set(docRef, place.toMap());
        }

        await batch.commit();
        successCount += currentBatch.length;
      }
    } catch (e) {
      errors.add('حدث خطأ أثناء الاتصال بقاعدة البيانات: ${e.toString()}');
    }

    return BulkUploadResult(
      successCount: successCount,
      duplicateCount: duplicateCount,
      errors: errors,
    );
  }

  Future<int> getPlacesCount() async {
    try {
      final snapshot =
          await _firestore.collection(_collectionName).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
