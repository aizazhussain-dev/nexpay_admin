import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class ClosureRequestsDeskScreen extends StatefulWidget {
  const ClosureRequestsDeskScreen({super.key});

  @override
  State<ClosureRequestsDeskScreen> createState() => _ClosureRequestsDeskScreenState();
}

class _ClosureRequestsDeskScreenState extends State<ClosureRequestsDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  bool _isLoading = true;
  List<dynamic> _closureRequests = [];
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, PENDING, APPROVED, REJECTED
  bool _isActionBusy = false;

  @override
  void initState() {
    super.initState();
    _fetchClosureRequests();
  }

  Future<void> _fetchClosureRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '',
        queryParameters: {
          'action': 'get_closure_requests',
          '_t': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (res.data['status'] == 'success') {
        setState(() {
          _closureRequests = res.data['requests'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Fetch Closure Requests Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final usersMap = admin.users;

    // Filter Logic
    final filteredList = _closureRequests.where((r) {
      final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
      if (_statusFilter == "PENDING" && status != "PENDING") return false;
      if (_statusFilter == "APPROVED" && status != "APPROVED") return false;
      if (_statusFilter == "REJECTED" && status != "REJECTED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (r['mobile'] ?? '').toString().toLowerCase();
        final name = (r['name'] ?? '').toString().toLowerCase();
        final cnic = (r['cnic'] ?? '').toString().toLowerCase();
        final reason = (r['reason'] ?? '').toString().toLowerCase();
        final feedback = (r['feedback'] ?? '').toString().toLowerCase();
        final id = (r['id'] ?? '').toString();
        return mob.contains(q) || name.contains(q) || cnic.contains(q) || reason.contains(q) || feedback.contains(q) || id.contains(q);
      }
      return true;
    }).toList();

    // Operational Counters
    int pendingCount = 0;
    int terminatedCount = 0;
    int rejectedCount = 0;

    for (var r in _closureRequests) {
      final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
      if (status == 'PENDING') {
        pendingCount++;
      } else if (status == 'APPROVED') {
        terminatedCount++;
      } else if (status == 'REJECTED') {
        rejectedCount++;
      }
    }

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Refresh
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
                          "Account Closures & Deletion Audit Desk",
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
                              "$pendingCount TO AUDIT",
                              style: const TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Review customer account closure requests, verify outstanding wallet balances, and execute permanent termination",
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
                onPressed: () {
                  _fetchClosureRequests();
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
              _buildMetricCard("PENDING AUDIT", "$pendingCount Requests", pendingCount > 0 ? AppConstants.dangerRed : AppConstants.accentGreen, isDesktop),
              _buildMetricCard("PERMANENTLY TERMINATED", "$terminatedCount Accounts", Colors.white70, isDesktop),
              _buildMetricCard("REJECTED REQUESTS", "$rejectedCount Retained", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("TOTAL REQUESTS LOGGED", "${_closureRequests.length} Total", AppConstants.accentGold, isDesktop),
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
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Mobile, Name, CNIC, Reason...",
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
              _buildFilterChip("ALL", "All Requests (${_closureRequests.length})"),
              _buildFilterChip("PENDING", "Pending Audit ($pendingCount)"),
              _buildFilterChip("APPROVED", "Terminated ($terminatedCount)"),
              _buildFilterChip("REJECTED", "Rejected ($rejectedCount)"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
                : filteredList.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No account closure requests found matching criteria",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
                : isDesktop
                ? _buildDesktopTable(filteredList, usersMap, admin)
                : _buildMobileCards(filteredList, usersMap, admin),
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

  Widget _buildDesktopTable(List<dynamic> list, Map<String, dynamic> usersMap, AdminProvider admin) {
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
                DataColumn(label: Text("REQUEST DATE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CNIC IDENTITY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("WALLET BALANCE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("REASON FOR LEAVING", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("FEEDBACK / NOTES", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((r) {
                final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
                final isPending = status == 'PENDING';
                final isApproved = status == 'APPROVED';
                final dateStr = _formatTimestamp(r['created_at']);
                final mobile = (r['mobile'] ?? '').toString();
                final name = (r['name'] ?? 'Customer').toString();
                final id = int.tryParse(r['id']?.toString() ?? '0') ?? 0;

                // Match with active user balance in memory
                final userObj = usersMap[mobile];
                final currentBal = userObj != null ? (double.tryParse(userObj['balance']?.toString() ?? '0') ?? 0.0) : 0.0;
                final hasFunds = currentBal > 0;

                return DataRow(
                  cells: [
                    DataCell(Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(mobile, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(Text(r['cnic'] ?? '-', style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "₨ ${_currencyFormat.format(currentBal)}",
                            style: TextStyle(
                              color: hasFunds ? AppConstants.dangerRed : AppConstants.accentGreen,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                          if (hasFunds)
                            const Text("⚠️ Balance Remaining", style: TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(r['reason'] ?? 'Not specified', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(r['feedback'] ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                      ),
                    ),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      isPending
                          ? Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.dangerRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isActionBusy
                                ? null
                                : () => _confirmClosureDecision(context, id, mobile, 'APPROVE', currentBal, name, admin),
                            child: const Text("🗑 Terminate", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isActionBusy
                                ? null
                                : () => _confirmClosureDecision(context, id, mobile, 'REJECT', currentBal, name, admin),
                            child: const Text("✕ Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                          ),
                        ],
                      )
                          : Text(
                        isApproved ? "✓ Account Expunged" : "✕ Request Rejected",
                        style: TextStyle(
                          color: isApproved ? AppConstants.dangerRed : AppConstants.accentGreen,
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

  Widget _buildMobileCards(List<dynamic> list, Map<String, dynamic> usersMap, AdminProvider admin) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final r = list[idx];
        final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
        final isPending = status == 'PENDING';
        final dateStr = _formatTimestamp(r['created_at']);
        final mobile = (r['mobile'] ?? '').toString();
        final name = (r['name'] ?? 'Customer').toString();
        final id = int.tryParse(r['id']?.toString() ?? '0') ?? 0;

        final userObj = usersMap[mobile];
        final currentBal = userObj != null ? (double.tryParse(userObj['balance']?.toString() ?? '0') ?? 0.0) : 0.0;
        final hasFunds = currentBal > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isPending ? AppConstants.dangerRed.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Case #$id • $name", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 2),
              Text("Mobile: $mobile • CNIC: ${r['cnic'] ?? '-'}", style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 11)),
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Reason for Leaving", style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                      Text(r['reason'] ?? 'Not specified', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Wallet Balance", style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                      Text(
                        "₨ ${_currencyFormat.format(currentBal)}",
                        style: TextStyle(
                          color: hasFunds ? AppConstants.dangerRed : AppConstants.accentGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (r['feedback'] != null && r['feedback'].toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text("Feedback: ${r['feedback']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
              const SizedBox(height: 10),
              Text("Requested at: $dateStr", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),

              if (isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.dangerRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isActionBusy
                            ? null
                            : () => _confirmClosureDecision(context, id, mobile, 'APPROVE', currentBal, name, admin),
                        icon: const Icon(Icons.delete_forever_rounded, size: 16),
                        label: const Text("Terminate Account", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isActionBusy
                            ? null
                            : () => _confirmClosureDecision(context, id, mobile, 'REJECT', currentBal, name, admin),
                        child: const Text("Reject Request", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
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
      label = "UNDER REVIEW";
    } else if (status == 'APPROVED') {
      bg = AppConstants.dangerRed.withValues(alpha: 0.15);
      text = AppConstants.dangerRed;
      label = "TERMINATED";
    } else {
      bg = AppConstants.accentGreen.withValues(alpha: 0.15);
      text = AppConstants.accentGreen;
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

  // Dialog: Confirm Account Termination or Rejection
  void _confirmClosureDecision(
      BuildContext context,
      int requestId,
      String mobile,
      String decision,
      double currentBalance,
      String customerName,
      AdminProvider admin,
      ) {
    final isApprove = decision == 'APPROVE';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
        title: Row(
          children: [
            Icon(isApprove ? Icons.delete_forever_rounded : Icons.cancel_rounded, color: isApprove ? AppConstants.dangerRed : AppConstants.accentGreen),
            const SizedBox(width: 8),
            Text(isApprove ? "PERMANENT TERMINATION" : "Reject Closure Request", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? "Warning: Kya aap waqai customer $customerName ($mobile) ka account PERMANENTLY TERMINATE karna chahte hain?\n\nYeh user database se mukammal tor par delete ho jayega aur access foran block ho jayegi."
                  : "Kya aap customer $customerName ($mobile) ki account closure request ko REJECT karke unka account restore rakhna chahte hain?",
              style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
            ),
            if (isApprove && currentBalance > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.dangerRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppConstants.dangerRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Alert: User ke wallet me abhi ₨ ${_currencyFormat.format(currentBalance)} balance baqi hai! Termination ke baad yeh access nahi ho sakega.",
                        style: const TextStyle(color: AppConstants.dangerRed, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppConstants.dangerRed : AppConstants.accentGreen,
              foregroundColor: isApprove ? Colors.white : const Color(0xFF021A13),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isActionBusy = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'review_closure_request'},
                  data: {
                    'requestId': requestId,
                    'mobile': mobile,
                    'decision': decision,
                    'adminName': 'Administrator',
                  },
                );

                if (res.data['status'] == 'success') {
                  await _fetchClosureRequests();
                  await admin.fetchAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: isApprove ? AppConstants.dangerRed : AppConstants.accentGreen,
                        content: Text(
                          isApprove ? "✓ Customer $mobile has been permanently terminated." : "✓ Closure request rejected. Account retained.",
                          style: TextStyle(color: isApprove ? Colors.white : const Color(0xFF021A13), fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Processing failed.")),
                    );
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while processing closure request.")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isActionBusy = false);
              }
            },
            child: Text(isApprove ? "Yes, Terminate Account" : "Yes, Reject Request", style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}