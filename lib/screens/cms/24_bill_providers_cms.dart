import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_image_picker.dart';
import '../../widgets/nexpay_ui_kit.dart';

class BillProvidersCmsScreen extends StatefulWidget {
  const BillProvidersCmsScreen({super.key});

  @override
  State<BillProvidersCmsScreen> createState() => _BillProvidersCmsScreenState();
}

class _BillProvidersCmsScreenState extends State<BillProvidersCmsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _list(AdminProvider admin) {
    final raw = admin.cmsConfig['billProviders'];
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
    final categories = items
        .map((p) => (p['category'] ?? 'Electricity').toString().toUpperCase())
        .toSet()
        .length;

    final filtered = items.where((p) {
      final st = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'DISABLED' && st == 'ACTIVE') return false;
      if (_query.isEmpty) return true;
      return '${p['name']} ${p['category']} ${p['sampleReference']}'
          .toLowerCase()
          .contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Utility Billers & 1-Bill Companies Directory',
        subtitle:
        'Manage electricity, gas, water, and internet billers with custom company logos uploaded from gallery',
        badgeText: '$activeCount ACTIVE BILLERS',
        badgeColor: AppConstants.accentBlue,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openDrawer(context, admin, items, null),
            icon: const Icon(Icons.add_business_rounded, size: 17),
            label: const Text('Add Utility Biller'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Total Utility Billers',
            value: '${items.length} Companies',
            sublabel: 'Integrated 1-Bill & direct utilities',
            icon: Icons.bolt_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Active In App',
            value: '$activeCount Online',
            sublabel: 'Available for instant customer bill pay',
            icon: Icons.check_circle_outline_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Paused / Disabled',
            value: '${items.length - activeCount} Offline',
            sublabel: 'Temporarily hidden from billing list',
            icon: Icons.pause_circle_outline_rounded,
            color: AppConstants.textMuted,
          ),
          NexPayStatItem(
            label: 'Utility Categories',
            value: '$categories Sectors',
            sublabel: 'Electricity, Gas, Water & Broadband',
            icon: Icons.category_outlined,
            color: AppConstants.accentGold,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search biller company or category...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'DISABLED'],
        selectedFilter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        resultSummary: 'Showing ${filtered.length} of ${items.length} billers',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1080,
        emptyState: const NexPayEmptyState(
          icon: Icons.bolt_rounded,
          title: 'No Utility Billers Configured',
          subtitle:
          'Click "Add Utility Biller" above to configure electricity, gas, or internet billing companies.',
        ),
        columns: const [
          DataColumn(label: Text('LOGO / ICON')),
          DataColumn(label: Text('COMPANY NAME')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('DIGITS & FORMAT')),
          DataColumn(label: Text('SERVICE FEE')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CONTROLS')),
        ],
        rows: filtered.map((p) {
          final iconVal = (p['icon'] ?? '⚡').toString();
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
              DataCell(Text((p['category'] ?? 'Electricity').toString(),
                  style: TextStyle(color: AppConstants.textSecondary))),
              DataCell(Text(
                  '${p['consumerDigits'] ?? 14} digits (${p['sampleReference'] ?? '-'})',
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontFamily: 'Consolas',
                      fontSize: 12))),
              DataCell(Text('Rs. ${p['fee'] ?? 0}',
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600))),
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
                      tooltip: 'Delete Biller',
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final confirmed = await showNexPayConfirmDialog(
                          context: context,
                          title: 'Delete Utility Biller',
                          message:
                          'Remove "$name" from the customer utility billers list?',
                          confirmLabel: 'Delete Biller',
                          confirmColor: AppConstants.dangerRed,
                        );
                        if (!confirmed || !context.mounted) return;
                        final updated =
                        items.where((x) => x['id'] != p['id']).toList();
                        final ok = await admin
                            .saveCmsConfig({'billProviders': updated});
                        if (context.mounted) {
                          _toast(context,
                              ok ? 'Biller removed.' : 'Delete failed.', ok);
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
  text: (existing?['category'] ?? 'Electricity').toString());
  final digitsCtrl = TextEditingController(
  text: (existing?['consumerDigits'] ?? '14').toString());
  final feeCtrl =
  TextEditingController(text: (existing?['fee'] ?? '0').toString());
  final sampleCtrl = TextEditingController(
  text: (existing?['sampleReference'] ?? '04000123456789').toString());
  String iconVal = (existing?['icon'] ?? '⚡').toString();
  bool active = existing == null ||
  (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

  showNexPayInspectorDrawer(
  context: context,
  title: isEdit ? 'Edit Biller: ${nameCtrl.text}' : 'Add Utility Biller',
  subtitle: 'Upload company logo from gallery or enter emoji icon',
  child: StatefulBuilder(
  builder: (ctx, setS) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  NexPayImageUploader(
  label: 'Biller Company Logo (Upload From Gallery - Optional)',
  initialValue:
  (iconVal.startsWith('data:image') || iconVal.startsWith('http'))
  ? iconVal
      : '',
  previewHeight: 110,
  onChanged: (v) => iconVal = v.isEmpty ? '⚡' : v,
  ),
  const SizedBox(height: 14),
  TextField(
  controller: nameCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText:
  'Biller Company Name (e.g. K-Electric, LESCO, SNGPL)')),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: catCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Category (Electricity/Gas/Water)'))),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: digitsCtrl,
  keyboardType: TextInputType.number,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Consumer ID Digits'))),
  ],
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: feeCtrl,
  keyboardType: TextInputType.number,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Convenience Fee (PKR)',
  prefixText: 'Rs. '))),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: sampleCtrl,
  style: TextStyle(color: AppConstants.textPrimary),
  decoration: const InputDecoration(
  labelText: 'Sample Reference Format'))),
  ],
  ),
  const SizedBox(height: 14),
  SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: Text('Biller Active in Customer App',
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
      : 'bill_${DateTime.now().millisecondsSinceEpoch}',
  'name': nameCtrl.text.trim(),
  'category': catCtrl.text.trim(),
  'consumerDigits': int.tryParse(digitsCtrl.text.trim()) ?? 14,
  'fee': double.tryParse(feeCtrl.text.trim()) ?? 0,
  'sampleReference': sampleCtrl.text.trim(),
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
  final ok = await admin.saveCmsConfig({'billProviders': updated});
  if (context.mounted) {
  _toast(context, ok ? 'Utility biller saved live!' : 'Save failed.',
  ok);
  }
  },
  child: const Text('Save Biller'),
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