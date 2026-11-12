import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class SavingsTiersCmsScreen extends StatefulWidget {
  const SavingsTiersCmsScreen({super.key});

  @override
  State<SavingsTiersCmsScreen> createState() => _SavingsTiersCmsScreenState();
}

class _SavingsTiersCmsScreenState extends State<SavingsTiersCmsScreen> {
  final _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _list(AdminProvider admin) {
    final raw = admin.cmsConfig['savingsTiers'];
    return raw is List
        ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final items = _list(admin);
    final activeCount = items
        .where((t) =>
    (t['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE')
        .length;
    double maxRoi = 0;
    for (final t in items) {
      final r = double.tryParse(t['annualRate']?.toString() ?? '0') ?? 0;
      if (r > maxRoi) maxRoi = r;
    }

    final filtered = items.where((t) {
      final st = (t['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'DISABLED' && st == 'ACTIVE') return false;
      if (_query.isEmpty) return true;
      return '${t['name']} ${t['shariahBadge']}'
          .toLowerCase()
          .contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Shariah-Compliant Halal Savings Tiers & Mudarabah ROI',
        subtitle:
        'Configure locked term vault durations, expected annual profit rates, and minimum deposit slabs',
        badgeText: '$activeCount ACTIVE TIERS',
        badgeColor: AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openDrawer(context, admin, items, null),
            icon: const Icon(Icons.add_chart_rounded, size: 17),
            label: const Text('Add Savings Tier'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Configured Vault Tiers',
            value: '${items.length} Plans',
            sublabel: '$activeCount active for customer lock-in',
            icon: Icons.savings_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Peak Mudarabah Rate',
            value: '${maxRoi.toStringAsFixed(1)}% p.a.',
            sublabel: 'Highest advertised annual return',
            icon: Icons.trending_up_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Profit Structure',
            value: 'Shariah Pool',
            sublabel: 'Halal Mudarabah profit distribution',
            icon: Icons.verified_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Settlement Engine',
            value: 'Automated',
            sublabel: 'Credited on vault maturity date',
            icon: Icons.lock_clock_rounded,
            color: AppConstants.accentGreen,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search savings tier name...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'DISABLED'],
        selectedFilter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        resultSummary: 'Showing ${filtered.length} of ${items.length} tiers',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const NexPayEmptyState(
          icon: Icons.savings_outlined,
          title: 'No Savings Tiers Configured',
          subtitle:
          'Click "Add Savings Tier" above to publish Halal Mudarabah vault plans.',
        ),
        columns: const [
          DataColumn(label: Text('TIER NAME')),
          DataColumn(label: Text('EXPECTED ANNUAL ROI')),
          DataColumn(label: Text('LOCK DURATION')),
          DataColumn(label: Text('MIN DEPOSIT')),
          DataColumn(label: Text('SHARIAH CERTIFICATE')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CONTROLS')),
        ],
        rows: filtered.map((t) {
          final name = (t['name'] ?? '').toString();
          return DataRow(
            cells: [
              DataCell(Text(name,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700))),
              DataCell(Text('${t['annualRate'] ?? 0}% p.a.',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentGreen))),
              DataCell(Text(
                  (t['durationLabel'] ?? '${t['lockDurationDays'] ?? 30} Days')
                      .toString(),
                  style: TextStyle(color: AppConstants.textPrimary))),
              DataCell(Text('Rs. ${t['minDeposit'] ?? 1000}',
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600))),
              DataCell(Text(
                  (t['shariahBadge'] ?? 'Mudarabah Certified').toString(),
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 12))),
              DataCell(
                  NexPayStatusBadge(status: (t['status'] ?? 'ACTIVE').toString())),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                        onPressed: () => _openDrawer(context, admin, items, t),
                        child: const Text('Edit')),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Delete Tier',
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final confirmed = await showNexPayConfirmDialog(
                          context: context,
                          title: 'Delete Savings Tier',
                          message:
                          'Remove "$name" from available customer savings plans?',
                          confirmLabel: 'Delete Tier',
                          confirmColor: AppConstants.dangerRed,
                        );
                        if (!confirmed || !context.mounted) return;
                        final updated =
                        items.where((x) => x['id'] != t['id']).toList();
                        final ok =
                        await admin.saveCmsConfig({'savingsTiers': updated});
                        if (context.mounted) {
                          _toast(context, ok ? 'Savings tier deleted.' : 'Delete failed.',
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

  void _openDrawer(BuildContext context, AdminProvider admin,
  List items, Map<String, dynamic>? existing) {
  final isEdit = existing != null;
  final nameCtrl =
  TextEditingController(text: (existing?['name'] ?? '').toString());
  final rateCtrl = TextEditingController(
  text: (existing?['annualRate'] ?? '14.5').toString());
  final daysCtrl = TextEditingController(
  text: (existing?['lockDurationDays'] ?? '90').toString());
  final labelCtrl = TextEditingController(
  text: (existing?['durationLabel'] ?? '3 Months Lock').toString());
  final minCtrl = TextEditingController(
  text: (existing?['minDeposit'] ?? '5000').toString());
  final freqCtrl = TextEditingController(
  text: (existing?['payoutFrequency'] ?? 'At Maturity').toString());
  final badgeCtrl = TextEditingController(
  text: (existing?['shariahBadge'] ?? 'Shariah Supervisory Approved')
      .toString());
  final descCtrl = TextEditingController(
  text: (existing?['description'] ?? '').toString());
  bool active = existing == null ||
  (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

  showNexPayInspectorDrawer(
  context: context,
  title: isEdit ? 'Edit Savings Tier' : 'Create Halal Savings Tier',
  subtitle: 'Configure Mudarabah profit rate and lock-in period',
  child: StatefulBuilder(
  builder: (ctx, setS) {
  final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
  final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
  final sampleProfit = 100000 * (rate / 100) * (days / 365);

  return Column(
  children: [
  TextField(
  controller: nameCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration:
  const InputDecoration(labelText: 'Savings Plan Name')),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: rateCtrl,
  onChanged: (_) => setS(() {}),
  keyboardType: TextInputType.number,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Expected Annual ROI (%)',
  suffixText: '%'))),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: daysCtrl,
  onChanged: (_) => setS(() {}),
  keyboardType: TextInputType.number,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration:
  const InputDecoration(labelText: 'Lock Days'))),
  ],
  ),
  const SizedBox(height: 12),
  Container(
  width: double.infinity,
  padding:
  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppConstants.borderColor),
  ),
  child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text('Sample Profit on Rs. 100,000 ($days days):',
  style: TextStyle(
  color: AppConstants.textMuted, fontSize: 12)),
  Text(
  '+Rs. ${_money.format(sampleProfit)}',
  style: TextStyle(
  color: AppConstants.accentGreen,
  fontSize: 13.5,
  fontWeight: FontWeight.w700),
  ),
  ],
  ),
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: labelCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Duration Label (e.g. 90 Days)'))),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: minCtrl,
  keyboardType: TextInputType.number,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Min Deposit (PKR)',
  prefixText: 'Rs. '))),
  ],
  ),
  const SizedBox(height: 12),
  TextField(
  controller: freqCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText:
  'Payout Frequency (Monthly / At Maturity)')),
  const SizedBox(height: 12),
  TextField(
  controller: badgeCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Shariah Compliance Badge')),
  const SizedBox(height: 12),
  TextField(
  controller: descCtrl,
  maxLines: 2,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(labelText: 'Plan Summary')),
  const SizedBox(height: 14),
  SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: Text('Tier Active for Subscriptions',
  style: TextStyle(
  color: AppConstants.textPrimary,
  fontWeight: FontWeight.w600)),
  value: active,
  activeThumbColor: AppConstants.accentGreen,
  onChanged: (v) => setS(() => active = v),
  ),
  ],
  );
  },
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
      : 'tier_${DateTime.now().millisecondsSinceEpoch}',
  'name': nameCtrl.text.trim(),
  'annualRate': double.tryParse(rateCtrl.text.trim()) ?? 12.0,
  'lockDurationDays': int.tryParse(daysCtrl.text.trim()) ?? 30,
  'durationLabel': labelCtrl.text.trim(),
  'minDeposit': double.tryParse(minCtrl.text.trim()) ?? 5000,
  'payoutFrequency': freqCtrl.text.trim(),
  'shariahBadge': badgeCtrl.text.trim(),
  'description': descCtrl.text.trim(),
  'status': active ? 'ACTIVE' : 'DISABLED',
  };
  final updated = List.from(items);
  if (isEdit) {
  final idx = updated.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updated[idx] = obj;
  } else {
  updated.add(obj);
  }
  final ok = await admin.saveCmsConfig({'savingsTiers': updated});
  if (context.mounted) {
  _toast(context, ok ? 'Savings tier saved live!' : 'Save failed.',
  ok);
  }
  },
  child: const Text('Save Tier'),
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