import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class LoansDeskScreen extends StatefulWidget {
  const LoansDeskScreen({super.key});

  @override
  State<LoansDeskScreen> createState() => _LoansDeskScreenState();
}

class _LoansDeskScreenState extends State<LoansDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, UNDER_REVIEW, DISBURSED, SETTLED, REJECTED
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final loans = admin.loans;

    // Filter Logic
    final filteredList = loans.where((l) {
      final status = (l['status'] ?? '').toString().toUpperCase();
      final repaid = double.tryParse(l['repaid_amount']?.toString() ?? '0') ?? 0.0;
      final total = double.tryParse(l['amount']?.toString() ?? '0') ?? 0.0;
      final isSettled = status == 'SETTLED' || (status == 'DISBURSED' && repaid >= total);

      if (_statusFilter == "UNDER_REVIEW" && status != "UNDER_REVIEW") return false;
      if (_statusFilter == "DISBURSED" && (status != "DISBURSED" || isSettled)) return false;
      if (_statusFilter == "SETTLED" && !isSettled) return false;
      if (_statusFilter == "REJECTED" && status != "REJECTED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (l['user_mobile'] ?? '').toString().toLowerCase();
        final name = (l['user_name'] ?? '').toString().toLowerCase();
        final id = (l['id'] ?? '').toString();
        final purpose = (l['purpose'] ?? '').toString().toLowerCase();
        final tenure = (l['tenure'] ?? '').toString().toLowerCase();
        return mob.contains(q) || name.contains(q) || id.contains(q) || purpose.contains(q) || tenure.contains(q);
      }
      return true;
    }).toList();

    // Financial Metrics Calculation
    double totalDisbursed = 0;
    double totalRepaid = 0;
    int pendingUnderReview = 0;

    for (var l in loans) {
      final status = (l['status'] ?? '').toString().toUpperCase();
      final amt = double.tryParse(l['amount']?.toString() ?? '0') ?? 0.0;
      final rep = double.tryParse(l['repaid_amount']?.toString() ?? '0') ?? 0.0;

      if (status == 'DISBURSED' || status == 'SETTLED') {
        totalDisbursed += amt;
        totalRepaid += rep;
      }
      if (status == 'UNDER_REVIEW') {
        pendingUnderReview++;
      }
    }

    final totalOutstanding = (totalDisbursed - totalRepaid).clamp(0.0, double.infinity);

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
                          "EasyCash Nano-Loans & Recovery Desk",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (pendingUnderReview > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              "$pendingUnderReview TO UNDERWRITE",
                              style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Audit nano-loan applications, disburse wallet capital, and log recovery installments",
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

          // Loan Portfolio Summary Cards
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("TOTAL DISBURSED", "₨ ${_currencyFormat.format(totalDisbursed)}", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("TOTAL RECOVERED", "₨ ${_currencyFormat.format(totalRepaid)}", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("OUTSTANDING DUE", "₨ ${_currencyFormat.format(totalOutstanding)}", AppConstants.dangerRed, isDesktop),
              _buildMetricCard("PORTFOLIO SIZE", "${loans.length} Loans", AppConstants.accentGold, isDesktop),
            ],
          ),
          const SizedBox(height: 20),

          // Search & Filter Controls
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 340 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Customer, Mobile, Purpose...",
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
              _buildFilterChip("ALL", "All (${loans.length})"),
              _buildFilterChip("UNDER_REVIEW", "Under Review ($pendingUnderReview)"),
              _buildFilterChip("DISBURSED", "Active Repayments"),
              _buildFilterChip("SETTLED", "Fully Settled"),
              _buildFilterChip("REJECTED", "Rejected"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Area
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.electric_bolt_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No loan records found matching criteria",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildMetricCard(String title, String value, Color color, bool isDesktop) {
    return Container(
      width: isDesktop ? 220 : 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
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
              columnSpacing: 26,
              columns: const [
                DataColumn(label: Text("LOAN ID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("PRINCIPAL", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("REPAID / DUE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("TENURE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("PURPOSE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((l) {
                final status = (l['status'] ?? 'UNDER_REVIEW').toString().toUpperCase();
                final totalAmt = double.tryParse(l['amount']?.toString() ?? '0') ?? 0.0;
                final repaid = double.tryParse(l['repaid_amount']?.toString() ?? '0') ?? 0.0;
                final isSettled = status == 'SETTLED' || (status == 'DISBURSED' && repaid >= totalAmt);
                final due = (totalAmt - repaid).clamp(0.0, double.infinity);
                final id = int.tryParse(l['id']?.toString() ?? '0') ?? 0;
                final mobile = (l['user_mobile'] ?? '').toString();

                return DataRow(
                  cells: [
                    DataCell(Text("#$id", style: const TextStyle(color: AppConstants.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l['user_name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(mobile, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        "₨ ${_currencyFormat.format(totalAmt)}",
                        style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Text("₨ ${_currencyFormat.format(repaid)}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                          const Text(" / ", style: TextStyle(color: Colors.white30)),
                          Text("₨ ${_currencyFormat.format(due)}", style: const TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    DataCell(Text(l['tenure'] ?? '30 Days', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(Text(l['purpose'] ?? 'General', style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
                    DataCell(_buildStatusBadge(status, isSettled)),
                    DataCell(
                      status == 'UNDER_REVIEW'
                          ? Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.accentGreen,
                              foregroundColor: const Color(0xFF021A13),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmLoanUnderwriting(context, id, true, totalAmt, mobile, admin),
                            child: const Text("✓ Disburse", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.dangerRed,
                              side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmLoanUnderwriting(context, id, false, totalAmt, mobile, admin),
                            child: const Text("✕ Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                          ),
                        ],
                      )
                          : (status == 'DISBURSED' && !isSettled)
                          ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.withValues(alpha: 0.15),
                          foregroundColor: Colors.amber,
                          side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _openLogRecoveryDialog(context, id, mobile, due, admin),
                        icon: const Icon(Icons.payments_rounded, size: 14),
                        label: const Text("Log Recovery", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                      )
                          : Text(
                        isSettled ? "✓ Fully Settled" : "✕ Rejected",
                        style: TextStyle(
                          color: isSettled ? AppConstants.accentGreen : AppConstants.dangerRed,
                          fontSize: 11.5,
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

  Widget _buildMobileCards(List<dynamic> list, AdminProvider admin) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final l = list[idx];
        final status = (l['status'] ?? 'UNDER_REVIEW').toString().toUpperCase();
        final totalAmt = double.tryParse(l['amount']?.toString() ?? '0') ?? 0.0;
        final repaid = double.tryParse(l['repaid_amount']?.toString() ?? '0') ?? 0.0;
        final isSettled = status == 'SETTLED' || (status == 'DISBURSED' && repaid >= totalAmt);
        final due = (totalAmt - repaid).clamp(0.0, double.infinity);
        final id = int.tryParse(l['id']?.toString() ?? '0') ?? 0;
        final mobile = (l['user_mobile'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: status == 'UNDER_REVIEW' ? AppConstants.accentGreen.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("#$id • ${l['tenure'] ?? '30 Days'}", style: const TextStyle(color: AppConstants.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                  _buildStatusBadge(status, isSettled),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l['user_name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(mobile, style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 12)),
                    ],
                  ),
                  Text(
                    "₨ ${_currencyFormat.format(totalAmt)}",
                    style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Purpose: ${l['purpose'] ?? 'General'}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  Text(
                    "Due: ₨ ${_currencyFormat.format(due)}",
                    style: const TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              if (status == 'UNDER_REVIEW') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentGreen,
                          foregroundColor: const Color(0xFF021A13),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmLoanUnderwriting(context, id, true, totalAmt, mobile, admin),
                        child: const Text("Approve & Disburse", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.dangerRed,
                          side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmLoanUnderwriting(context, id, false, totalAmt, mobile, admin),
                        child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ] else if (status == 'DISBURSED' && !isSettled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      foregroundColor: Colors.amber,
                      side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openLogRecoveryDialog(context, id, mobile, due, admin),
                    icon: const Icon(Icons.payments_rounded, size: 16),
                    label: const Text("Log Repayment Installment", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, bool isSettled) {
    Color bg;
    Color text;
    String label = status;

    if (isSettled) {
      bg = AppConstants.accentGreen.withValues(alpha: 0.15);
      text = AppConstants.accentGreen;
      label = "FULLY SETTLED";
    } else if (status == 'UNDER_REVIEW') {
      bg = const Color(0xFFA855F7).withValues(alpha: 0.15);
      text = const Color(0xFFA855F7);
      label = "UNDER REVIEW";
    } else if (status == 'DISBURSED') {
      bg = Colors.amber.withValues(alpha: 0.15);
      text = Colors.amber;
      label = "ACTIVE REPAYMENT";
    } else {
      bg = AppConstants.dangerRed.withValues(alpha: 0.15);
      text = AppConstants.dangerRed;
      label = "REJECTED";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: text, fontSize: 10.5, fontWeight: FontWeight.w900)),
    );
  }

  // Underwrite / Disburse / Reject Dialog
  void _confirmLoanUnderwriting(BuildContext context, int id, bool approved, double amount, String mobile, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
        title: Row(
          children: [
            Icon(approved ? Icons.verified_rounded : Icons.cancel_rounded, color: approved ? AppConstants.accentGreen : AppConstants.dangerRed),
            const SizedBox(width: 8),
            Text(approved ? "Disburse Nano-Loan" : "Reject Loan Application", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          approved
              ? "Kya aap Loan #$id approve karna chahte hain? ₨ ${_currencyFormat.format(amount)} customer ($mobile) ke primary wallet balance me foran credit kar diye jayenge."
              : "Kya aap Loan #$id ko REJECT karna chahte hain?",
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approved ? AppConstants.accentGreen : AppConstants.dangerRed,
              foregroundColor: approved ? const Color(0xFF021A13) : Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'review_loan'},
                  data: {'loanId': id, 'approved': approved},
                );

                if (res.data['status'] == 'success') {
                  await admin.fetchAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: approved ? AppConstants.accentGreen : AppConstants.dangerRed,
                        content: Text(
                          approved ? "✓ Loan approved & ₨ ${_currencyFormat.format(amount)} disbursed!" : "Loan #$id rejected.",
                          style: TextStyle(color: approved ? const Color(0xFF021A13) : Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Loan review failed.")),
                    );
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while updating loan.")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: Text(approved ? "Yes, Disburse Capital" : "Yes, Reject", style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // Log Repayment Installment Dialog
  void _openLogRecoveryDialog(BuildContext context, int id, String mobile, double due, AdminProvider admin) {
    final controller = TextEditingController(text: due.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
        title: const Row(
          children: [
            Icon(Icons.payments_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text("Log Loan Installment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: $mobile • Loan #$id", style: const TextStyle(color: AppConstants.accentBlue, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Outstanding Balance Due: ₨ ${_currencyFormat.format(due)}", style: const TextStyle(color: AppConstants.dangerRed, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              decoration: InputDecoration(
                labelText: "Recovered Installment (PKR)",
                labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppConstants.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () async {
              final val = double.tryParse(controller.text) ?? 0.0;
              if (val <= 0) return;
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'repay_loan'},
                  data: {
                    'loanId': id,
                    'mobile': mobile,
                    'amount': val,
                  },
                );

                if (res.data['status'] == 'success') {
                  await admin.fetchAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppConstants.accentGreen,
                        content: Text("✓ Recorded recovery of ₨ ${_currencyFormat.format(val)}!", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Recovery logging failed.")),
                    );
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while recording repayment.")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: const Text("Log Repayment", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}