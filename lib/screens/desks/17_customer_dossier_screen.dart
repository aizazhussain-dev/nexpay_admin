import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class CustomerDossierScreen extends StatefulWidget {
  const CustomerDossierScreen({super.key});

  @override
  State<CustomerDossierScreen> createState() => _CustomerDossierScreenState();
}

class _CustomerDossierScreenState extends State<CustomerDossierScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    // Merge live dossiers with master users so every customer has a complete 360 dossier
    final Map<String, Map<String, dynamic>> dossierIndex = {};
    for (final d in admin.dossiers) {
      if (d is Map) {
        final mob = (d['mobile'] ?? d['user_mobile'] ?? '').toString();
        if (mob.isNotEmpty) dossierIndex[mob] = Map<String, dynamic>.from(d);
      }
    }

    final List combined = [];
    admin.users.forEach((mobile, raw) {
    if (raw is! Map) return;
    final u = Map<String, dynamic>.from(raw);
    final extra = dossierIndex[mobile] ?? {};
    final userLoans = admin.loans.where((l) => l is Map && (l['user_mobile'] ?? l['mobile']) == mobile).length;
    final userKametis = admin.kametiMembers.where((m) => m is Map && (m['user_mobile'] ?? m['mobile']) == mobile).length;
    final userTrades = admin.stockTrades.where((t) => t is Map && (t['user_mobile'] ?? t['mobile']) == mobile).length;

    combined.add({
    ...extra,
    ...u,
    'mobile': mobile,
    'loanCount': userLoans,
    'kametiCount': userKametis,
    'tradeCount': userTrades,
    });
    });

    final filtered = combined.where((c) {
    final hasLoans = (c['loanCount'] as int) > 0;
    final hasInvest = ((double.tryParse(c['cryptoBalance']?.toString() ?? '0') ?? 0) > 0) ||
    ((double.tryParse(c['goldGrams']?.toString() ?? '0') ?? 0) > 0) ||
    (c['tradeCount'] as int) > 0;

    if (_filter == 'INVESTORS' && !hasInvest) return false;
    if (_filter == 'BORROWERS' && !hasLoans) return false;
    if (_filter == 'KAMETI' && (c['kametiCount'] as int) == 0) return false;

    if (_query.isEmpty) return true;
    final hay = '${c['name']} ${c['mobile']} ${c['cnic']} ${c['deviceId'] ?? ''}'.toLowerCase();
    return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
    header: NexPayDeskHeader(
    title: 'Customer 360° Intelligence Dossiers',
    subtitle: 'Unified cross-product exposure across PKR wallets, USDT, 24K Gold, US Equities, EasyCash Loans & Kameti',
    badgeText: '360° RISK INTELLIGENCE',
    badgeColor: AppConstants.accentBlue,
    actions: [
    ElevatedButton.icon(
    onPressed: () => admin.fetchAllData(),
    icon: const Icon(Icons.refresh_rounded, size: 17),
    label: const Text('Refresh Dossiers'),
    ),
    ],
    ),
    statStrip: NexPayStatStrip(
    items: [
    NexPayStatItem(
    label: 'Total Dossiers',
    value: '${combined.length} Profiles',
    sublabel: 'Synchronized with smartvest.tech',
    icon: Icons.folder_shared_rounded,
    color: AppConstants.accentBlue,
    ),
    NexPayStatItem(
    label: 'Active Investors',
    value: '${combined.where((c) => ((double.tryParse(c['cryptoBalance']?.toString() ?? '0') ?? 0) > 0) || ((double.tryParse(c['goldGrams']?.toString() ?? '0') ?? 0) > 0)).length} Users',
    sublabel: 'Holding USDT, Gold, or US Stocks',
    icon: Icons.trending_up_rounded,
    color: AppConstants.accentGreen,
    ),
    NexPayStatItem(
    label: 'Credit Exposure',
    value: '${combined.where((c) => (c['loanCount'] as int) > 0).length} Borrowers',
    sublabel: 'Active or historical loan accounts',
    icon: Icons.account_balance_rounded,
    color: AppConstants.accentGold,
    ),
    NexPayStatItem(
    label: 'ROSCA Participants',
    value: '${combined.where((c) => (c['kametiCount'] as int) > 0).length} Members',
    sublabel: 'Enrolled in Digital Kameti committees',
    icon: Icons.groups_rounded,
    color: AppConstants.accentBlue,
    ),
    ],
    ),
    filterBar: NexPayFilterBar(
    searchController: _searchCtrl,
    searchHint: 'Search dossier by name, mobile, CNIC, or device ID...',
    onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
    filters: const ['ALL', 'INVESTORS', 'BORROWERS', 'KAMETI'],
    selectedFilter: _filter,
    onFilterChanged: (f) => setState(() => _filter = f),
    resultSummary: 'Showing ${filtered.length} of ${combined.length} dossiers',
    ),
    body: NexPayFullWidthTable(
    minTableWidth: 1180,
    emptyState: const InstitutionalEmptyState(
    icon: Icons.folder_open_rounded,
    title: 'No Customer Dossiers Found',
    subtitle: 'No customer profiles match your filter criteria.',
    ),
    columns: const [
    DataColumn(label: Text('CUSTOMER IDENTITY')),
    DataColumn(label: Text('PKR WALLET'), numeric: true),
    DataColumn(label: Text('USDT'), numeric: true),
    DataColumn(label: Text('GOLD (g)'), numeric: true),
    DataColumn(label: Text('LOANS / KAMETI / TRADES')),
    DataColumn(label: Text('KYC & STATUS')),
    DataColumn(label: Text('FULL DOSSIER')),
    ],
    rows: filtered.map((c) {
    final mobile = c['mobile'].toString();
    final name = (c['name'] ?? 'Customer').toString();
    final pkr = double.tryParse(c['balance']?.toString() ?? '0') ?? 0;
    final usdt = double.tryParse(c['cryptoBalance']?.toString() ?? '0') ?? 0;
    final gold = double.tryParse(c['goldGrams']?.toString() ?? '0') ?? 0;
    final isKyc = c['isKycVerified'] == true ||
    c['isKycVerified'] == 1 ||
    (c['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';

    return DataRow(
    cells: [
    DataCell(
    Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
    Text('$mobile • ${c['cnic'] ?? 'No CNIC'}', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
    ],
    ),
    ),
    DataCell(Text('Rs. ${_money.format(pkr)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGreen))),
    DataCell(Text('\$ ${_money.format(usdt)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGold))),
    DataCell(Text('${gold.toStringAsFixed(3)} g', style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGold))),
    DataCell(
    Text(
    '${c['loanCount']} Loans  •  ${c['kametiCount']} Kameti  •  ${c['tradeCount']} Trades',
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    ),
    DataCell(NexPayStatusBadge(status: isKyc ? 'VERIFIED' : 'UNVERIFIED')),
    DataCell(
    OutlinedButton.icon(
    onPressed: () => _openDossierDrawer(context, c),
    icon: const Icon(Icons.folder_open_rounded, size: 15),
    label: const Text('Open 360° Sheet'),
    ),
    ),
    ],
    );
    }).toList(),
    ),
    );
  }

  void _openDossierDrawer(BuildContext context, Map<String, dynamic> c) {
    final pkr = double.tryParse(c['balance']?.toString() ?? '0') ?? 0;
    final usdt = double.tryParse(c['cryptoBalance']?.toString() ?? '0') ?? 0;
    final gold = double.tryParse(c['goldGrams']?.toString() ?? '0') ?? 0;
    final txs = (c['transactions'] is List) ? (c['transactions'] as List) : [];

    showNexPayInspectorDrawer(
      context: context,
      width: 600,
      title: '360° Dossier: ${c['name'] ?? 'Customer'}',
      subtitle: '${c['mobile']} • CNIC: ${c['cnic'] ?? 'N/A'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _miniMetric('PKR CASH', 'Rs. ${_money.format(pkr)}', AppConstants.accentGreen),
              _miniMetric('USDT CRYPTO', '\$ ${_money.format(usdt)}', AppConstants.accentGold),
              _miniMetric('24K GOLD', '${gold.toStringAsFixed(3)} g', AppConstants.accentGold),
            ],
          ),
          const SizedBox(height: 20),
          _kv('Registered Email', (c['email'] ?? '-').toString()),
          _kv('Residential Address', (c['address'] ?? '-').toString()),
          _kv('Device Binding ID', (c['deviceId'] ?? c['device_id'] ?? 'Unbound').toString()),
          _kv('Account Created', (c['createdAt'] ?? c['created_at'] ?? '-').toString()),
          const SizedBox(height: 18),
          Text(
            'RECENT WALLET ACTIVITY (${txs.length} RECORDS)',
            style: const TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (txs.isEmpty)
            const Text('No transaction history recorded on this profile yet.', style: TextStyle(color: AppConstants.textMuted, fontSize: 12.5))
          else
            ...txs.take(15).map((t) {
              if (t is! Map) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((t['title'] ?? t['type'] ?? 'Transaction').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          Text('${t['tid'] ?? '-'} • ${t['date'] ?? '-'}', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${t['amount'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.textPrimary),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
      footerActions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close Dossier')),
      ],
    );
  }

  Widget _miniMetric(String label, String val, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(k, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600))),
          Expanded(child: Text(v, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}