import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class DashboardDeskScreen extends StatelessWidget {
  const DashboardDeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final money = NumberFormat('#,##0.00', 'en_US');
    final compact = NumberFormat.compact(locale: 'en_US');

    double totalWalletFloat = 0;
    double totalVaults = 0;
    double totalGoldGrams = 0;
    double totalInflow = 0;
    double totalOutflow = 0;
    int verifiedUsers = 0;
    int frozenUsers = 0;

    final List recentLedger = [];

    admin.users.forEach((mobile, rawUser) {
    if (rawUser is! Map) return;
    totalWalletFloat += double.tryParse(rawUser['balance']?.toString() ?? '0') ?? 0;
    totalVaults += double.tryParse(rawUser['vaultBalance']?.toString() ?? '0') ?? 0;
    totalGoldGrams += double.tryParse(rawUser['goldGrams']?.toString() ?? '0') ?? 0;
    totalInflow += double.tryParse(rawUser['received']?.toString() ?? '0') ?? 0;
    totalOutflow += double.tryParse(rawUser['sent']?.toString() ?? '0') ?? 0;
    if (rawUser['isKycVerified'] == true) verifiedUsers++;
    if (rawUser['isFrozen'] == true) frozenUsers++;

    final txs = rawUser['transactions'];
    if (txs is List) {
    for (final t in txs.take(5)) {
    if (t is Map) {
    recentLedger.add({
    ...Map<String, dynamic>.from(t),
    'userMobile': mobile,
    'userName': rawUser['name'] ?? 'Customer',
    });
    }
    }
    }
    });

    recentLedger.sort((a, b) => (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));

    final goldEngine = admin.cmsConfig['goldEngine'] is Map ? admin.cmsConfig['goldEngine'] : {};
    final usdPerOz = double.tryParse(goldEngine['usdRatePerOunce']?.toString() ?? '4140') ?? 4140;
    final usdPkr = double.tryParse(goldEngine['usdPkrRate']?.toString() ?? '280') ?? 280;
    final goldValuePkr = totalGoldGrams * ((usdPerOz / 31.1035) * usdPkr);
    final totalEcosystemLiquidity = totalWalletFloat + totalVaults + goldValuePkr;

    final pendingDeposits = admin.deposits.where((d) => (d['status'] ?? '').toString().toUpperCase() == 'PENDING').toList();
    final pendingPayouts = admin.payouts.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING').toList();
    final pendingLoans = admin.loans.where((l) => (l['status'] ?? '').toString().toUpperCase() == 'UNDER_REVIEW').toList();
    final openTickets = admin.tickets.where((t) => (t['status'] ?? '').toString().toUpperCase() == 'OPEN').toList();

    return SingleChildScrollView(
    padding: EdgeInsets.all(isDesktop ? 24 : 16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Top Action Header
    Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    'Institutional Treasury & Risk Overview',
    style: TextStyle(
    color: AppConstants.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    ),
    ),
    const SizedBox(height: 3),
    Text(
    'Live settlement telemetry • ${admin.users.length} accounts ($verifiedUsers KYC verified, $frozenUsers frozen)',
    style: const TextStyle(color: AppConstants.textMuted, fontSize: 12.5),
    ),
    ],
    ),
    Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    OutlinedButton.icon(
    onPressed: () => _showQuickWalletDialog(context, admin),
    icon: const Icon(Icons.account_balance_wallet_outlined, size: 17, color: AppConstants.accentBlue),
    label: const Text('Credit / Debit Wallet'),
    ),
    const SizedBox(width: 10),
    ElevatedButton.icon(
    onPressed: () => admin.fetchAllData(),
    icon: const Icon(Icons.refresh_rounded, size: 17),
    label: const Text('Refresh Telemetry'),
    ),
    ],
    ),
    ],
    ),
    const SizedBox(height: 20),

    // 4 Primary Financial KPI Cards
    LayoutBuilder(
    builder: (context, constraints) {
    final cols = constraints.maxWidth >= 1000 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
    final cardWidth = (constraints.maxWidth - (14 * (cols - 1))) / cols;
    return Wrap(
    spacing: 14,
    runSpacing: 14,
    children: [
    _buildExecutiveKpi(
    width: cardWidth,
    label: 'ECOSYSTEM LIQUIDITY',
    value: 'Rs. ${money.format(totalEcosystemLiquidity)}',
    subtext: 'Wallet: Rs. ${compact.format(totalWalletFloat)} • Gold: ${totalGoldGrams.toStringAsFixed(2)}g',
    badge: '24/7 SOLVENT',
    accent: AppConstants.accentGreen,
    badgeBg: AppConstants.accentGreenLight,
    icon: Icons.account_balance_rounded,
    ),
    _buildExecutiveKpi(
    width: cardWidth,
    label: 'TOTAL INWARD SETTLEMENT',
    value: 'Rs. ${money.format(totalInflow)}',
    subtext: '${pendingDeposits.length} deposit proofs awaiting clearance',
    badge: 'CASH-IN',
    accent: AppConstants.accentBlue,
    badgeBg: AppConstants.accentBlueLight,
    icon: Icons.south_west_rounded,
    ),
    _buildExecutiveKpi(
    width: cardWidth,
    label: 'TOTAL OUTWARD PAYOUTS',
    value: 'Rs. ${money.format(totalOutflow)}',
    subtext: '${pendingPayouts.length} manual bank transfers queued',
    badge: 'CASH-OUT',
    accent: AppConstants.dangerRed,
    badgeBg: AppConstants.dangerRedLight,
    icon: Icons.north_east_rounded,
    ),
    _buildExecutiveKpi(
    width: cardWidth,
    label: 'ACTIVE OPERATIONS QUEUE',
    value: '${pendingDeposits.length + pendingPayouts.length + pendingLoans.length}',
    subtext: '${pendingLoans.length} Loans • ${openTickets.length} Support Tickets',
    badge: 'ACTION NEEDED',
    accent: AppConstants.accentGold,
    badgeBg: AppConstants.accentGoldLight,
    icon: Icons.pending_actions_rounded,
    ),
    ],
    );
    },
    ),
    const SizedBox(height: 20),

    // Middle Analytics Row: Treasury Flow Bar Chart + Asset Reserve Allocation
    if (isDesktop)
    Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Expanded(
    flex: 3,
    child: _buildTreasuryBarChart(totalInflow, totalOutflow, totalWalletFloat, goldValuePkr, money),
    ),
    const SizedBox(width: 16),
    Expanded(
    flex: 2,
    child: _buildAssetAllocationCard(totalWalletFloat, totalVaults, goldValuePkr, money),
    ),
    ],
    )
    else ...[
    _buildTreasuryBarChart(totalInflow, totalOutflow, totalWalletFloat, goldValuePkr, money),
    const SizedBox(height: 16),
    _buildAssetAllocationCard(totalWalletFloat, totalVaults, goldValuePkr, money),
    ],
    const SizedBox(height: 20),

    // Lower Workbench: 1-Click Approval Queue + Recent Master Ledger
    if (isDesktop)
    Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Expanded(
    flex: 5,
    child: _buildPendingWorkbench(context, admin, pendingDeposits, pendingPayouts, pendingLoans, money),
    ),
    const SizedBox(width: 16),
    Expanded(
    flex: 6,
    child: _buildRecentTransactionsCard(recentLedger, money),
    ),
    ],
    )
    else ...[
    _buildPendingWorkbench(context, admin, pendingDeposits, pendingPayouts, pendingLoans, money),
    const SizedBox(height: 16),
    _buildRecentTransactionsCard(recentLedger, money),
    ],
    ],
    ),
    );
  }

  Widget _buildExecutiveKpi({
    required double width,
    required String label,
    required String value,
    required String subtext,
    required String badge,
    required Color accent,
    required Color badgeBg,
    required IconData icon,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuryBarChart(
      double inflow,
      double outflow,
      double walletFloat,
      double goldPkr,
      NumberFormat money,
      ) {
    final maxVal = [inflow, outflow, walletFloat, goldPkr, 1000.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Treasury Capital & Settlement Flow',
                    style: TextStyle(color: AppConstants.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Comparative breakdown of Inward, Outward, Liquid Float & 24K Bullion',
                    style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                  ),
                ],
              ),
              Text(
                'Net Ratio: ${inflow + outflow > 0 ? ((inflow / (inflow + outflow)) * 100).toStringAsFixed(1) : '100'}% In',
                style: const TextStyle(color: AppConstants.accentGreen, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.18,
                barTouchData: BarTouchData(enabled: true),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      getTitlesWidget: (val, _) => Text(
                        NumberFormat.compact().format(val),
                        style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        const labels = ['Inward Flow', 'Outward Flow', 'Wallet Float', '24K Gold'];
                        final idx = val.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _makeRod(0, inflow, AppConstants.accentGreen),
                  _makeRod(1, outflow, AppConstants.dangerRed),
                  _makeRod(2, walletFloat, AppConstants.accentBlue),
                  _makeRod(3, goldPkr, AppConstants.accentGold),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeRod(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 34,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildAssetAllocationCard(double wallet, double vaults, double gold, NumberFormat money) {
    final total = wallet + vaults + gold;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custody Reserve Breakdown',
            style: TextStyle(color: AppConstants.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text(
            'Customer liabilities across liquid wallets, vaults & bullion',
            style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildReserveRow('Primary Liquid Wallets', wallet, total, AppConstants.accentBlue, money),
          const SizedBox(height: 16),
          _buildReserveRow('Safe Savings Vaults', vaults, total, AppConstants.accentGreen, money),
          const SizedBox(height: 16),
          _buildReserveRow('24K Physical Bullion Reserve', gold, total, AppConstants.accentGold, money),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Custodial Liability',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Rs. ${money.format(total)}',
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveRow(String title, double amount, double total, Color color, NumberFormat money) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
            Text(
              'Rs. ${money.format(amount)} (${(pct * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: AppConstants.surfaceCard,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingWorkbench(
      BuildContext context,
      AdminProvider admin,
      List<dynamic> pendingDeposits,
      List<dynamic> pendingPayouts,
      List<dynamic> pendingLoans,
      NumberFormat money,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Urgent Settlement Approvals',
                style: TextStyle(color: AppConstants.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.dangerRedLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pendingDeposits.length + pendingPayouts.length + pendingLoans.length} Pending',
                  style: const TextStyle(color: AppConstants.dangerRed, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (pendingDeposits.isEmpty && pendingPayouts.isEmpty && pendingLoans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'All deposits, payouts, and loans are cleared.',
                  style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                ),
              ),
            ),
          ...pendingPayouts.take(4).map((p) {
            final id = int.tryParse(p['id']?.toString() ?? '0') ?? 0;
            final tid = (p['tid'] ?? '').toString();
            final mobile = (p['sender_mobile'] ?? '').toString();
            final amt = double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
            return _buildApprovalTile(
              badge: 'PAYOUT',
              badgeColor: AppConstants.dangerRed,
              badgeBg: AppConstants.dangerRedLight,
              title: '${p['beneficiary_title'] ?? 'Beneficiary'} • ${p['target_bank'] ?? 'Bank'}',
              subtitle: 'Acct: ${p['beneficiary_account'] ?? ''} • By $mobile',
              amount: 'Rs. ${money.format(amt)}',
              onApprove: () => admin.completePayout(id, tid),
              onReject: () => admin.rejectPayout(id, tid, mobile, amt),
            );
          }),
          ...pendingDeposits.take(4).map((d) {
            final id = int.tryParse(d['id']?.toString() ?? '0') ?? 0;
            final amt = double.tryParse(d['amount']?.toString() ?? '0') ?? 0;
            return _buildApprovalTile(
              badge: 'DEPOSIT',
              badgeColor: AppConstants.accentGreen,
              badgeBg: AppConstants.accentGreenLight,
              title: '${d['user_name'] ?? 'Customer'} (${d['user_mobile'] ?? ''})',
              subtitle: 'Channel: ${d['channel'] ?? 'Bank'} • ID #$id',
              amount: 'Rs. ${money.format(amt)}',
              onApprove: () => admin.reviewDeposit(id, true),
              onReject: () => admin.reviewDeposit(id, false),
            );
          }),
          ...pendingLoans.take(3).map((l) {
            final id = int.tryParse(l['id']?.toString() ?? '0') ?? 0;
            final amt = double.tryParse(l['amount']?.toString() ?? '0') ?? 0;
            return _buildApprovalTile(
              badge: 'LOAN',
              badgeColor: AppConstants.accentGold,
              badgeBg: AppConstants.accentGoldLight,
              title: '${l['user_name'] ?? 'Applicant'} (${l['user_mobile'] ?? ''})',
              subtitle: 'Tenure: ${l['tenure'] ?? '30 Days'} • ${l['purpose'] ?? 'Financing'}',
              amount: 'Rs. ${money.format(amt)}',
              onApprove: () => admin.reviewLoan(id, true),
              onReject: () => admin.reviewLoan(id, false),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApprovalTile({
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required String title,
    required String subtitle,
    required String amount,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
            child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Approve & Settle',
            icon: const Icon(Icons.check_circle_rounded, color: AppConstants.accentGreen, size: 22),
            onPressed: onApprove,
          ),
          IconButton(
            tooltip: 'Reject',
            icon: const Icon(Icons.cancel_rounded, color: AppConstants.dangerRed, size: 22),
            onPressed: onReject,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsCard(List ledger, NumberFormat money) {
  return Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppConstants.borderColor),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text(
  'Live Master Ledger Stream',
  style: TextStyle(color: AppConstants.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
  ),
  const SizedBox(height: 2),
  const Text(
  'Latest settled transactions across all customer wallets',
  style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
  ),
  const SizedBox(height: 14),
  if (ledger.isEmpty)
  const Padding(
  padding: EdgeInsets.symmetric(vertical: 28),
  child: Center(
  child: Text('No ledger transactions recorded yet.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
  ),
  )
  else
  ...ledger.take(8).map((tx) {
  final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
  final isCredit = amt >= 0;
  return Container(
  padding: const EdgeInsets.symmetric(vertical: 10),
  decoration: const BoxDecoration(
  border: Border(bottom: BorderSide(color: AppConstants.borderColor)),
  ),
  child: Row(
  children: [
  Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
  color: isCredit ? AppConstants.accentGreenLight : AppConstants.dangerRedLight,
  borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(
  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
  size: 16,
  color: isCredit ? AppConstants.accentGreen : AppConstants.dangerRed,
  ),
  ),
  const SizedBox(width: 10),
  Expanded(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(
  (tx['title'] ?? 'Ledger Entry').toString(),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(color: AppConstants.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
  ),
  Text(
  '${tx['userName']} (${tx['userMobile']}) • TID: ${tx['tid'] ?? 'N/A'}',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  ),
  ],
  ),
  ),
  const SizedBox(width: 8),
  Text(
  '${isCredit ? '+' : '-'} Rs. ${money.format(amt.abs())}',
  style: TextStyle(
  color: isCredit ? AppConstants.accentGreen : AppConstants.dangerRed,
  fontSize: 12.5,
  fontWeight: FontWeight.w700,
  fontFeatures: [FontFeature.tabularFigures()],
  ),
  ),
  ],
  ),
  );
  }),
  ],
  ),
  );
  }

  void _showQuickWalletDialog(BuildContext context, AdminProvider admin) {
  final mobileCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  bool isCredit = true;

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setModalState) => AlertDialog(
  title: const Text('Treasury Wallet Credit / Debit'),
  content: SizedBox(
  width: 380,
  child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  Row(
  children: [
  Expanded(
  child: ChoiceChip(
  label: const Center(child: Text('Credit (+ PKR)')),
  selected: isCredit,
  onSelected: (_) => setModalState(() => isCredit = true),
  ),
  ),
  const SizedBox(width: 10),
  Expanded(
  child: ChoiceChip(
  label: const Center(child: Text('Debit (- PKR)')),
  selected: !isCredit,
  onSelected: (_) => setModalState(() => isCredit = false),
  ),
  ),
  ],
  ),
  const SizedBox(height: 14),
  TextField(
  controller: mobileCtrl,
  decoration: const InputDecoration(
  labelText: 'Customer Mobile (e.g. 03001234567)',
  prefixIcon: Icon(Icons.phone_android_rounded, size: 18),
  ),
  ),
  const SizedBox(height: 12),
  TextField(
  controller: amountCtrl,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
  labelText: 'Amount in PKR',
  prefixIcon: Icon(Icons.payments_outlined, size: 18),
  ),
  ),
  ],
  ),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
  ElevatedButton(
  onPressed: () async {
  final mob = mobileCtrl.text.trim();
  final rawAmt = double.tryParse(amountCtrl.text.trim()) ?? 0;
  if (mob.isEmpty || rawAmt <= 0) return;
  final finalAmt = isCredit ? rawAmt : -rawAmt;
  Navigator.pop(ctx);
  final ok = await admin.adjustBalance(mob, finalAmt);
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  content: Text(ok ? 'Wallet balance updated successfully.' : 'Failed to update wallet balance.'),
  backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed,
  ),
  );
  }
  },
  child: const Text('Execute Adjustment'),
  ),
  ],
  ),
  ),
  );
  }
}