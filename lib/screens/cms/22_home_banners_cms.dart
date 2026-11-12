import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_image_picker.dart';
import '../../widgets/nexpay_ui_kit.dart';

class HomeBannersCmsScreen extends StatefulWidget {
  const HomeBannersCmsScreen({super.key});

  @override
  State<HomeBannersCmsScreen> createState() => _HomeBannersCmsScreenState();
}

class _HomeBannersCmsScreenState extends State<HomeBannersCmsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _getLiveBanners(AdminProvider admin) {
    final raw = admin.cmsConfig['homeBanners'];
    if (raw is List) {
      return raw
          .whereType()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final banners = _getLiveBanners(admin);

    final activeCount = banners
        .where((b) =>
    (b['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE')
        .length;
    final disabledCount = banners.length - activeCount;

    final filtered = banners.where((b) {
      final st = (b['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'INACTIVE' && st == 'ACTIVE') return false;
      if (_query.isEmpty) return true;
      final hay = '${b['title']} ${b['subtitle']} ${b['route']} ${b['tag']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Home Promotional Banners & Campaign Sliders',
        subtitle:
        'Upload promotional banners directly from your gallery, configure deep-link routes, and publish live',
        badgeText: '$activeCount LIVE BANNERS',
        badgeColor: AppConstants.accentGreen,
        actions: [
          OutlinedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.sync_rounded, size: 17),
            label: const Text('Sync CMS'),
          ),
          ElevatedButton.icon(
            onPressed: () => _openBannerDrawer(context, admin, banners, null),
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
            label: const Text('Add New Banner'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Active App Banners',
            value: '$activeCount Visible',
            sublabel: 'Live on customer home carousel',
            icon: Icons.view_carousel_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Paused Banners',
            value: '$disabledCount Hidden',
            sublabel: 'Saved drafts not shown in app',
            icon: Icons.visibility_off_outlined,
            color: AppConstants.textMuted,
          ),
          NexPayStatItem(
            label: 'Total Campaigns',
            value: '${banners.length} Sliders',
            sublabel: '100% live smartvest.tech config',
            icon: Icons.campaign_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Media Upload',
            value: 'Gallery Ready',
            sublabel: 'Direct PNG/JPG/WEBP upload supported',
            icon: Icons.photo_library_outlined,
            color: AppConstants.accentGold,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search banner by title, subtitle, or deep-link route...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'INACTIVE'],
        selectedFilter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        resultSummary:
        'Showing ${filtered.length} of ${banners.length} banners',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const NexPayEmptyState(
          icon: Icons.view_carousel_outlined,
          title: 'No Promotional Banners Configured',
          subtitle:
          'Click "Add New Banner" above to upload a banner image from your gallery and publish it.',
        ),
        columns: const [
          DataColumn(label: Text('BANNER PREVIEW')),
          DataColumn(label: Text('HEADLINE & SUBTITLE')),
          DataColumn(label: Text('BADGE TAG')),
          DataColumn(label: Text('TARGET ROUTE')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CONTROLS')),
        ],
        rows: filtered.map((b) {
          final imgSrc = (b['imageUrl'] ?? '').toString();
          final title = (b['title'] ?? 'Promo Banner').toString();
          final subtitle = (b['subtitle'] ?? '-').toString();
          final tag = (b['tag'] ?? 'PROMO').toString();
          final route = (b['route'] ?? '/home').toString();
          final status = (b['status'] ?? 'ACTIVE').toString().toUpperCase();

          return DataRow(
            cells: [
              DataCell(
                Container(
                  width: 110,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child:
                    NexPaySmartImage(source: imgSrc, fit: BoxFit.cover),
                  ),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppConstants.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppConstants.accentGoldLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          color: AppConstants.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              DataCell(NexPayCopyableId(text: route, label: 'App Route')),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openBannerDrawer(context, admin, banners, b),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Delete Banner',
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final confirmed = await showNexPayConfirmDialog(
                          context: context,
                          title: 'Delete Home Banner',
                          message:
                          'Remove "$title" from the live customer app home carousel?',
                          confirmLabel: 'Delete Banner',
                          confirmColor: AppConstants.dangerRed,
                          icon: Icons.delete_outline_rounded,
                        );
                        if (!confirmed || !context.mounted) return;
                        final updated = banners
                            .where((item) => item['id'] != b['id'])
                            .toList();
                        final ok = await admin
                            .saveCmsConfig({'homeBanners': updated});
                        if (context.mounted) {
                          _toast(
                              context,
                              ok
                                  ? 'Banner deleted & synced live.'
                                  : 'Delete failed.',
                              ok);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openBannerDrawer(
  BuildContext context,
  AdminProvider admin,
  List currentList,
  Map<String, dynamic>? existing,
  ) {
  final isEdit = existing != null;
  final titleCtrl =
  TextEditingController(text: (existing?['title'] ?? '').toString());
  final subtitleCtrl =
  TextEditingController(text: (existing?['subtitle'] ?? '').toString());
  final tagCtrl =
  TextEditingController(text: (existing?['tag'] ?? 'FEATURED').toString());
  final routeCtrl =
  TextEditingController(text: (existing?['route'] ?? '/gold').toString());
  String imageValue = (existing?['imageUrl'] ?? '').toString();
  bool isActive = existing == null ||
  (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

  showNexPayInspectorDrawer(
  context: context,
  width: 560,
  title: isEdit ? 'Edit Promotional Banner' : 'Create Promotional Banner',
  subtitle:
  'Upload banner artwork from gallery or provide direct image URL',
  child: StatefulBuilder(
  builder: (ctx, setDrawerState) {
  return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  NexPayImageUploader(
  label: 'Banner Artwork (Upload From Gallery / Computer)',
  initialValue: imageValue,
  previewHeight: 160,
  onChanged: (val) => imageValue = val,
  ),
  const SizedBox(height: 16),
  TextField(
  controller: titleCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration:
  const InputDecoration(labelText: 'Banner Headline Title'),
  ),
  const SizedBox(height: 14),
  TextField(
  controller: subtitleCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration:
  const InputDecoration(labelText: 'Promotional Subtitle'),
  ),
  const SizedBox(height: 14),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: tagCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Pill Tag (e.g. 24K GOLD)'),
  ),
  ),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: routeCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'App Deep-Link Route'),
  ),
  ),
  ],
  ),
  const SizedBox(height: 16),
  SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: Text('Publish Banner Live in Customer App',
  style: TextStyle(
  color: AppConstants.textPrimary,
  fontWeight: FontWeight.w600,
  fontSize: 13.5)),
  value: isActive,
  activeThumbColor: AppConstants.accentGreen,
  onChanged: (v) => setDrawerState(() => isActive = v),
  ),
  ],
  );
  },
  ),
  footerActions: [
  OutlinedButton(
  onPressed: () => Navigator.pop(context),
  child: const Text('Cancel')),
  ElevatedButton.icon(
  onPressed: () async {
  final title = titleCtrl.text.trim();
  if (title.isEmpty) {
  _toast(context, 'Banner headline title is required.', false);
  return;
  }
  Navigator.pop(context);
  final bannerObj = {
  'id': isEdit
  ? existing['id']
      : 'banner_${DateTime.now().millisecondsSinceEpoch}',
  'title': title,
  'subtitle': subtitleCtrl.text.trim(),
  'tag':
  tagCtrl.text.trim().isEmpty ? 'PROMO' : tagCtrl.text.trim(),
  'route': routeCtrl.text.trim(),
  'imageUrl': imageValue,
  'status': isActive ? 'ACTIVE' : 'INACTIVE',
  };
  final updated = List.from(currentList);
  if (isEdit) {
  final idx = updated.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) {
  updated[idx] = bannerObj;
  } else {
  updated.add(bannerObj);
  }
  } else {
  updated.add(bannerObj);
  }
  final ok = await admin.saveCmsConfig({'homeBanners': updated});
  if (context.mounted) {
  _toast(
  context,
  ok ? 'Home banner published live!' : 'Save failed.',
  ok);
  }
  },
  icon: const Icon(Icons.publish_rounded, size: 17),
  label: const Text('Save & Publish Banner'),
  ),
  ],
  );
  }

  void _toast(BuildContext context, String msg, bool ok) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  content: Text(msg),
  backgroundColor:
  ok ? AppConstants.accentGreen : AppConstants.dangerRed),
  );
  }
}