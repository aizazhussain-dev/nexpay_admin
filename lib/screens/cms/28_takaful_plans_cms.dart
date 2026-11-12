import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_image_picker.dart';
import '../../widgets/nexpay_ui_kit.dart';

class TakafulPlansCmsScreen extends StatefulWidget {
  const TakafulPlansCmsScreen({super.key});

  @override
  State<TakafulPlansCmsScreen> createState() => _TakafulPlansCmsScreenState();
}

class _TakafulPlansCmsScreenState extends State<TakafulPlansCmsScreen> {
  final _searchCtrl = TextEditingController();
  final NumberFormat _compact = NumberFormat.compact(locale: 'en_US');
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _list(AdminProvider admin) {
    final raw = admin.cmsConfig['takafulPlans'];
    return raw is List
        ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final items = _list(admin);
    final activeCount = items
        .where((p) =>
    (p['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE')
        .length;
    double maxCoverage = 0;
    for (final p in items) {
      final c = double.tryParse(p['coverageAmount']?.toString() ?? '0') ?? 0;
      if (c > maxCoverage) maxCoverage = c;
    }

    final filtered = items.where((p) {
      final st = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'DISABLED' && st == 'ACTIVE') return false;
      if (_query.isEmpty) return true;
      return '${p['name']} ${p['category']} ${p['underwriter']}'
          .toLowerCase()
          .contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Islamic Takaful Protection Plans & Waqf Policies',
        subtitle:
        'Configure health, life, bike, and travel Takaful plans with gallery artwork and coverage limits',
        badgeText: '$activeCount ACTIVE PLANS',
        badgeColor: AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openDrawer(context, admin, items, null),
            icon: const Icon(Icons.add_moderator_rounded, size: 17),
            label: const Text('Add Takaful Plan'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Configured Policies',
            value: '${items.length} Plans',
            sublabel: '$activeCount active in Takaful store',
            icon: Icons.shield_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Max Coverage Ceiling',
            value: 'Rs. ${_compact.format(maxCoverage)}',
            sublabel: 'Highest single-policy Waqf cover',
            icon: Icons.health_and_safety_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Governance Model',
            value: 'Waqf Pool',
            sublabel: '100% Shariah-compliant Takaful',
            icon: Icons.verified_user_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Underwriting Partners',
            value: '${items.map((e) => e['underwriter']).toSet().length} Active',
            sublabel: 'Licensed Pakistani Takaful operators',
            icon: Icons.business_rounded,
            color: AppConstants.accentGreen,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search Takaful plan, category, or underwriter...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'DISABLED'],
        selectedFilter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        resultSummary: 'Showing ${filtered.length} of ${items.length} plans',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const NexPayEmptyState(
          icon: Icons.shield_outlined,
          title: 'No Takaful Plans Configured',
          subtitle:
          'Click "Add Takaful Plan" above to publish Shariah-compliant protection policies.',
        ),
        columns: const [
          DataColumn(label: Text('BADGE')),
          DataColumn(label: Text('PLAN NAME')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('COVERAGE LIMIT'), numeric: true),
          DataColumn(label: Text('MONTHLY / ANNUAL')),
          DataColumn(label: Text('UNDERWRITER')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CONTROLS')),
        ],
        rows: filtered.map((p) {
          final iconVal = (p['icon'] ?? '🛡️').toString();
          final isImg =
              iconVal.startsWith('data:image') || iconVal.startsWith('http');
          final name = (p['name'] ?? '').toString();
          return DataRow(
            cells: [
              DataCell(
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppConstants.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppConstants.borderColor)),
                  child: isImg
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: NexPaySmartImage(
                          source: iconVal, fit: BoxFit.cover))
                      : Text(iconVal, style: const TextStyle(fontSize: 18)),
                ),
              ),
              DataCell(Text(name,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700))),
              DataCell(Text((p['category'] ?? 'Health').toString(),
                  style: TextStyle(color: AppConstants.textSecondary))),
              DataCell(Text('Rs. ${p['coverageAmount'] ?? 0}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentGreen))),
              DataCell(Text(
                  'Rs. ${p['monthlyPremium'] ?? 0}/mo • Rs. ${p['annualPremium'] ?? 0}/yr',
                  style: TextStyle(
                      color: AppConstants.textPrimary, fontSize: 12))),
              DataCell(Text(
                  (p['underwriter'] ?? 'Pak-Qatar Takaful').toString(),
                  style: TextStyle(color: AppConstants.textSecondary))),
              DataCell(
                  NexPayStatusBadge(status: (p['status'] ?? 'ACTIVE').toString())),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                        onPressed: () => _openDrawer(context, admin, items, p),
                        child: const Text('Edit')),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Delete Plan',
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final confirmed = await showNexPayConfirmDialog(
                          context: context,
                          title: 'Delete Takaful Plan',
                          message:
                          'Remove "$name" from the live customer Takaful catalog?',
                          confirmLabel: 'Delete Plan',
                          confirmColor: AppConstants.dangerRed,
                        );
                        if (!confirmed || !context.mounted) return;
                        final updated =
                        items.where((x) => x['id'] != p['id']).toList();
                        final ok =
                        await admin.saveCmsConfig({'takafulPlans': updated});
                        if (context.mounted) {
                          _toast(context,
                              ok ? 'Takaful plan removed.' : 'Delete failed.', ok);
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

  void _openDrawer(BuildContext context, AdminProvider admin,
  List items, Map<String, dynamic>? existing) {
  final isEdit = existing != null;
  final nameCtrl =
  TextEditingController(text: (existing?['name'] ?? '').toString());
  final catCtrl = TextEditingController(
  text: (existing?['category'] ?? 'Health').toString());
  final covCtrl = TextEditingController(
  text: (existing?['coverageAmount'] ?? '500000').toString());
  final moCtrl = TextEditingController(
  text: (existing?['monthlyPremium'] ?? '499').toString());
  final yrCtrl = TextEditingController(
  text: (existing?['annualPremium'] ?? '5499').toString());
  final uwCtrl = TextEditingController(
  text: (existing?['underwriter'] ?? 'Pak-Qatar Family Takaful')
      .toString());
  final benCtrl = TextEditingController(
  text: (existing?['benefits'] ??
  '24/7 Hospitalization & Emergency Coverage')
      .toString());
  String iconVal = (existing?['icon'] ?? '🛡️').toString();
  bool active = existing == null ||
  (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

  showNexPayInspectorDrawer(
  context: context,
  title: isEdit ? 'Edit Takaful Plan' : 'Add Islamic Takaful Plan',
  subtitle: 'Upload plan badge from gallery and configure coverage limits',
  child: StatefulBuilder(
  builder: (ctx, setS) => Column(
  children: [
  NexPayImageUploader(
  label: 'Plan Icon / Badge (Upload From Gallery - Optional)',
  initialValue:
  (iconVal.startsWith('data:image') || iconVal.startsWith('http'))
  ? iconVal
      : '',
  previewHeight: 110,
  onChanged: (v) => iconVal = v.isEmpty ? '🛡️' : v,
  ),
  const SizedBox(height: 12),
  TextField(
  controller: nameCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration:
  const InputDecoration(labelText: 'Takaful Plan Name')),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: catCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Category (Health/Life/Travel)'))),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: covCtrl,
  keyboardType: TextInputType.number,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Coverage Limit (PKR)',
  prefixText: 'Rs. '))),
  ],
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: moCtrl,
  keyboardType: TextInputType.number,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Monthly Contribution',
  prefixText: 'Rs. '))),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: yrCtrl,
  keyboardType: TextInputType.number,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Annual Contribution',
  prefixText: 'Rs. '))),
  ],
  ),
  const SizedBox(height: 12),
  TextField(
  controller: uwCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Takaful Operator / Underwriter')),
  const SizedBox(height: 12),
  TextField(
  controller: benCtrl,
  maxLines: 2,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration:
  const InputDecoration(labelText: 'Key Policy Benefits')),
  const SizedBox(height: 12),
  SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: Text('Plan Active in Customer App',
  style: TextStyle(
  color: AppConstants.textPrimary,
  fontWeight: FontWeight.w600)),
  value: active,
  activeThumbColor: AppConstants.accentGreen,
  onChanged: (v) => setS(() => active = v),
  ),
  ],
  ),
  ),
  footerActions: [
  OutlinedButton(
  onPressed: () => Navigator.pop(context),
  child: const Text('Cancel')),
  ElevatedButton(
  onPressed: () async {
  if (nameCtrl.text.trim().isEmpty) return;
  Navigator.pop(context);
  final obj = {
  'id': isEdit
  ? existing['id']
      : 'tkf_${DateTime.now().millisecondsSinceEpoch}',
  'name': nameCtrl.text.trim(),
  'category': catCtrl.text.trim(),
  'coverageAmount': double.tryParse(covCtrl.text.trim()) ?? 500000,
  'monthlyPremium': double.tryParse(moCtrl.text.trim()) ?? 499,
  'annualPremium': double.tryParse(yrCtrl.text.trim()) ?? 5499,
  'underwriter': uwCtrl.text.trim(),
  'benefits': benCtrl.text.trim(),
  'icon': iconVal,
  'status': active ? 'ACTIVE' : 'DISABLED',
  };
  final updated = List.from(items);
  if (isEdit) {
  final idx = updated.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updated[idx] = obj;
  } else {
  updated.add(obj);
  }
  final ok = await admin.saveCmsConfig({'takafulPlans': updated});
  if (context.mounted) {
  _toast(context, ok ? 'Takaful plan saved live!' : 'Save failed.',
  ok);
  }
  },
  child: const Text('Save Plan'),
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