// screens/library_screen.dart
// مكتبة يا بلدي: واجهة هادئة للاستكشاف الثقافي والبصري.
// لا نكرر وظائف places؛ المكتبة تجمع القصص والصور والفيديو والتراث والمواد المرتبطة بالرحلات.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/library_content.dart';
import '../services/library_content_service.dart';
import '../theme/app_colors.dart';

class LibraryScreen extends StatefulWidget {
  final String governorateId;
  const LibraryScreen({super.key, this.governorateId = 'port_said'});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? _selectedType;
  late Future<List<LibraryContent>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = LibraryContentService().getPublished(
      governorateId: widget.governorateId,
      contentType: _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة يا بلدي'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_reload),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            const Text('من مصر إلى كل محافظة', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('صور وحكايات ومعالم وأطعمة وتراث وفعاليات ومواد تساعدك على اكتشاف المكان بهدوء.', style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'الكل', selected: _selectedType == null, onTap: () => _setType(null)),
                  ...LibraryContentType.all.map((type) => _FilterChip(
                    label: LibraryContentType.labelAr(type),
                    selected: _selectedType == type,
                    onTap: () => _setType(type),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<LibraryContent>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return _StateCard(text: 'تعذر تحميل المكتبة حاليًا.', action: 'إعادة المحاولة', onTap: () => setState(_reload));
                }
                final items = snapshot.data ?? const <LibraryContent>[];
                if (items.isEmpty) {
                  return const _StateCard(text: 'لا توجد مواد منشورة لهذا الاختيار حاليًا.');
                }
                return Column(children: items.map(_contentCard).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setType(String? type) => setState(() { _selectedType = type; _reload(); });

  Widget _contentCard(LibraryContent item) {
    final hasImage = item.thumbnailUrl.trim().isNotEmpty || (item.contentType == LibraryContentType.image && item.mediaUrl.trim().isNotEmpty);
    final imageUrl = item.thumbnailUrl.trim().isNotEmpty ? item.thumbnailUrl : item.mediaUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.mediaUrl.isEmpty ? null : () => _openMedia(item),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (hasImage) AspectRatio(aspectRatio: 16 / 9, child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _MediaFallback())),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: Text(LibraryContentType.labelAr(item.contentType), style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w700))),
                const Spacer(),
                if (item.scope == 'national') const Icon(Icons.public, size: 18, color: AppColors.textSecondary),
              ]),
              const SizedBox(height: 8),
              Text(item.titleAr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (item.descriptionAr.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(item.descriptionAr, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
              ],
              if (item.credit.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text('المصدر/الائتمان: ${item.credit}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _openMedia(LibraryContent item) async {
    final uri = Uri.tryParse(item.mediaUrl);
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap(), selectedColor: AppColors.secondary.withValues(alpha: .16)),
  );
}

class _StateCard extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onTap;
  const _StateCard({required this.text, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.photo_library_outlined, size: 42, color: AppColors.textSecondary), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)), if (action != null) ...[const SizedBox(height: 12), TextButton(onPressed: onTap, child: Text(action!))]])));
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback();
  @override
  Widget build(BuildContext context) => Container(color: AppColors.background, child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 42, color: AppColors.textSecondary)));
}
