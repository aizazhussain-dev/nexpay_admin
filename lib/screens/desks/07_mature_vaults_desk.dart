import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class MatureVaultsDeskScreen extends StatefulWidget {
  const MatureVaultsDeskScreen({super.key});

  @override
  State<MatureVaultsDeskScreen> createState() => _MatureVaultsDeskScreenState();
}

class _MatureVaultsDeskScreenState extends State<MatureVaultsDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _extractLiveVaults(AdminProvider admin) {
    final List list = [];
    admin.users.forEach((mobile, rawUser) {
    if (rawUser is! Map) return;
    final userName = (rawUser['name'] ?? 'Saver').toString();
    final vaultsRaw = rawUser['vaults'] ??
    rawUser['savingsVaults'] ??
    rawUser['lockedVaults'] ??
    [];
    if (vaultsRaw is List) {
    for (final v in vaultsRaw) {
    if (v is! Map) continue;
    final principal = double.tryParse(v['amount']?.toString() ??
    v['principal']?.toString() ??
    '0') ??
    0;
    final profit = double.tryParse(v['profit']?.toString() ??
    v['expectedProfit']?.toString() ??
    '0') ??
    0;
    final status = (v['status'] ?? 'ACTIVE').toString().toUpperCase();
    list.add({
    'id': (v['id'] ?? 'VLT-${list.length + 1}').toString(),
    'mobile': mobile,
    'userName': userName,
    'title':
    (v['title'] ?? v['planName'] ?? 'Halal Term Vault').toString(),
    'principal': principal,
    'profit': profit,
    'apy': (v['apy'] ?? v['rate'] ?? '-').toString(),
    'maturityDate':
    (v['maturityDate'] ?? v['unlockDate'] ?? '-').toString(),
    'status': status,
    });
    }
    }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final vaults = _extractLiveVaults(admin);

    double activePrincipal = 0;
    double accruedProfit = 0;
    int maturedCount = 0;

    for (final v in vaults) {
      activePrincipal += (v['principal'] as double);
      accruedProfit += (v['profit'] as double);
      if (v['status'].toString().contains('MATUR')) maturedCount++;
    }

    final filtered = vaults.where((v) {
      final st = v['status'].toString();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'MATURED' && !st.contains('MATUR')) return false;
      if (_filter == 'REDEEMED' && !st.contains('REDEEM')) return false;

      if (_query.isEmpty) return true;
      final hay = '${v['id']} ${v['userName']} ${v['mobile']} ${v['title']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Matured Savings Vaults & Halal Profit Pools',
        subtitle:
        'Monitor customer term-locked Mudarabah vaults, maturity schedules, and accrued profit liabilities',
        badgeText: 'SAVINGS TREASURY',
        badgeColor: AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Vault Ledger'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Total Locked Principal',
            value: 'Rs. ${_money.format(activePrincipal)}',
            sublabel: '${vaults.length} live customer savings vaults',
            icon: Icons.lock_clock_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Accrued Halal Profit',
            value: 'Rs. ${_money.format(accruedProfit)}',
            sublabel: 'Total projected Mudarabah yield',
            icon: Icons.savings_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Matured Vaults',
            value: '$maturedCount Matured',
            sublabel: 'Ready for customer redemption',
            icon: Icons.event_available_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Total Vault Liability',
            value: 'Rs. ${_money.format(activePrincipal + accruedProfit)}',
            sublabel: 'Principal + profit reserve coverage',
            icon: Icons.account_balance_wallet_rounded,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search by vault ID, customer name, mobile, or plan...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'MATURED', 'REDEEMED'],
        selectedFilter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        resultSummary:
        'Showing ${filtered.length} of ${vaults.length} vaults',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const NexPayEmptyState(
          icon: Icons.lock_clock_rounded,
          title: 'No Savings Vaults Found',
          subtitle:
          'No active or matured customer savings vaults exist in the live database for this filter.',
        ),
        columns: const [
          DataColumn(label: Text('VAULT ID')),
          DataColumn(label: Text('SAVER ACCOUNT')),
          DataColumn(label: Text('VAULT PLAN')),
          DataColumn(label: Text('LOCKED PRINCIPAL'), numeric: true),
          DataColumn(label: Text('EXPECTED PROFIT'), numeric: true),
          DataColumn(label: Text('MATURITY DATE')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('INSPECT')),
        ],
        rows: filtered.map((v) {
          final vaultId = v['id'].toString();
          final principal = (v['principal'] as double);
          final profit = (v['profit'] as double);

          return DataRow(
            cells: [
              DataCell(NexPayCopyableId(text: vaultId, label: 'Vault ID')),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['userName'].toString(),
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w700)),
                    Text(v['mobile'].toString(),
                        style: TextStyle(
                            color: AppConstants.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              DataCell(
                Text(v['title'].toString(),
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              DataCell(
                Text('Rs. ${_money.format(principal)}',
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              DataCell(
                Text('+Rs. ${_money.format(profit)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppConstants.accentGreen,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              DataCell(
                Text(v['maturityDate'].toString(),
                    style: TextStyle(
                        color: AppConstants.textMuted, fontSize: 12)),
              ),
              DataCell(NexPayStatusBadge(status: v['status'].toString())),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () {
                    showNexPayInspectorDrawer(
                      context: context,
                      title: 'Savings Vault $vaultId',
                      subtitle: '${v['userName']} (${v['mobile']})',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                              border:
                              Border.all(color: AppConstants.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TOTAL MATURITY PAYOUT',
                                    style: TextStyle(
                                        color: AppConstants.textMuted,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${_money.format(principal + profit)}',
                                  style: TextStyle(
                                      color: AppConstants.accentGreen,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                NexPayStatusBadge(
                                    status: v['status'].toString()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          NexPayDetailSection(
                            title: 'Mudarabah Term Certificate',
                            children: [
                              NexPayKeyValueRow(
                                  label: 'Vault ID',
                                  value: vaultId,
                                  copyable: true),
                              NexPayKeyValueRow(
                                  label: 'Saver Mobile',
                                  value: v['mobile'].toString(),
                                  copyable: true),
                              NexPayKeyValueRow(
                                  label: 'Vault Plan',
                                  value: v['title'].toString()),
                              NexPayKeyValueRow(
                                  label: 'Locked Principal',
                                  value: 'Rs. ${_money.format(principal)}'),
                              NexPayKeyValueRow(
                                  label: 'Projected Profit',
                                  value: '+Rs. ${_money.format(profit)}',
                                  valueColor: AppConstants.accentGreen),
                              NexPayKeyValueRow(
                                  label: 'Expected APY',
                                  value: v['apy'].toString()),
                              NexPayKeyValueRow(
                                  label: 'Maturity Date',
                                  value: v['maturityDate'].toString()),
                            ],
                          ),
                        ],
                      ),
                      footerActions: [
                        OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close')),
                      ],
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('Details'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}