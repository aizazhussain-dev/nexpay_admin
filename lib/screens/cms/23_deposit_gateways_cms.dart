import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_image_picker.dart';
import '../../widgets/nexpay_ui_kit.dart';

class DepositGatewaysCmsScreen extends StatefulWidget {
  const DepositGatewaysCmsScreen({super.key});

  @override
  State<DepositGatewaysCmsScreen> createState() => _DepositGatewaysCmsScreenState();
}

class _DepositGatewaysCmsScreenState extends State<DepositGatewaysCmsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _getLiveGateways(AdminProvider admin) {
    final raw = admin.cmsConfig['depositGateways'];
    if (raw is List) {
      return raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final gateways = _getLiveGateways(admin);

    final activeCount = gateways.where((g) => (g['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE').length;
    final qrCount = gateways.where((g) => (g['qrUrl'] ?? '').toString().trim().isNotEmpty).length;

    final filtered = gateways.where((g) {
      final st = (g['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'INACTIVE' && st == 'ACTIVE') return false;
      if (_query.isEmpty) return true;
      final hay = '${g['name']} ${g['accountTitle']} ${g['accountNumber']} ${g['iban']}'.toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Deposit Gateways, IBFT Accounts & Raast QR Codes',
        subtitle: 'Configure receiving bank accounts, mobile wallets, limits, and upload Raast/Bank QR codes from gallery',
        badgeText: '$activeCount ACTIVE CHANNELS',
        badgeColor: AppConstants.accentGreen,
        actions: [
          OutlinedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.sync_rounded, size: 17),
            label: const Text('Sync Gateways'),
          ),
          ElevatedButton.icon(
            onPressed: () => _openGatewayDrawer(context, admin, gateways, null),
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('Add Deposit Channel'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Active Deposit Channels',
            value: '$activeCount Online',
            sublabel: 'Visible in customer Add-Money screen',
            icon: Icons.account_balance_wallet_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Raast / Bank QR Attached',
            value: '$qrCount QR Codes',
            sublabel: 'Scannable QR images uploaded',
            icon: Icons.qr_code_2_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Total Configured Banks',
            value: '${gateways.length} Channels',
            sublabel: 'Live smartvest.tech gateway config',
            icon: Icons.account_balance_rounded,
            color: AppConstants.accentGold,
          ),
          const NexPayStatItem(
            label: 'QR Media Upload',
            value: 'Gallery Enabled',
            sublabel: 'Upload QR screenshots directly from device',
            icon: Icons.photo_library_outlined,
            color: AppConstants.accentGreen,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search by bank name, account title, account number, or IBAN...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'INACTIVE'],
        selectedFilter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        resultSummary: 'Showing ${filtered.length} of ${gateways.length} gateways',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1140,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'No Deposit Gateways Configured',
          subtitle: 'Click "Add Deposit Channel" above to add a receiving bank account or Raast QR code.',
        ),
        columns: const [
          DataColumn(label: Text('QR / ICON')),
          DataColumn(label: Text('BANK / WALLET NAME')),
          DataColumn(label: Text('ACCOUNT TITLE')),
          DataColumn(label: Text('ACCOUNT NUMBER / IBAN')),
          DataColumn(label: Text('MIN - MAX LIMIT')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CONTROLS')),
        ],
        rows: filtered.map((g) {
          final qrSrc = (g['qrUrl'] ?? '').toString();
          final name = (g['name'] ?? 'Bank Channel').toString();
          final title = (g['accountTitle'] ?? '-').toString();
          final acct = (g['accountNumber'] ?? '-').toString();
          final minAmt = (g['minAmount'] ?? '100').toString();
          final maxAmt = (g['maxAmount'] ?? '500000').toString();
          final status = (g['status'] ?? 'ACTIVE').toString().toUpperCase();

          return DataRow(
            cells: [
              DataCell(
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: qrSrc.isNotEmpty
                        ? NexPaySmartImage(source: qrSrc, fit: BoxFit.cover)
                        : const Icon(Icons.qr_code_2_rounded, color: AppConstants.textMuted, size: 22),
                  ),
                ),
              ),
              DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(acct, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600))),
              DataCell(Text('Rs. $minAmt – Rs. $maxAmt', style: const TextStyle(fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openGatewayDrawer(context, admin, gateways, g),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Delete Gateway',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final updated = gateways.where((item) => item['id'] != g['id']).toList();
                        final ok = await admin.saveCmsConfig({'depositGateways': updated});
                        if (context.mounted) {
                          _toast(context, ok ? 'Deposit channel removed.' : 'Delete failed.', ok);
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

  void _openGatewayDrawer(
  BuildContext context,
  AdminProvider admin,
  List currentList,
  Map<String, dynamic>? existing,
  ) {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: (existing?['name'] ?? '').toString());
  final titleCtrl = TextEditingController(text: (existing?['accountTitle'] ?? '').toString());
  final acctCtrl = TextEditingController(text: (existing?['accountNumber'] ?? '').toString());
  final ibanCtrl = TextEditingController(text: (existing?['iban'] ?? '').toString());
  final minCtrl = TextEditingController(text: (existing?['minAmount'] ?? '100').toString());
  final maxCtrl = TextEditingController(text: (existing?['maxAmount'] ?? '500000').toString());
  final instructionsCtrl = TextEditingController(text: (existing?['instructions'] ?? 'Transfer exact amount and upload receipt screenshot.').toString());
  String qrValue = (existing?['qrUrl'] ?? '').toString();
  bool isActive = existing == null || (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

  showNexPayInspectorDrawer(
  context: context,
  width: 560,
  title: isEdit ? 'Edit Deposit Channel: ${nameCtrl.text}' : 'Add Receiving Bank / Wallet',
  subtitle: 'Upload Raast/Bank QR image from gallery and configure account credentials',
  child: StatefulBuilder(
  builder: (ctx, setDrawerState) {
  return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  NexPayImageUploader(
  label: 'Raast / Bank QR Code Image (Upload From Gallery)',
  initialValue: qrValue,
  previewHeight: 150,
  onChanged: (val) => qrValue = val,
  ),
  const SizedBox(height: 16),
  TextField(
  controller: nameCtrl,
  decoration: const InputDecoration(labelText: 'Bank or Wallet Name (e.g. Meezan Bank / SadaPay / Raast)'),
  ),
  const SizedBox(height: 14),
  TextField(
  controller: titleCtrl,
  decoration: const InputDecoration(labelText: 'Account Title'),
  ),
  const SizedBox(height: 14),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: acctCtrl,
  decoration: const InputDecoration(labelText: 'Account / Mobile Number'),
  ),
  ),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: ibanCtrl,
  decoration: const InputDecoration(labelText: 'IBAN (Optional)'),
  ),
  ),
  ],
  ),
  const SizedBox(height: 14),
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: minCtrl,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(labelText: 'Min Deposit (PKR)', prefixText: 'Rs. '),
  ),
  ),
  const SizedBox(width: 12),
  Expanded(
  child: TextField(
  controller: maxCtrl,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(labelText: 'Max Deposit (PKR)', prefixText: 'Rs. '),
  ),
  ),
  ],
  ),
  const SizedBox(height: 14),
  TextField(
  controller: instructionsCtrl,
  maxLines: 2,
  decoration: const InputDecoration(labelText: 'Customer Payment Instructions'),
  ),
  const SizedBox(height: 14),
  SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('Channel Active for Customer Deposits', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
  value: isActive,
  activeThumbColor: AppConstants.accentGreen,
  onChanged: (v) => setDrawerState(() => isActive = v),
  ),
  ],
  );
  },
  ),
  footerActions: [
  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
  const SizedBox(width: 12),
  ElevatedButton.icon(
  onPressed: () async {
  final name = nameCtrl.text.trim();
  final acct = acctCtrl.text.trim();
  if (name.isEmpty || acct.isEmpty) {
  _toast(context, 'Bank name and account number are required.', false);
  return;
  }
  Navigator.pop(context);
  final gwObj = {
  'id': isEdit ? existing['id'] : 'gw_${DateTime.now().millisecondsSinceEpoch}',
  'name': name,
  'accountTitle': titleCtrl.text.trim(),
  'accountNumber': acct,
  'iban': ibanCtrl.text.trim(),
  'minAmount': minCtrl.text.trim(),
  'maxAmount': maxCtrl.text.trim(),
  'instructions': instructionsCtrl.text.trim(),
  'qrUrl': qrValue,
  'status': isActive ? 'ACTIVE' : 'INACTIVE',
  };
  final updated = List.from(currentList);
  if (isEdit) {
  final idx = updated.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) {
  updated[idx] = gwObj;
  } else {
  updated.add(gwObj);
  }
  } else {
  updated.add(gwObj);
  }
  final ok = await admin.saveCmsConfig({'depositGateways': updated});
  if (context.mounted) {
  _toast(context, ok ? 'Deposit gateway saved live!' : 'Save failed.', ok);
  }
  },
  icon: const Icon(Icons.save_rounded, size: 17),
  label: const Text('Save Gateway'),
  ),
  ],
  );
  }

  void _toast(BuildContext context, String msg, bool ok) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(msg), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
  );
  }
}