import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class SavingsTiersCmsScreen extends StatefulWidget {
  const SavingsTiersCmsScreen({super.key});

  @override
  State<SavingsTiersCmsScreen> createState() => _SavingsTiersCmsScreenState();
}

class _SavingsTiersCmsScreenState extends State<SavingsTiersCmsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List> _list(AdminProvider admin) {
    final raw = admin.cmsConfig['savingsTiers'];
    return raw is List ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final items = _list(admin);
    final filtered = items.where((t) {
      final st = (t['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'DISABLED' && st == 'ACTIVE') return false;
      if (_query.isEmpty) return true;
      return '${t['name']} ${t['shariahBadge']}'.toLowerCase().contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Shariah-Compliant Halal Savings Tiers & Mudarabah ROI',
        subtitle: 'Configure locked term vault durations, expected annual profit rates, and minimum deposit slabs',
        badgeText: '${items.length} SAVINGS TIERS',
        badgeColor: AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openDrawer(context, admin, items, null),
            icon: const Icon(Icons.add_chart_rounded, size: 17),
            label: const Text('Add Savings Tier'),
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
        emptyState: const InstitutionalEmptyState(
          icon: Icons.savings_outlined,
          title: 'No Savings Tiers Configured',
          subtitle: 'Click "Add Savings Tier" above to publish Halal Mudarabah vault plans.',
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
          return DataRow(
            cells: [
              DataCell(Text((t['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text('${t['annualRate'] ?? 0}% p.a.', style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGreen))),
              DataCell(Text((t['durationLabel'] ?? '${t['lockDurationDays'] ?? 30} Days').toString())),
              DataCell(Text('Rs. ${t['minDeposit'] ?? 1000}', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text((t['shariahBadge'] ?? 'Mudarabah Certified').toString(), style: const TextStyle(fontSize: 12))),
              DataCell(NexPayStatusBadge(status: (t['status'] ?? 'ACTIVE').toString())),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(onPressed: () => _openDrawer(context, admin, items, t), child: const Text('Edit')),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final updated = items.where((x) => x['id'] != t['id']).toList();
                        await admin.saveCmsConfig({'savingsTiers': updated});
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

  void _openDrawer(BuildContext context, AdminProvider admin, List> items, Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: (existing?['name'] ?? '').toString());
    final rateCtrl = TextEditingController(text: (existing?['annualRate'] ?? '14.5').toString());
    final daysCtrl = TextEditingController(text: (existing?['lockDurationDays'] ?? '90').toString());
    final labelCtrl = TextEditingController(text: (existing?['durationLabel'] ?? '3 Months Lock').toString());
    final minCtrl = TextEditingController(text: (existing?['minDeposit'] ?? '5000').toString());
    final freqCtrl = TextEditingController(text: (existing?['payoutFrequency'] ?? 'At Maturity').toString());
    final badgeCtrl = TextEditingController(text: (existing?['shariahBadge'] ?? 'Shariah Supervisory Approved').toString());
    final descCtrl = TextEditingController(text: (existing?['description'] ?? '').toString());
    bool active = existing == null || (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

    showNexPayInspectorDrawer(
      context: context,
      title: isEdit ? 'Edit Savings Tier' : 'Create Halal Savings Tier',
      subtitle: 'Configure Mudarabah profit rate and lock-in period',
      child: StatefulBuilder(
        builder: (ctx, setS) => Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Savings Plan Name')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Expected Annual ROI (%)', suffixText: '%'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lock Days'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Duration Label (e.g. 90 Days)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Deposit (PKR)', prefixText: 'Rs. '))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: freqCtrl, decoration: const InputDecoration(labelText: 'Payout Frequency (Monthly / At Maturity)')),
            const SizedBox(height: 12),
            TextField(controller: badgeCtrl, decoration: const InputDecoration(labelText: 'Shariah Compliance Badge')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Plan Summary')),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tier Active for Subscriptions', style: TextStyle(fontWeight: FontWeight.w600)),
              value: active,
              activeThumbColor: AppConstants.accentGreen,
              onChanged: (v) => setS(() => active = v),
            ),
          ],
        ),
      ),
      footerActions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            Navigator.pop(context);
            final obj = {
              'id': isEdit ? existing['id'] : 'tier_${DateTime.now().millisecondsSinceEpoch}',
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
            final updated = List>.from(items);
            if (isEdit) {
              final idx = updated.indexWhere((x) => x['id'] == existing['id']);
              if (idx != -1) updated[idx] = obj;
            } else {
              updated.add(obj);
            }
            await admin.saveCmsConfig({'savingsTiers': updated});
          },
          child: const Text('Save Tier'),
        ),
      ],
    );
  }
}