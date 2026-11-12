import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class ManualPayoutsDeskScreen extends StatefulWidget {
  const ManualPayoutsDeskScreen({super.key});

  @override
  State<ManualPayoutsDeskScreen> createState() => _ManualPayoutsDeskScreenState();
}

class _ManualPayoutsDeskScreenState extends State<ManualPayoutsDeskScreen> {
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, PENDING, COMPLETED, REJECTED
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final payouts = admin.payouts;

    // Filter Logic matching PHP backend
    final filteredList = payouts.where((p) {
      final status = (p['status'] ?? '').toString().toUpperCase();
      if (_statusFilter == "PENDING" && status != "PENDING") return false;
      if (_statusFilter == "COMPLETED" && (status != "COMPLETED" && status != "ACCEPTED")) return false;
      if (_statusFilter == "REJECTED" && status != "REJECTED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (p['sender_mobile'] ?? '').toString().toLowerCase();
        final tid = (p['tid'] ?? '').toString().toLowerCase();
        final bank = (p['target_bank'] ?? '').toString().toLowerCase();
        final acc = (p['beneficiary_account'] ?? '').toString().toLowerCase();
        final title = (p['beneficiary_title'] ?? '').toString().toLowerCase();
        final name = (p['sender_name'] ?? '').toString().toLowerCase();
        return mob.contains(q) || tid.contains(q) || bank.contains(q) || acc.contains(q) || title.contains(q) || name.contains(q);
      }
      return true;
    }).toList();

