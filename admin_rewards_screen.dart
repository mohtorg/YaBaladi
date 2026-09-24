// screens/admin/admin_rewards_screen.dart
// إدارة كتالوج المكافآت للأدمن.
// الأدمن يعرّف المكافأة وشروطها، لكنه لا يعدّل أرصدة المستخدمين من هذه الشاشة.
// هذا الفصل مهم أمنيًا لأن رصيد النقاط قيمة قابلة للاستغلال.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/locale_controller.dart';
import '../../l10n/app_strings.dart';
import '../../models/reward_model.dart';

class AdminRewardsScreen extends StatelessWidget {
  const AdminRewardsScreen({super.key});

  Future<void> _openEditor(BuildContext context, {Reward? reward}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RewardDialog(reward: reward),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of('admin_rewards', lang)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('rewards').orderBy('pointsCost').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return Center(child: Text(AppStrings.of('no_rewards', lang)));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final reward = Reward.fromMap(docs[index].id, docs[index].data());
              return Card(
                child: ListTile(
                  leading: Icon(reward.active ? Icons.card_giftcard : Icons.block),
                  title: Text(reward.nameFor(lang)),
                  subtitle: Text('${reward.pointsCost} ${AppStrings.of('points', lang)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openEditor(context, reward: reward),
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

class _RewardDialog extends StatefulWidget {
  final Reward? reward;
  const _RewardDialog({this.reward});

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameAr;
  late final TextEditingController _nameEn;
  late final TextEditingController _descAr;
  late final TextEditingController _descEn;
  late final TextEditingController _cost;
  late final TextEditingController _coupon;
  late final TextEditingController _placeId;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.reward;
    _nameAr = TextEditingController(text: r?.nameAr ?? '');
    _nameEn = TextEditingController(text: r?.nameEn ?? '');
    _descAr = TextEditingController(text: r?.descriptionAr ?? '');
    _descEn = TextEditingController(text: r?.descriptionEn ?? '');
    _cost = TextEditingController(text: r?.pointsCost.toString() ?? '');
    _coupon = TextEditingController(text: r?.couponCode ?? '');
    _placeId = TextEditingController(text: r?.placeId ?? '');
    _active = r?.active ?? true;
  }

  @override
  void dispose() {
    _nameAr.dispose(); _nameEn.dispose(); _descAr.dispose(); _descEn.dispose();
    _cost.dispose(); _coupon.dispose(); _placeId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cost = int.tryParse(_cost.text.trim());
    if (cost == null || cost <= 0) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'nameAr': _nameAr.text.trim(),
        'nameEn': _nameEn.text.trim(),
        'descriptionAr': _descAr.text.trim(),
        'descriptionEn': _descEn.text.trim(),
        'pointsCost': cost,
        'couponCode': _coupon.text.trim().isEmpty ? null : _coupon.text.trim(),
        'placeId': _placeId.text.trim().isEmpty ? null : _placeId.text.trim(),
        'active': _active,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final ref = FirebaseFirestore.instance.collection('rewards');
      if (widget.reward == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await ref.add(data);
      } else {
        await ref.doc(widget.reward!.id).update(data);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    return AlertDialog(
      title: Text(AppStrings.of(widget.reward == null ? 'add_reward' : 'edit_reward', lang)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(_nameAr, 'name_ar', lang),
            _field(_nameEn, 'name_en', lang),
            _field(_descAr, 'description_ar', lang, maxLines: 2),
            _field(_descEn, 'description_en', lang, maxLines: 2),
            _field(_cost, 'points_cost', lang, keyboard: TextInputType.number),
            _field(_coupon, 'coupon_code', lang),
            _field(_placeId, 'place_id', lang),
            SwitchListTile(value: _active, onChanged: (v) => setState(() => _active = v), title: Text(AppStrings.of('active_reward', lang))),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text(AppStrings.of('cancel', lang))),
        ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppStrings.of('save', lang))),
      ],
    );
  }

  Widget _field(TextEditingController c, String key, String lang, {int maxLines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: AppStrings.of(key, lang), border: const OutlineInputBorder()),
        validator: (v) => (key == 'name_ar' || key == 'name_en' || key == 'points_cost') && (v == null || v.trim().isEmpty) ? AppStrings.of('required_field', lang) : null,
      ),
    );
  }
}
