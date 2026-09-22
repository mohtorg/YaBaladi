import 'package:flutter/material.dart';
import '../../models/governorate_control.dart';
import '../../services/governorate_control_service.dart';

class AdminGovernoratesScreen extends StatefulWidget {
  const AdminGovernoratesScreen({super.key});

  @override
  State<AdminGovernoratesScreen> createState() => _AdminGovernoratesScreenState();
}

class _AdminGovernoratesScreenState extends State<AdminGovernoratesScreen> {
  final _service = GovernorateControlService();
  final Set<String> _selected = {};
  bool _initialized = false;

  Future<void> _ensureDefaults() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _service.ensureDefaults();
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> _bulkAction(List<GovernorateControl> all) async {
    if (_selected.isEmpty) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('تطبيق على المحافظات المحددة', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.power), title: const Text('تفعيل المحافظة'), onTap: () => Navigator.pop(context, 'enable')),
          ListTile(leading: const Icon(Icons.power_off), title: const Text('تعطيل المحافظة'), onTap: () => Navigator.pop(context, 'disable')),
          ListTile(leading: const Icon(Icons.visibility), title: const Text('إظهار المحافظة'), onTap: () => Navigator.pop(context, 'show')),
          ListTile(leading: const Icon(Icons.visibility_off), title: const Text('إخفاء المحافظة'), onTap: () => Navigator.pop(context, 'hide')),
          ListTile(leading: const Icon(Icons.settings), title: const Text('تغيير حالة التشغيل'), onTap: () => Navigator.pop(context, 'status')),
          ListTile(leading: const Icon(Icons.extension), title: const Text('إدارة وظائف المحافظة'), onTap: () => Navigator.pop(context, 'feature')),
        ]),
      ),
    );
    if (action == null || !mounted) return;

    try {
      if (action == 'enable') await _service.updateGovernorates(governorateIds: _selected, enabled: true, status: GovernorateStatus.active);
      if (action == 'disable') await _service.updateGovernorates(governorateIds: _selected, enabled: false);
      if (action == 'show') await _service.updateGovernorates(governorateIds: _selected, visible: true);
      if (action == 'hide') await _service.updateGovernorates(governorateIds: _selected, visible: false);
      if (action == 'status') await _chooseStatus();
      if (action == 'feature') await _chooseFeature();
      if (!mounted) return;
      setState(() => _selected.clear());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تطبيق العملية بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
    }
  }

  Future<void> _chooseStatus() async {
    final status = await showDialog<GovernorateStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('حالة التشغيل'),
        children: GovernorateStatus.values.map((status) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, status),
          child: Text(_statusLabel(status)),
        )).toList(),
      ),
    );
    if (status != null) await _service.updateGovernorates(governorateIds: _selected, status: status);
  }

  Future<void> _chooseFeature() async {
    final feature = await showDialog<GovernorateFeatureDefinition>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('اختر الوظيفة'),
        children: GovernorateControlService.featureDefinitions.map((f) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, f),
          child: Text(f.nameAr),
        )).toList(),
      ),
    );
    if (feature == null || !mounted) return;
    final state = await showDialog<FeatureState>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('حالة ${feature.nameAr}'),
        children: [
          for (final state in [FeatureState.inherit, FeatureState.enabled, FeatureState.disabled, FeatureState.visible, FeatureState.hidden, FeatureState.comingSoon, FeatureState.maintenance])
            SimpleDialogOption(onPressed: () => Navigator.pop(context, state), child: Text(_featureStateLabel(state))),
        ],
      ),
    );
    if (state != null) await _service.setFeatureState(governorateIds: _selected, featureId: feature.id, state: state);
  }

  String _statusLabel(GovernorateStatus s) => switch (s) {
    GovernorateStatus.draft => 'مسودة',
    GovernorateStatus.preparing => 'قيد التجهيز',
    GovernorateStatus.active => 'نشطة',
    GovernorateStatus.suspended => 'موقوفة',
    GovernorateStatus.maintenance => 'صيانة',
  };

  String _featureStateLabel(FeatureState s) => switch (s) {
    FeatureState.inherit => 'الافتراضي العام',
    FeatureState.enabled => 'مفعّل',
    FeatureState.disabled => 'معطّل',
    FeatureState.visible => 'ظاهر',
    FeatureState.hidden => 'مخفي',
    FeatureState.comingSoon => 'قريبًا',
    FeatureState.maintenance => 'صيانة',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المحافظات'),
        actions: [
          IconButton(onPressed: () => setState(() => _selected.clear()), icon: const Icon(Icons.clear_all)),
        ],
      ),
      body: StreamBuilder<List<GovernorateControl>>(
        stream: _service.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final all = snapshot.data ?? const <GovernorateControl>[];
          WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDefaults());
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(child: Text('المحدد: ${_selected.length} من ${all.length}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    TextButton(onPressed: all.isEmpty ? null : () => setState(() => _selected.addAll(all.map((e) => e.id))), child: const Text('تحديد الكل')),
                    FilledButton.icon(onPressed: _selected.isEmpty ? null : () => _bulkAction(all), icon: const Icon(Icons.tune), label: const Text('إجراء جماعي')),
                  ]),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: all.length,
                itemBuilder: (context, index) {
                  final gov = all[index];
                  final selected = _selected.contains(gov.id);
                  return Card(
                    child: ListTile(
                      leading: Checkbox(value: selected, onChanged: (v) => setState(() => v == true ? _selected.add(gov.id) : _selected.remove(gov.id))),
                      title: Text(gov.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${_statusLabel(gov.status)} • ${gov.enabled ? 'مفعّلة' : 'معطّلة'} • ${gov.visible ? 'ظاهرة' : 'مخفية'}'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GovernorateControlCenterScreen(governorate: gov))),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class GovernorateControlCenterScreen extends StatefulWidget {
  final GovernorateControl governorate;
  const GovernorateControlCenterScreen({super.key, required this.governorate});

  @override
  State<GovernorateControlCenterScreen> createState() => _GovernorateControlCenterScreenState();
}

class _GovernorateControlCenterScreenState extends State<GovernorateControlCenterScreen> {
  final _service = GovernorateControlService();
  late bool _enabled;
  late bool _visible;
  late GovernorateStatus _status;

  @override
  void initState() {
    super.initState();
    _enabled = widget.governorate.enabled;
    _visible = widget.governorate.visible;
    _status = widget.governorate.status;
  }

  String _statusLabel(GovernorateStatus s) => switch (s) {
    GovernorateStatus.draft => 'مسودة',
    GovernorateStatus.preparing => 'قيد التجهيز',
    GovernorateStatus.active => 'نشطة',
    GovernorateStatus.suspended => 'موقوفة',
    GovernorateStatus.maintenance => 'صيانة',
  };

  String _featureStateLabel(FeatureState s) => switch (s) {
    FeatureState.inherit => 'الافتراضي العام',
    FeatureState.enabled => 'مفعّل',
    FeatureState.disabled => 'معطّل',
    FeatureState.visible => 'ظاهر',
    FeatureState.hidden => 'مخفي',
    FeatureState.comingSoon => 'قريبًا',
    FeatureState.maintenance => 'صيانة',
  };

  Future<void> _setFeature(String id, FeatureState current) async {
    final state = await showDialog<FeatureState>(context: context, builder: (context) => SimpleDialog(
      title: const Text('تحديد الحالة'),
      children: FeatureState.values.map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(context, s), child: Text(_featureStateLabel(s)))).toList(),
    ));
    if (state != null) await _service.setFeatureState(governorateIds: [widget.governorate.id], featureId: id, state: state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تحكم ${widget.governorate.nameAr}')),
      body: StreamBuilder<Map<String, FeatureState>>(
        stream: _service.watchFeatureOverrides(widget.governorate.id),
        builder: (context, snapshot) {
          final overrides = snapshot.data ?? const {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.governorate.nameAr, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<GovernorateStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'حالة التشغيل'),
                  items: GovernorateStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(_statusLabel(status)))).toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    await _service.updateGovernorates(governorateIds: [widget.governorate.id], status: value);
                    if (mounted) setState(() => _status = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تفعيل المحافظة'),
                  subtitle: const Text('عند التعطيل لا تظهر المحافظة للمستخدمين.'),
                  value: _enabled,
                  onChanged: (value) async {
                    await _service.updateGovernorates(governorateIds: [widget.governorate.id], enabled: value);
                    if (mounted) setState(() => _enabled = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إظهار المحافظة'),
                  subtitle: const Text('يفصل الظهور عن حالة التشغيل لإتاحة الإخفاء المؤقت.'),
                  value: _visible,
                  onChanged: (value) async {
                    await _service.updateGovernorates(governorateIds: [widget.governorate.id], visible: value);
                    if (mounted) setState(() => _visible = value);
                  },
                ),
              ]))),
              const SizedBox(height: 16),
              const Text('وظائف المحافظة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...GovernorateControlService.featureDefinitions.map((feature) {
                final state = overrides[feature.id] ?? FeatureState.inherit;
                return Card(child: ListTile(
                  title: Text(feature.nameAr),
                  subtitle: Text(_featureStateLabel(state)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _setFeature(feature.id, state),
                ));
              }),
              const SizedBox(height: 16),
              Card(child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('مبدأ التحكم'),
                subtitle: const Text('الإعداد المحلي يتغلب على الافتراضي العام فقط عند وجود Override؛ ويمكن إعادته إلى الافتراضي في أي وقت.'),
              )),
            ],
          );
        },
      ),
    );
  }
}