    final pendingCount = payouts.where((p) => (p['status'] ?? '').toString().toUpperCase() == "PENDING").length;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Manual Transfers & Payouts Desk",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.dangerRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              "$pendingCount PENDING",
                              style: const TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Review customer withdrawal requests, dispatch to bank/wallets or auto-refund",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: const Color(0xFF021A13),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => admin.fetchAllData(),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search & Filter Controls
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Field
              SizedBox(
                width: isDesktop ? 360 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search TID, Mobile, Bank, Account...",
                    hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.textMuted, size: 20),
                    filled: true,
                    fillColor: AppConstants.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),

              // Filter Chips
              _buildFilterChip("ALL", "All Payouts"),
              _buildFilterChip("PENDING", "Pending ($pendingCount)"),
              _buildFilterChip("COMPLETED", "Completed"),
              _buildFilterChip("REJECTED", "Rejected & Refunded"),
            ],
          ),
          const SizedBox(height: 18),

          // Main Table or Card List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 54, color: AppConstants.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    "No payout transfers found matching criteria",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Status filter: $_statusFilter",
                    style: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )
                : isDesktop
                ? _buildDesktopTable(filteredList, admin)
                : _buildMobileCards(filteredList, admin),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.accentGreen,
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF021A13) : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppConstants.accentGreen : Colors.white10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  // Desktop Scrollable Table
  Widget _buildDesktopTable(List<dynamic> list, AdminProvider admin) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text("TIMESTAMP", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CUSTOMER (SENDER)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("TARGET SERVICE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("ACCOUNT TITLE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("ACCOUNT / IBAN", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("AMOUNT (PKR)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("TID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((p) {
                final status = (p['status'] ?? 'PENDING').toString().toUpperCase();
                final isPending = status == 'PENDING';
                final isCompleted = status == 'COMPLETED' || status == 'ACCEPTED';
                final amount = double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
                final dateStr = _formatTimestamp(p['created_at']);

                return DataRow(
                  cells: [
                    DataCell(Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p['sender_name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(p['sender_mobile'] ?? '-', style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          p['target_bank'] ?? 'Bank',
                          style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w800, fontSize: 11.5),
                        ),
                      ),
                    ),
                    DataCell(Text(p['beneficiary_title'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5))),
                    DataCell(
                      Text(
                        p['beneficiary_account'] ?? '-',
                        style: const TextStyle(color: AppConstants.accentGold, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                    DataCell(
                      Text(
                        "₨ ${_currencyFormat.format(amount)}",
                        style: const TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                    DataCell(Text(p['tid'] ?? '-', style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'))),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      isPending
                          ? Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.accentGreen,
                              foregroundColor: const Color(0xFF021A13),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmCompletePayout(context, p, admin),
                            icon: const Icon(Icons.check_rounded, size: 14),
                            label: const Text("Accept", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.dangerRed,
                              side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmRejectAndRefund(context, p, admin),
                            icon: const Icon(Icons.close_rounded, size: 14),
                            label: const Text("Reject & Refund", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                          ),
                        ],
                      )
                          : Text(
                        isCompleted ? "✓ Completed (${p['processed_by'] ?? 'Admin'})" : "✕ Refunded",
                        style: TextStyle(
                          color: isCompleted ? AppConstants.accentGreen : AppConstants.dangerRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Mobile Friendly Cards List
  Widget _buildMobileCards(List<dynamic> list, AdminProvider admin) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final p = list[idx];
        final status = (p['status'] ?? 'PENDING').toString().toUpperCase();
        final isPending = status == 'PENDING';
        final amount = double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
        final dateStr = _formatTimestamp(p['created_at']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isPending ? Colors.amber.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p['target_bank'] ?? 'Bank',
                      style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w900, fontSize: 11.5),
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['beneficiary_title'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(p['beneficiary_account'] ?? '-', style: const TextStyle(color: AppConstants.accentGold, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13)),
                    ],
                  ),
                  Text(
                    "₨ ${_currencyFormat.format(amount)}",
                    style: const TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("From: ${p['sender_name']} (${p['sender_mobile']})", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              Text("TID: ${p['tid']}", style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontFamily: 'monospace')),

              if (isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentGreen,
                          foregroundColor: const Color(0xFF021A13),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmCompletePayout(context, p, admin),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text("Accept Transfer", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.dangerRed,
                          side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmRejectAndRefund(context, p, admin),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text("Reject & Refund", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label = status;

    if (status == 'PENDING') {
      bg = Colors.amber.withValues(alpha: 0.15);
      text = Colors.amber;
      label = "PENDING DISPATCH";
    } else if (status == 'COMPLETED' || status == 'ACCEPTED') {
      bg = AppConstants.accentGreen.withValues(alpha: 0.15);
      text = AppConstants.accentGreen;
      label = "COMPLETED";
    } else {
      bg = AppConstants.dangerRed.withValues(alpha: 0.15);
      text = AppConstants.dangerRed;
      label = "REJECTED & REFUNDED";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: text, fontSize: 10.5, fontWeight: FontWeight.w900)),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "-";
    try {
      final date = DateTime.parse(timestamp.toString());
      return DateFormat("dd MMM, hh:mm a").format(date);
    } catch (_) {
      return timestamp.toString();
    }
  }

  // Dialog: Complete / Accept Payout
  void _confirmCompletePayout(BuildContext context, dynamic payout, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppConstants.accentGreen),
            SizedBox(width: 8),
            Text("Complete Transfer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          "Have you sent ₨ ${_currencyFormat.format(double.tryParse(payout['amount']?.toString() ?? '0') ?? 0)} to ${payout['beneficiary_title']} (${payout['beneficiary_account']})?\n\nThis will mark the payout as COMPLETED.",
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: const Color(0xFF021A13)),
            onPressed: () async {
              Navigator.pop(ctx);
              final id = int.tryParse(payout['id']?.toString() ?? '0') ?? 0;
              final tid = payout['tid']?.toString() ?? '';
              final success = await admin.completePayout(id, tid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppConstants.accentGreen : AppConstants.dangerRed,
                    content: Text(
                      success ? "Payout #$tid marked as Completed!" : "Failed to update payout.",
                      style: TextStyle(color: success ? const Color(0xFF021A13) : Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            },
            child: const Text("Yes, Mark Completed", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // Dialog: Reject & Refund
  void _confirmRejectAndRefund(BuildContext context, dynamic payout, AdminProvider admin) {
    final amount = double.tryParse(payout['amount']?.toString() ?? '0') ?? 0.0;
    final senderMobile = payout['sender_mobile']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppConstants.dangerRed),
            SizedBox(width: 8),
            Text("Reject & Auto-Refund", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          "Are you sure you want to REJECT payout TID: ${payout['tid']}?\n\n₨ ${_currencyFormat.format(amount)} will be automatically credited back into customer's ($senderMobile) primary wallet ledger.",
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final id = int.tryParse(payout['id']?.toString() ?? '0') ?? 0;
              final tid = payout['tid']?.toString() ?? '';
              final success = await admin.rejectPayout(id, tid, senderMobile, amount);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppConstants.accentGreen : AppConstants.dangerRed,
                    content: Text(
                      success ? "Payout rejected. ₨ ${_currencyFormat.format(amount)} refunded to $senderMobile!" : "Failed to refund payout.",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            },
            child: const Text("Reject & Refund Funds", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}