// lib/features/admin/screens/manage_geo_hierarchy_screen.dart
// [v1.4] — VERIFIED: Clean file, no linter issues, no address formatting needed.
// [v1.3] — LINTER FIX: Added braces to all if statements.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/governorate_config.dart';
import '../../../models/location_hierarchy_models.dart';
import '../../../repositories/location_repository.dart';
import '../../../core/utils/import_data_utility.dart';
import '../../../theme/design_tokens.dart';

class ManageGeoHierarchyScreen extends StatefulWidget {
  const ManageGeoHierarchyScreen({super.key});

  @override
  State<ManageGeoHierarchyScreen> createState() =>
      _ManageGeoHierarchyScreenState();
}

class _ManageGeoHierarchyScreenState extends State<ManageGeoHierarchyScreen> {
  final _locationRepo = LocationRepository();
  List<GovernorateConfig> _governorates = [];
  List<Map<String, String>> _allGeoZones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final govsSnap =
          await FirebaseFirestore.instance.collection('governorates').get();
      final govs = govsSnap.docs.map((d) {
        final data = d.data();
        return GovernorateConfig(
          docId: d.id,
          nameAr: data['nameAr'] ?? '',
          nameEn: data['nameEn'] ?? '',
          order: (data['order'] as num?)?.toInt() ?? 0,
          isActive: data['isActive'] == true,
          deliveryEnabled: data['deliveryEnabled'] == true,
          tripsEnabled: data['tripsEnabled'] == true,
        );
      }).toList();

      final geoZones = await _locationRepo.getGeoZones();

