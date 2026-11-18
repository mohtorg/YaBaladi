// lib/features/admin/widgets/place_form/location_section.dart
// [v1.3] — LINTER FIX: Removed unnecessary services.dart import.

import 'package:flutter/material.dart';
import '../../../../theme/design_tokens.dart';

class LocationSection extends StatelessWidget {
  final Widget categoryDropdown;
  final Widget governorateDropdown;
  final Widget? districtDropdown; // ✅ جديد
  final Widget? zoneDropdown; // ✅ جديد
  final TextEditingController addressCtrl;
  final TextEditingController pasteUrlCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final bool isEditing;
  final bool isFetchingLocation;
  final String fetchedZoneName;
  final VoidCallback onFetchLocation;
  final VoidCallback onExtractUrl;
  final VoidCallback onPreviewMap;
  final String? Function(String?) latValidator;
  final String? Function(String?) lngValidator;
  final ThemeData theme;

  const LocationSection({
    super.key,
    required this.categoryDropdown,
    required this.governorateDropdown,
    this.districtDropdown,
    this.zoneDropdown,
    required this.addressCtrl,
    required this.pasteUrlCtrl,
    required this.latCtrl,
    required this.lngCtrl,
    required this.isEditing,
    required this.isFetchingLocation,
    required this.fetchedZoneName,
    required this.onFetchLocation,
    required this.onExtractUrl,
    required this.onPreviewMap,
    required this.latValidator,
    required this.lngValidator,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        categoryDropdown,
        const SizedBox(height: 16),
        governorateDropdown,

        // ✅ إضافة الأحياء والمناطق إذا تم تمريرها
        if (districtDropdown != null) ...[
          const SizedBox(height: 16),
          districtDropdown!,
        ],
        if (zoneDropdown != null) ...[
          const SizedBox(height: 16),
          zoneDropdown!,
        ],

        const SizedBox(height: 16),
        TextFormField(
          controller: addressCtrl,
          enabled: isEditing,
          decoration: const InputDecoration(
            labelText: 'العنوان التفصيلي (الشارع) *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
          validator: (v) => v!.isEmpty ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: latCtrl,
                enabled: isEditing,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude *',
                  border: OutlineInputBorder(),
                ),
                validator: latValidator,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: lngCtrl,
                enabled: isEditing,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude *',
                  border: OutlineInputBorder(),
                ),
                validator: lngValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (isEditing) ...[
          TextFormField(
            controller: pasteUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'لصق رابط جوجل ماب (اختياري)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExtractUrl,
                  icon: const Icon(Icons.download),
                  label: const Text('استخراج الإحداثيات'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreviewMap,
                  icon: const Icon(Icons.map),
                  label: const Text('معاينة الخريطة'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: isFetchingLocation ? null : onFetchLocation,
            icon: isFetchingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.my_location),
            label: Text(isFetchingLocation
                ? 'جارٍ جلب الموقع...'
                : 'جلب الموقع الحالي (GPS)'),
            style: FilledButton.styleFrom(
                backgroundColor: YaBaladiDesignTokens.navy),
          ),
        ],

        if (fetchedZoneName.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'المنطقة الجغرافية المكتشفة: $fetchedZoneName',
                    style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
