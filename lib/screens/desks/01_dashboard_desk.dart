import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class DashboardDeskScreen extends StatelessWidget {
  const DashboardDeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Financial Inflow & Outflow Calculation from Users
    double totalInflow = 0;
    double totalOutflow = 0;

    admin.users.forEach((_, u) {
      totalInflow += double.tryParse(u['received']?.toString() ?? '0') ?? 0;
      totalOutflow += double.tryParse(u['sent']?.toString() ?? '0') ?? 0;
    });

    final totalVolume = totalInflow + totalOutflow;
    final inRatio = totalVolume > 0 ? (totalInflow / totalVolume) : 0.5;

    // Pending Counters
    final pendingDeposits = admin.deposits.where((d) => d['status'] == 'PENDING').length;
    final pendingPayouts = admin.payouts.where((p) => p['status'] == 'PENDING').length;
    final pendingLoans = admin.loans.where((l) => l['status'] == 'UNDER_REVIEW').length;
    final openTickets = admin.tickets.where((t) => t['status'] == 'OPEN').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Quick Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Treasury & Analytics Command",
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: isDesktop ? 22 : 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Real-time liquidity, operational counters, and settlement ratio",
                    style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: Color(0xFF021A13),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => admin.fetchAllData(),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 7 Core KPI Cards (Responsive Adaptive Grid)
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _buildKpiCard("Registered Accounts", "${admin.users.length}", Icons.people_alt_rounded, AppConstants.accentBlue, isDesktop),
              _buildKpiCard("Pending Deposits", "$pendingDeposits", Icons.move_to_inbox_rounded, AppConstants.accentGold, isDesktop),
              _buildKpiCard("Pending Payouts", "$pendingPayouts", Icons.send_and_archive_rounded, AppConstants.dangerRed, isDesktop),
              _buildKpiCard("Active Loans", "${admin.loans.length}", Icons.electric_bolt_rounded, AppConstants.accentGreen, isDesktop),
              _buildKpiCard("Open Tickets", "$openTickets", Icons.headset_mic_rounded, Colors.orange, isDesktop),
              _buildKpiCard("Active Kametis", "${admin.kametiPools.length}", Icons.groups_rounded, Color(0xFFA855F7), isDesktop),
              _buildKpiCard("Pending Closures", "0", Icons.cancel_outlined, AppConstants.dangerRed, isDesktop),
            ],
          ),
          const SizedBox(height: 28),

          // Treasury Inflow vs Outflow Ratio Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppConstants.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Treasury Inflow vs Outflow Ratio",
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      "Total Volume: ₨ ${totalVolume.toStringAsFixed(2)}",
                      style: const TextStyle(color: AppConstants.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TOTAL INWARD FLOW", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text("₨ ${totalInflow.toStringAsFixed(2)}", style: const TextStyle(color: AppConstants.accentGreen, fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("TOTAL OUTWARD FLOW", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text("₨ ${totalOutflow.toStringAsFixed(2)}", style: const TextStyle(color: AppConstants.dangerRed, fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (inRatio * 100).toInt(),
                          child: Container(color: AppConstants.accentGreen),
                        ),
                        Expanded(
                          flex: ((1 - inRatio) * 100).toInt(),
                          child: Container(color: AppConstants.dangerRed),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, bool isDesktop) {
    return Container(
      width: isDesktop ? 220 : 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