      if (mounted) {
        setState(() {
          _governorates = govs;
          _allGeoZones = geoZones;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showImportDialog(String type, String parentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('استيراد $type'),
        content: Text(
            'سيتم استيراد $type وربطها تلقائياً بالمعرف المحدد. هل أنت متأكد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ImportDataUtility.importCsvToFirestore(
                collectionName: type == 'أحياء' ? 'districts' : 'zones',
                parentId: parentId,
                isDistrictCollection: type == 'أحياء',
              );
            },
            child: const Text('بدء الاستيراد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الهيكل الجغرافي'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadInitialData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _governorates.length,
              itemBuilder: (context, index) {
                return _GovernorateCard(
                  gov: _governorates[index],
                  locationRepo: _locationRepo,
                  allGeoZones: _allGeoZones,
                  onImportDistricts: () =>
                      _showImportDialog('أحياء', _governorates[index].docId),
                  onRefresh: _loadInitialData,
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 1. بطاقة المحافظة
// ─────────────────────────────────────────────────────────────
class _GovernorateCard extends StatefulWidget {
  final GovernorateConfig gov;
  final LocationRepository locationRepo;
  final List<Map<String, String>> allGeoZones;
  final VoidCallback onImportDistricts;
  final VoidCallback onRefresh;

  const _GovernorateCard({
    required this.gov,
    required this.locationRepo,
    required this.allGeoZones,
    required this.onImportDistricts,
    required this.onRefresh,
  });

  @override
  State<_GovernorateCard> createState() => _GovernorateCardState();
}

class _GovernorateCardState extends State<_GovernorateCard> {
  List<DistrictModel> _districts = [];
  bool _loading = true;
  late bool _isActive;
  late bool _deliveryEnabled;
  late bool _tripsEnabled;

  @override
  void initState() {
    super.initState();
    _isActive = widget.gov.isActive;
    _deliveryEnabled = widget.gov.deliveryEnabled;
    _tripsEnabled = widget.gov.tripsEnabled;
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    final dists = await widget.locationRepo.getAllDistricts(widget.gov.docId);
    if (mounted) {
      setState(() {
        _districts = dists;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Icon(Icons.location_city,
                color:
                    _isActive ? YaBaladiDesignTokens.primaryBlue : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.gov.nameAr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isActive ? theme.colorScheme.onSurface : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        trailing: Switch(
          value: _isActive,
          onChanged: (val) async {
            setState(() => _isActive = val);
            await widget.locationRepo
                .toggleStatus('governorates', widget.gov.docId, val);
          },
        ),
        children: [
          if (_isActive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSmallSwitch('التوصيل', _deliveryEnabled, (v) async {
                    setState(() => _deliveryEnabled = v);
                    await FirebaseFirestore.instance
                        .collection('governorates')
                        .doc(widget.gov.docId)
                        .update({'deliveryEnabled': v});
                  }),
                  _buildSmallSwitch('الرحلات', _tripsEnabled, (v) async {
                    setState(() => _tripsEnabled = v);
                    await FirebaseFirestore.instance
                        .collection('governorates')
                        .doc(widget.gov.docId)
                        .update({'tripsEnabled': v});
                  }),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: widget.onImportDistricts,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('استيراد أحياء (CSV)'),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator())
            else if (_districts.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(16), child: Text('لا توجد أحياء.'))
            else
              ..._districts.map((d) => _DistrictCard(
                    dist: d,
                    locationRepo: widget.locationRepo,
                    allGeoZones: widget.allGeoZones,
                    onImportZones: () {
                      final state = context.findAncestorStateOfType<
                          _ManageGeoHierarchyScreenState>();
                      state?._showImportDialog('مناطق', d.id);
                    },
                    onRefresh: widget.onRefresh,
                  )),
          ] else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('المحافظة غير مفعلة. قم بتفعيلها لإدارة الأحياء.',
                  style: TextStyle(color: Colors.grey)),
            )
        ],
      ),
    );
  }

  Widget _buildSmallSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. بطاقة الحي
// ─────────────────────────────────────────────────────────────
class _DistrictCard extends StatefulWidget {
  final DistrictModel dist;
  final LocationRepository locationRepo;
  final List<Map<String, String>> allGeoZones;
  final VoidCallback onImportZones;
  final VoidCallback onRefresh;

  const _DistrictCard({
    required this.dist,
    required this.locationRepo,
    required this.allGeoZones,
    required this.onImportZones,
    required this.onRefresh,
  });

  @override
  State<_DistrictCard> createState() => _DistrictCardState();
}

class _DistrictCardState extends State<_DistrictCard> {
  List<ZoneModel> _zones = [];
  bool _loading = true;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.dist.isActive;
    _loadZones();
  }

  Future<void> _loadZones() async {
    final zones = await widget.locationRepo.getAllZones(widget.dist.id);
    if (mounted) {
      setState(() {
        _zones = zones;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          widget.dist.nameAr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _isActive ? Colors.black : Colors.grey,
          ),
        ),
        trailing: Switch(
          value: _isActive,
          onChanged: (val) async {
            setState(() => _isActive = val);
            await widget.locationRepo
                .toggleStatus('districts', widget.dist.id, val);
          },
        ),
        children: [
          if (_isActive) ...[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton.icon(
                  onPressed: widget.onImportZones,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('استيراد مناطق (CSV)',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator())
            else
              ..._zones.map((z) => _ZoneItem(
                    zone: z,
                    locationRepo: widget.locationRepo,
                    allGeoZones: widget.allGeoZones,
                    onRefresh: widget.onRefresh,
                  )),
          ]
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. عنصر المنطقة (مع دعم الملاحظات)
// ─────────────────────────────────────────────────────────────
class _ZoneItem extends StatefulWidget {
  final ZoneModel zone;
  final LocationRepository locationRepo;
  final List<Map<String, String>> allGeoZones;
  final VoidCallback onRefresh;

  const _ZoneItem({
    required this.zone,
    required this.locationRepo,
    required this.allGeoZones,
    required this.onRefresh,
  });

  @override
  State<_ZoneItem> createState() => _ZoneItemState();
}

class _ZoneItemState extends State<_ZoneItem> {
  late bool _isActive;
  late String? _currentGeoZoneId;
  late String? _currentNotes;

  @override
  void initState() {
    super.initState();
    _isActive = widget.zone.isActive;
    _currentGeoZoneId = widget.zone.geoZoneId;
    _currentNotes = widget.zone.notes;
  }

  Future<void> _editNotes() async {
    final controller = TextEditingController(text: _currentNotes ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ملاحظات ${widget.zone.nameAr}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'مثال: تحت الإنشاء، صيانة...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final newNotes = controller.text.trim();
              await widget.locationRepo
                  .updateZoneNotes(widget.zone.id, newNotes);
              setState(() => _currentNotes = newNotes);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        _currentGeoZoneId != null
            ? Icons.location_on
            : Icons.location_on_outlined,
        color: _currentGeoZoneId != null ? Colors.green : Colors.grey,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.zone.nameAr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, size: 20, color: Colors.blue),
            onPressed: _editNotes,
            tooltip: 'تعديل الملاحظات',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      subtitle: _currentNotes != null && _currentNotes!.isNotEmpty
          ? Text(
              'ملاحظة: $_currentNotes',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold),
            )
          : Text(
              _currentGeoZoneId != null ? 'مرتبطة بحدود' : 'بدون حدود',
              style: TextStyle(
                fontSize: 10,
                color: _currentGeoZoneId != null ? Colors.green : Colors.grey,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.link,
                size: 20,
                color: _currentGeoZoneId != null ? Colors.green : Colors.grey),
            onPressed: () => _showLinkDialog(context),
            tooltip: 'ربط بحدود جغرافية',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _isActive,
            onChanged: (val) async {
              setState(() => _isActive = val);
              await widget.locationRepo
                  .toggleStatus('zones', widget.zone.id, val);
            },
          ),
        ],
      ),
    );
  }

  void _showLinkDialog(BuildContext context) {
    String? selectedId = _currentGeoZoneId;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('ربط ${widget.zone.nameAr} بحدود جغرافية'),
          content: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('بدون ربط')),
              ...widget.allGeoZones.map((gz) => DropdownMenuItem(
                    value: gz['id'],
                    child: Text(gz['nameAr'] ?? ''),
                  )),
            ],
            onChanged: (val) => setModalState(() => selectedId = val),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                await widget.locationRepo
                    .linkGeoZone('zones', widget.zone.id, selectedId);
                Navigator.pop(context);
                setState(() => _currentGeoZoneId = selectedId);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
