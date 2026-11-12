import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class TelecomPackagesCmsScreen extends StatefulWidget {
  const TelecomPackagesCmsScreen({super.key});

  @override
  State<TelecomPackagesCmsScreen> createState() => _TelecomPackagesCmsScreenState();
}

class _TelecomPackagesCmsScreenState extends State<TelecomPackagesCmsScreen> {
  final _searchCtrl = TextEditingController();
  String _network = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _list(AdminProvider admin) {
    final raw = admin.cmsConfig['telecomPackages'];
    return raw is List ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final items = _list(admin);
    final filtered = items.where((p) {
      final net = (p['network'] ?? '').toString().toUpperCase();
      if (_network != 'ALL' && net != _network) return false;
      if (_query.isEmpty) return true;
      return '${p['name']} $net ${p['data']}'.toLowerCase().contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Telecom Mobile Bundles & EasyLoad Catalog',
        subtitle: 'Configure Jazz, Zong, Telenor, and Ufone data/call packages in the live customer app',
        badgeText: '${items.length} PACKAGES',
        badgeColor: AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openDrawer(context, admin, items, null),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Add Telecom Bundle'),
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search bundle name, network, or GB data...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'JAZZ', 'ZONG', 'TELENOR', 'UFONE'],
        selectedFilter: _network,
        onFilterChanged: (f) => setState(() => _network = f),
        resultSummary: 'Showing ${filtered.length} of ${items.length} bundles',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.signal_cellular_alt_rounded,
          title: 'No Telecom Bundles Configured',
          subtitle: 'Click "Add Telecom Bundle" above to publish Jazz, Zong, Telenor, or Ufone offers.',
        ),
        columns: const [
          DataColumn(label: Text('NETWORK')),
          DataColumn(label: Text('BUNDLE NAME')),
          DataColumn(label: Text('DATA / MINS / SMS')),
          DataColumn(label: Text('VALIDITY')),
          DataColumn(label: Text('PRICE (PKR)'), numeric: true),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CONTROLS')),
        ],
        rows: filtered.map((p) {
          return DataRow(
            cells: [
              DataCell(Text((p['network'] ?? 'JAZZ').toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentBlue))),
              DataCell(Text((p['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text('${p['data'] ?? '-'} • ${p['onNet'] ?? '-'} On-Net • ${p['offNet'] ?? '-'} Off-Net', style: const TextStyle(fontSize: 12))),
              DataCell(Text((p['validity'] ?? '30 Days').toString())),
              DataCell(Text('Rs. ${p['price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGreen))),
              DataCell(NexPayStatusBadge(status: (p['status'] ?? 'ACTIVE').toString())),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(onPressed: () => _openDrawer(context, admin, items, p), child: const Text('Edit')),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final updated = items.where((x) => x['id'] != p['id']).toList();
                        await admin.saveCmsConfig({'telecomPackages': updated});
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

  void _openDrawer(BuildContext context, AdminProvider admin, List items, Map<String, dynamic>? existing) {
  final isEdit = existing != null;
  final netCtrl = TextEditingController(text: (existing?['network'] ?? 'JAZZ').toString());
  final nameCtrl = TextEditingController(text: (existing?['name'] ?? '').toString());
  final validCtrl = TextEditingController(text: (existing?['validity'] ?? '30 Days').toString());
  final priceCtrl = TextEditingController(text: (existing?['price'] ?? '').toString());
  final dataCtrl = TextEditingController(text: (existing?['data'] ?? '25 GB').toString());
  final onNetCtrl = TextEditingController(text: (existing?['onNet'] ?? '1000').toString());
  final offNetCtrl = TextEditingController(text: (existing?['offNet'] ?? '250').toString());
  final smsCtrl = TextEditingController(text: (existing?['sms'] ?? '1000').toString());
  bool active = existing == null || (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

  showNexPayInspectorDrawer(
  context: context,
  title: isEdit ? 'Edit Telecom Bundle' : 'Add Telecom Bundle',
  subtitle: 'Configure network package quotas and retail price',
  child: StatefulBuilder(
  builder: (ctx, setS) => Column(
  children: [
  Row(
  children: [
  Expanded(child: TextField(controller: netCtrl, decoration: const InputDecoration(labelText: 'Network (JAZZ/ZONG/TELENOR/UFONE)'))),
  const SizedBox(width: 12),
  Expanded(child: TextField(controller: validCtrl, decoration: const InputDecoration(labelText: 'Validity (e.g. 30 Days)'))),
  ],
  ),
  const SizedBox(height: 12),
  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Package Title')),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (PKR)', prefixText: 'Rs. '))),
  const SizedBox(width: 12),
  Expanded(child: TextField(controller: dataCtrl, decoration: const InputDecoration(labelText: 'Internet Data (e.g. 30 GB)'))),
  ],
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(child: TextField(controller: onNetCtrl, decoration: const InputDecoration(labelText: 'On-Net Mins'))),
  const SizedBox(width: 12),
  Expanded(child: TextField(controller: offNetCtrl, decoration: const InputDecoration(labelText: 'Off-Net Mins'))),
  const SizedBox(width: 12),
  Expanded(child: TextField(controller: smsCtrl, decoration: const InputDecoration(labelText: 'SMS'))),
  ],
  ),
  const SizedBox(height: 14),
  SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('Package Active', style: TextStyle(fontWeight: FontWeight.w600)),
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
  'id': isEdit ? existing['id'] : 'tel_${DateTime.now().millisecondsSinceEpoch}',
  'network': netCtrl.text.trim().toUpperCase(),
  'name': nameCtrl.text.trim(),
  'validity': validCtrl.text.trim(),
  'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
  'data': dataCtrl.text.trim(),
  'onNet': onNetCtrl.text.trim(),
  'offNet': offNetCtrl.text.trim(),
  'sms': smsCtrl.text.trim(),
  'status': active ? 'ACTIVE' : 'DISABLED',
  };
  final updated = List.from(items);
  if (isEdit) {
  final idx = updated.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updated[idx] = obj;
  } else {
  updated.add(obj);
  }
  await admin.saveCmsConfig({'telecomPackages': updated});
  },
  child: const Text('Save Package'),
  ),
  ],
  );
  }
}