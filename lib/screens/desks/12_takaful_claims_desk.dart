import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class TakafulClaimsDeskScreen extends StatefulWidget {
  const TakafulClaimsDeskScreen({super.key});

  @override
  State<TakafulClaimsDeskScreen> createState() => _TakafulClaimsDeskScreenState();
}

class _TakafulClaimsDeskScreenState extends State<TakafulClaimsDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  bool _isLoading = true;
  List<dynamic> _claimsList = [];
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, PENDING, APPROVED, REJECTED
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchClaims();
  }

  Future<void> _fetchClaims() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '',
        queryParameters: {
          'action': 'get_takaful_claims',
          '_t': DateTime.now().millisecondsSinceEpoch
        },
      );
      if (res.data['status'] == 'success') {
        setState(() {
          _claimsList = res.data['claims'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Fetch Claims Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _claimsList.where((c) {
      final status = (c['status'] ?? 'PENDING').toString().toUpperCase();
      if (_statusFilter == "PENDING" && status != "PENDING") return false;
      if (_statusFilter == "APPROVED" && status != "APPROVED") return false;
      if (_statusFilter == "REJECTED" && status != "REJECTED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (c['user_mobile'] ?? '').toString().toLowerCase();
        final name = (c['user_name'] ?? '').toString().toLowerCase();
        final policy = (c['policy_number'] ?? '').toString().toLowerCase();
        final plan = (c['plan_title'] ?? '').toString().toLowerCase();
        final claimId = (c['claim_id'] ?? '').toString().toLowerCase();
        final details = (c['details'] ?? '').toString().toLowerCase();
        return mob.contains(q) ||
            name.contains(q) ||
            policy.contains(q) ||
            plan.contains(q) ||
            claimId.contains(q) ||
            details.contains(q);
      }
      return true;
    }).toList();

    // Financial Metrics
    int pendingCount = 0;
    int approvedCount = 0;
    double totalDisbursedAmount = 0.0;
    double pendingClaimVolume = 0.0;

    for (var c in _claimsList) {
      final status = (c['status'] ?? 'PENDING').toString().toUpperCase();
      final amt = double.tryParse(c['claim_amount']?.toString() ?? '0') ?? 0.0;

      if (status == 'PENDING') {
        pendingCount++;
        pendingClaimVolume += amt;
      } else if (status == 'APPROVED') {
        approvedCount++;
        totalDisbursedAmount += amt;
      }
    }

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
                          "Takaful Claims & Loss Settlement Desk",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
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
                              "$pendingCount TO AUDIT",
                              style: const TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Review customer loss claims, inspect policy subscriptions, and approve instant wallet compensation",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: Color(0xFF021A13),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _fetchClaims();
                  admin.fetchAllData();
                },
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metric Cards
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("PENDING AUDIT", "$pendingCount Claims", pendingCount > 0 ? AppConstants.dangerRed : AppConstants.accentGreen, isDesktop),
              _buildMetricCard("PENDING VOLUME", "₨ ${_currencyFormat.format(pendingClaimVolume)}", AppConstants.accentGold, isDesktop),
              _buildMetricCard("DISBURSED SETTLEMENTS", "₨ ${_currencyFormat.format(totalDisbursedAmount)}", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("TOTAL CLAIMS LOGGED", "${_claimsList.length} Claims", AppConstants.accentBlue, isDesktop),
            ],
          ),
          const SizedBox(height: 20),

          // Filters & Search
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 340 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Mobile, Case ID, Policy, Details...",
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
              _buildFilterChip("ALL", "All Claims (${_claimsList.length})"),
              _buildFilterChip("PENDING", "Under Audit ($pendingCount)"),
              _buildFilterChip("APPROVED", "Approved & Disbursed ($approvedCount)"),
              _buildFilterChip("REJECTED", "Rejected"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Desk
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
                : filteredList.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.health_and_safety_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No Takaful claim requests found",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold),
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
        border: Border.all(color: Color(0xFFE2E8F0)),
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
        color: isSelected ? Color(0xFF021A13) : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppConstants.accentGreen : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  Widget _buildDesktopTable(List<dynamic> list, AdminProvider admin) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE2E8F0)),
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
                DataColumn(label: Text("CLAIM DATE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("POLICY ID & PLAN", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CLAIM AMOUNT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("LOSS DESCRIPTION / DETAILS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("AUDIT ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((c) {
                final status = (c['status'] ?? 'PENDING').toString().toUpperCase();
                final isPending = status == 'PENDING';
                final isApproved = status == 'APPROVED';
                final amt = double.tryParse(c['claim_amount']?.toString() ?? '0') ?? 0.0;
                final dateStr = _formatTimestamp(c['created_at']);
                final claimId = (c['claim_id'] ?? '').toString();
                final mobile = (c['user_mobile'] ?? '').toString();

                return DataRow(
                  cells: [
                    DataCell(Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c['user_name'] ?? 'Customer', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(mobile, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c['plan_title'] ?? 'Takaful Plan', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 12.5)),
                          Text(c['policy_number'] ?? '-', style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        "₨ ${_currencyFormat.format(amt)}",
                        style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          c['details'] ?? '-',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      isPending
                          ? Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.accentGreen,
                              foregroundColor: Color(0xFF021A13),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isProcessing
                                ? null
                                : () => _confirmClaimDecision(context, claimId, 'APPROVED', amt, mobile, c['plan_title'] ?? 'Takaful', admin),
                            child: const Text("✓ Approve & Credit", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.dangerRed,
                              side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isProcessing
                                ? null
                                : () => _confirmClaimDecision(context, claimId, 'REJECTED', amt, mobile, c['plan_title'] ?? 'Takaful', admin),
                            child: const Text("✕ Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                          ),
                        ],
                      )
                          : Text(
                        isApproved ? "✓ Settled & Credited" : "✕ Rejected",
                        style: TextStyle(
                          color: isApproved ? AppConstants.accentGreen : AppConstants.dangerRed,
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
        final c = list[idx];
        final status = (c['status'] ?? 'PENDING').toString().toUpperCase();
        final isPending = status == 'PENDING';
        final amt = double.tryParse(c['claim_amount']?.toString() ?? '0') ?? 0.0;
        final dateStr = _formatTimestamp(c['created_at']);
        final claimId = (c['claim_id'] ?? '').toString();
        final mobile = (c['user_mobile'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isPending ? AppConstants.accentGreen.withValues(alpha: 0.3) : Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c['plan_title'] ?? 'Takaful Plan', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Policy: ${c['policy_number']} • Case: $claimId", style: const TextStyle(color: Color(0xFFA855F7), fontFamily: 'monospace', fontSize: 11)),
                  Text(
                    "₨ ${_currencyFormat.format(amt)}",
                    style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 20),
              Text("Loss Details: ${c['details'] ?? '-'}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, height: 1.35)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Customer: ${c['user_name']} ($mobile)", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                ],
              ),

              if (isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentGreen,
                          foregroundColor: Color(0xFF021A13),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () => _confirmClaimDecision(context, claimId, 'APPROVED', amt, mobile, c['plan_title'] ?? 'Takaful', admin),
                        child: const Text("Approve & Credit Wallet", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
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
                        onPressed: _isProcessing
                            ? null
                            : () => _confirmClaimDecision(context, claimId, 'REJECTED', amt, mobile, c['plan_title'] ?? 'Takaful', admin),
                        child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
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
      label = "UNDER AUDIT";
    } else if (status == 'APPROVED') {
      bg = AppConstants.accentGreen.withValues(alpha: 0.15);
      text = AppConstants.accentGreen;
      label = "APPROVED & CREDITED";
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "-";
    try {
      final date = DateTime.parse(timestamp.toString());
      return DateFormat("dd MMM, hh:mm a").format(date);
    } catch (_) {
      return timestamp.toString();
    }
  }

  // Confirm Claim Approval & Wallet Credit Dialog
  void _confirmClaimDecision(
      BuildContext context,
      String claimId,
      String decision,
      double amount,
      String mobile,
      String planTitle,
      AdminProvider admin,
      ) {
    final isApprove = decision == 'APPROVED';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE2E8F0))),
        title: Row(
          children: [
            Icon(isApprove ? Icons.verified_rounded : Icons.cancel_rounded, color: isApprove ? AppConstants.accentGreen : AppConstants.dangerRed),
            const SizedBox(width: 8),
            Text(isApprove ? "Approve & Credit Claim" : "Reject Takaful Claim", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          isApprove
              ? "Kya aap waqai Case #$claimId ko APPROVE karna chahte hain?\n\n"
              "Plan: $planTitle\n"
              "Compensation: ₨ ${_currencyFormat.format(amount)}\n\n"
              "Yeh raqam customer ($mobile) ke primary wallet balance me foran credit ho jayegi."
              : "Kya aap Case #$claimId ko REJECT karna chahte hain?",
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppConstants.accentGreen : AppConstants.dangerRed,
              foregroundColor: isApprove ? Color(0xFF021A13) : Color(0xFF0F172A),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'review_takaful_claim'},
                  data: {
                    'claimId': claimId,
                    'decision': decision,
                    'adminName': 'Administrator',
                  },
                );

                if (res.data['status'] == 'success') {
                  await _fetchClaims();
                  await admin.fetchAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: isApprove ? AppConstants.accentGreen : AppConstants.dangerRed,
                        content: Text(
                          isApprove ? "✓ Claim approved! ₨ ${_currencyFormat.format(amount)} credited to $mobile." : "Claim #$claimId rejected.",
                          style: TextStyle(color: isApprove ? Color(0xFF021A13) : Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Claim review failed.")),
                    );
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while processing claim.")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: Text(isApprove ? "Yes, Approve & Disburse" : "Yes, Reject", style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
