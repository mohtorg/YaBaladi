// lib/features/admin/screens/manage_review_criteria_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';

class ManageReviewCriteriaScreen extends StatefulWidget {
  const ManageReviewCriteriaScreen({super.key});

  @override
  State<ManageReviewCriteriaScreen> createState() =>
      _ManageReviewCriteriaScreenState();
}

class _ManageReviewCriteriaScreenState
    extends State<ManageReviewCriteriaScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المعايير'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'معايير عامة', icon: Icon(Icons.public)),
              Tab(text: 'معايير خاصة', icon: Icon(Icons.category)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GeneralCriteriaView(),
            _SpecificCriteriaCategoriesView(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. المعايير العامة (General)
// ═══════════════════════════════════════════════════════════════

class _GeneralCriteriaView extends StatefulWidget {
  const _GeneralCriteriaView();

  @override
  State<_GeneralCriteriaView> createState() => _GeneralCriteriaViewState();
}

class _GeneralCriteriaViewState extends State<_GeneralCriteriaView> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _showDialog({DocumentSnapshot? doc}) async {
    final isEdit = doc != null;
    final data = isEdit ? doc.data() as Map<String, dynamic> : null;

    final nameArController = TextEditingController(text: data?['nameAr'] ?? '');
    final nameEnController = TextEditingController(text: data?['nameEn'] ?? '');
    final descArController =
        TextEditingController(text: data?['descriptionAr'] ?? '');
    final fieldKeyController =
        TextEditingController(text: data?['fieldKey'] ?? '');
    final weightController =
        TextEditingController(text: (data?['weight'] ?? 1.0).toString());
    final orderController =
        TextEditingController(text: (data?['order'] ?? 1).toString());

    bool isActive = data?['isActive'] ?? true;
    bool isRequired = data?['isRequired'] ?? true;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'تعديل معيار عام' : 'إضافة معيار عام',
                  style: YaBaladiTypography.headingLabel),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameArController,
                      decoration:
                          const InputDecoration(labelText: 'الاسم العربي'),
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    TextField(
                      controller: nameEnController,
                      decoration:
                          const InputDecoration(labelText: 'الاسم الإنجليزي'),
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    TextField(
                      controller: descArController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف (شرح للمستخدم)',
                        hintText: 'مثال: هل المكان نظيف ومرتب؟',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    TextField(
                      controller: fieldKeyController,
                      readOnly: isEdit,
                      enabled: !isEdit,
                      decoration: InputDecoration(
                        labelText: 'المفتاح (fieldKey)',
                        hintText: 'e.g., cleanliness',
                        helperText: isEdit
                            ? 'لا يمكن تغيير المفتاح بعد الإنشاء'
                            : 'حروف إنجليزية وأرقام و _ فقط',
                      ),
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'الوزن'),
                          ),
                        ),
                        const SizedBox(width: YaBaladiDesignTokens.space2),
                        Expanded(
                          child: TextField(
                            controller: orderController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'الترتيب'),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('نشط',
                          style: YaBaladiTypography.bodyMedium),
                      value: isActive,
                      onChanged: (v) {
                        setStateDialog(() => isActive = v);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('مطلوب',
                          style: YaBaladiTypography.bodyMedium),
                      value: isRequired,
                      onChanged: (v) {
                        setStateDialog(() => isRequired = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final nameAr = nameArController.text.trim();
                          final fieldKey = fieldKeyController.text.trim();

                          if (nameAr.isEmpty || fieldKey.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('الاسم والمفتاح مطلوبان')),
                            );
                            return;
                          }

                          setStateDialog(() => isSaving = true);

                          try {
                            final collisionSnap = await _firestore
                                .collection('review_criteria')
                                .where('fieldKey', isEqualTo: fieldKey)
                                .get();

                            bool hasCollision = false;
                            for (var d in collisionSnap.docs) {
                              if (!isEdit || d.id != doc.id) {
                                hasCollision = true;
                                break;
                              }
                            }

                            if (hasCollision) {
                              setStateDialog(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'هذا المفتاح (fieldKey) مستخدم بالفعل في معيار آخر!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            final map = {
                              'categoryId': null,
                              'isGeneral': true,
                              'nameAr': nameAr,
                              'nameEn': nameEnController.text.trim(),
                              'descriptionAr': descArController.text.trim(),
                              'fieldKey': fieldKey,
                              'weight':
                                  double.tryParse(weightController.text) ?? 1.0,
                              'order': int.tryParse(orderController.text) ?? 1,
                              'isActive': isActive,
                              'isRequired': isRequired,
                            };
                            if (isEdit) {
                              await _firestore
                                  .collection('review_criteria')
                                  .doc(doc.id)
                                  .update(map);
                            } else {
                              await _firestore
                                  .collection('review_criteria')
                                  .add(map);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setStateDialog(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('حدث خطأ: $e'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('review_criteria')
            .where('isGeneral', isEqualTo: true)
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'حدث خطأ في تحميل البيانات.',
                      style: YaBaladiTypography.headingLabel,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'قد تحتاج إلى إنشاء فهرس (Index) في Firebase.\n${snapshot.error}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('لا توجد معايير عامة. أضف معيارك الأول!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final activeLabel = data['isActive'] == true ? 'نشط' : 'معطل';
              return Card(
                child: ListTile(
                  title: Text(data['nameAr'] as String? ?? 'بدون اسم',
                      style: YaBaladiTypography.headingSubsection),
                  subtitle: Text(
                      'المفتاح: ${data['fieldKey']} | الوزن: ${data['weight']} | $activeLabel'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showDialog(doc: docs[index]),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.visibility_off, color: Colors.red),
                        tooltip: 'تعطيل المعيار',
                        onPressed: () {
                          _firestore
                              .collection('review_criteria')
                              .doc(docs[index].id)
                              .update({'isActive': false});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. المعايير الخاصة (Specific)
// ═══════════════════════════════════════════════════════════════

class _SpecificCriteriaCategoriesView extends StatelessWidget {
  const _SpecificCriteriaCategoriesView();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'حدث خطأ في تحميل التصنيفات.\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('لا توجد تصنيفات بعد'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final nameAr = data['nameAr'] as String? ?? 'بدون اسم';
            return Card(
              child: ListTile(
                title:
                    Text(nameAr, style: YaBaladiTypography.headingSubsection),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ManageSpecificCriteriaScreen(
                        categoryId: docs[index].id,
                        categoryName: nameAr,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ManageSpecificCriteriaScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const _ManageSpecificCriteriaScreen({
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<_ManageSpecificCriteriaScreen> createState() =>
      _ManageSpecificCriteriaScreenState();
}

class _ManageSpecificCriteriaScreenState
    extends State<_ManageSpecificCriteriaScreen> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _showDialog({DocumentSnapshot? doc}) async {
    final isEdit = doc != null;
    final data = isEdit ? doc.data() as Map<String, dynamic> : null;

    final nameArController = TextEditingController(text: data?['nameAr'] ?? '');
    final nameEnController = TextEditingController(text: data?['nameEn'] ?? '');
    final descArController =
        TextEditingController(text: data?['descriptionAr'] ?? '');
    final fieldKeyController =
        TextEditingController(text: data?['fieldKey'] ?? '');
    final weightController =
        TextEditingController(text: (data?['weight'] ?? 1.0).toString());
    final orderController =
        TextEditingController(text: (data?['order'] ?? 1).toString());

    bool isActive = data?['isActive'] ?? true;
    bool isRequired = data?['isRequired'] ?? true;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'تعديل معيار خاص' : 'إضافة معيار خاص',
                  style: YaBaladiTypography.headingLabel),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameArController,
                      decoration:
                          const InputDecoration(labelText: 'الاسم العربي'),
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    TextField(
                      controller: nameEnController,
                      decoration:
                          const InputDecoration(labelText: 'الاسم الإنجليزي'),
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    TextField(
                      controller: descArController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف (شرح للمستخدم)',
                        hintText: 'مثال: هل الطعام لذيذ؟',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    TextField(
                      controller: fieldKeyController,
                      readOnly: isEdit,
                      enabled: !isEdit,
                      decoration: InputDecoration(
                        labelText: 'المفتاح (fieldKey)',
                        hintText: 'e.g., food_taste',
                        helperText: isEdit
                            ? 'لا يمكن تغيير المفتاح بعد الإنشاء'
                            : 'حروف إنجليزية وأرقام و _ فقط',
                      ),
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'الوزن'),
                          ),
                        ),
                        const SizedBox(width: YaBaladiDesignTokens.space2),
                        Expanded(
                          child: TextField(
                            controller: orderController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'الترتيب'),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('نشط',
                          style: YaBaladiTypography.bodyMedium),
                      value: isActive,
                      onChanged: (v) {
                        setStateDialog(() => isActive = v);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('مطلوب',
                          style: YaBaladiTypography.bodyMedium),
                      value: isRequired,
                      onChanged: (v) {
                        setStateDialog(() => isRequired = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final nameAr = nameArController.text.trim();
                          final fieldKey = fieldKeyController.text.trim();

                          if (nameAr.isEmpty || fieldKey.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('الاسم والمفتاح مطلوبان')),
                            );
                            return;
                          }

                          setStateDialog(() => isSaving = true);

                          try {
                            final collisionSnap = await _firestore
                                .collection('review_criteria')
                                .where('fieldKey', isEqualTo: fieldKey)
                                .get();

                            bool hasCollision = false;
                            for (var d in collisionSnap.docs) {
                              if (!isEdit || d.id != doc.id) {
                                hasCollision = true;
                                break;
                              }
                            }

                            if (hasCollision) {
                              setStateDialog(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'هذا المفتاح (fieldKey) مستخدم بالفعل في معيار آخر!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            final map = {
                              'categoryId': widget.categoryId,
                              'isGeneral': false,
                              'nameAr': nameAr,
                              'nameEn': nameEnController.text.trim(),
                              'descriptionAr': descArController.text.trim(),
                              'fieldKey': fieldKey,
                              'weight':
                                  double.tryParse(weightController.text) ?? 1.0,
                              'order': int.tryParse(orderController.text) ?? 1,
                              'isActive': isActive,
                              'isRequired': isRequired,
                            };
                            if (isEdit) {
                              await _firestore
                                  .collection('review_criteria')
                                  .doc(doc.id)
                                  .update(map);
                            } else {
                              await _firestore
                                  .collection('review_criteria')
                                  .add(map);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setStateDialog(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('حدث خطأ: $e'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('معايير: ${widget.categoryName}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('review_criteria')
            .where('categoryId', isEqualTo: widget.categoryId)
            .where('isGeneral', isEqualTo: false)
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'حدث خطأ في تحميل المعايير.',
                      style: YaBaladiTypography.headingLabel,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'قد تحتاج إلى إنشاء فهرس (Index) في Firebase.\n${snapshot.error}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('لا توجد معايير خاصة. أضف معيارك الأول!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final activeLabel = data['isActive'] == true ? 'نشط' : 'معطل';
              return Card(
                child: ListTile(
                  title: Text(data['nameAr'] as String? ?? 'بدون اسم',
                      style: YaBaladiTypography.headingSubsection),
                  subtitle: Text(
                      'المفتاح: ${data['fieldKey']} | الوزن: ${data['weight']} | $activeLabel'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showDialog(doc: docs[index]),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.visibility_off, color: Colors.red),
                        tooltip: 'تعطيل المعيار',
                        onPressed: () {
                          _firestore
                              .collection('review_criteria')
                              .doc(docs[index].id)
                              .update({'isActive': false});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
