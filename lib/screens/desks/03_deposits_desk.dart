import '../../widgets/institutional_scroll.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class DepositsDeskScreen extends StatefulWidget {
  const DepositsDeskScreen({super.key});

  @override
  State<DepositsDeskScreen> createState() => _DepositsDeskScreenState();
}

class _DepositsDeskScreenState extends State<DepositsDeskScreen> {
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, PENDING, APPROVED, REJECTED
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final deposits = admin.deposits;

    // Filter Logic
    final filteredList = deposits.where((d) {
      final status = (d['status'] ?? '').toString().toUpperCase();
      if (_statusFilter == "PENDING" && status != "PENDING") return false;
      if (_statusFilter == "APPROVED" && status != "APPROVED") return false;
      if (_statusFilter == "REJECTED" && status != "REJECTED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (d['user_mobile'] ?? '').toString().toLowerCase();
        final name = (d['user_name'] ?? '').toString().toLowerCase();
        final channel = (d['channel'] ?? '').toString().toLowerCase();
        final id = (d['id'] ?? '').toString();
        return mob.contains(q) || name.contains(q) || channel.contains(q) || id.contains(q);
      }
      return true;
    }).toList();

    final pendingCount = deposits.where((d) => (d['status'] ?? '').toString().toUpperCase() == "PENDING").length;

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
                          "Add Money & Deposits Desk",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConstants.accentGold.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              "$pendingCount PENDING REVIEW",
                              style: const TextStyle(color: AppConstants.accentGold, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Inspect payment proofs, verify bank transaction receipts and credit wallets",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => admin.fetchAllData(),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters and Search
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 360 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Mobile, Customer, Channel, ID...",
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
              _buildFilterChip("ALL", "All Deposits"),
              _buildFilterChip("PENDING", "Pending ($pendingCount)"),
              _buildFilterChip("APPROVED", "Approved"),
              _buildFilterChip("REJECTED", "Rejected"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Area
          Expanded(
            child: filteredList.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.move_to_inbox_outlined, size: 54, color: AppConstants.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    "No deposits found in this category",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Active filter: $_statusFilter",
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
        color: isSelected ? Color(0xFF021A13) : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
        child: InstitutionalVScroll(
          scrollDirection: Axis.vertical,
          child: InstitutionalHScroll(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              horizontalMargin: 20,
              columnSpacing: 26,
              columns: const [
                DataColumn(label: Text("REF ID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("AMOUNT (PKR)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("PAYMENT CHANNEL", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("PROOF RECEIPT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("DATE / TIME", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("DECISION ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((d) {
                final status = (d['status'] ?? 'PENDING').toString().toUpperCase();
                final isPending = status == 'PENDING';
                final amount = double.tryParse(d['amount']?.toString() ?? '0') ?? 0.0;
                final id = int.tryParse(d['id']?.toString() ?? '0') ?? 0;
                final dateStr = _formatTimestamp(d['created_at']);

                return DataRow(
                  cells: [
                    DataCell(Text("#$id", style: const TextStyle(color: AppConstants.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.w700))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(d['user_name'] ?? 'Customer', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(d['user_mobile'] ?? '-', style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        "₨ ${_currencyFormat.format(amount)}",
                        style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppConstants.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppConstants.accentGold.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          d['channel'] ?? 'Gateway',
                          style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w800, fontSize: 11.5),
                        ),
                      ),
                    ),
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.surfaceCard,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _openProofViewerDialog(context, id, d['user_name'] ?? 'Customer', amount),
                        icon: const Icon(Icons.photo_library_outlined, size: 14, color: AppConstants.accentBlue),
                        label: const Text("View Proof", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    DataCell(Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      isPending
                          ? Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmDepositDecision(context, id, true, amount, d['user_name'] ?? 'Customer', admin),
                            child: const Text("✓ Approve", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.dangerRed,
                              side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmDepositDecision(context, id, false, amount, d['user_name'] ?? 'Customer', admin),
                            child: const Text("✕ Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                          ),
                        ],
                      )
                          : Text(
                        status == 'APPROVED' ? "✓ Credited to Wallet" : "✕ Rejected",
                        style: TextStyle(
                          color: status == 'APPROVED' ? AppConstants.accentGreen : AppConstants.dangerRed,
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
        final d = list[idx];
        final status = (d['status'] ?? 'PENDING').toString().toUpperCase();
        final isPending = status == 'PENDING';
        final amount = double.tryParse(d['amount']?.toString() ?? '0') ?? 0.0;
        final id = int.tryParse(d['id']?.toString() ?? '0') ?? 0;
        final dateStr = _formatTimestamp(d['created_at']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isPending ? AppConstants.accentGold.withValues(alpha: 0.3) : Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("#$id", style: const TextStyle(color: AppConstants.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConstants.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          d['channel'] ?? 'Gateway',
                          style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ],
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
                      Text(d['user_name'] ?? 'Customer', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(d['user_mobile'] ?? '-', style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 12)),
                    ],
                  ),
                  Text(
                    "₨ ${_currencyFormat.format(amount)}",
                    style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.accentBlue,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => _openProofViewerDialog(context, id, d['user_name'] ?? 'Customer', amount),
                    icon: const Icon(Icons.fullscreen_rounded, size: 18),
                    label: const Text("Inspect Proof Slip", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmDepositDecision(context, id, true, amount, d['user_name'] ?? 'Customer', admin),
                        child: const Text("Approve & Credit", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
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
                        onPressed: () => _confirmDepositDecision(context, id, false, amount, d['user_name'] ?? 'Customer', admin),
                        child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
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

    if (status == 'PENDING') {
      bg = Colors.amber.withValues(alpha: 0.15);
      text = Colors.amber;
    } else if (status == 'APPROVED') {
      bg = AppConstants.accentGreen.withValues(alpha: 0.15);
      text = AppConstants.accentGreen;
    } else {
      bg = AppConstants.dangerRed.withValues(alpha: 0.15);
      text = AppConstants.dangerRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: text, fontSize: 10.5, fontWeight: FontWeight.w700)),
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

  // Confirmation Alert Dialog
  void _confirmDepositDecision(BuildContext context, int id, bool approved, double amount, String customerName, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
        title: Row(
          children: [
            Icon(approved ? Icons.verified_rounded : Icons.cancel_rounded, color: approved ? AppConstants.accentGreen : AppConstants.dangerRed),
            const SizedBox(width: 8),
            Text(approved ? "Approve Deposit" : "Reject Deposit", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Text(
          approved
              ? "Deposit #$id tasdeeq karein? ₨ ${_currencyFormat.format(amount)} $customerName ke primary wallet me credit ho jayenge."
              : "Kya aap Deposit #$id ko reject karna chahte hain?",
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approved ? AppConstants.accentGreen : AppConstants.dangerRed,
              foregroundColor: approved ? Color(0xFF021A13) : Color(0xFF0F172A),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await admin.reviewDeposit(id, approved);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppConstants.accentGreen : AppConstants.dangerRed,
                    content: Text(
                      success
                          ? (approved ? "Deposit #$id approved! Balance credited." : "Deposit #$id rejected.")
                          : "Process failed. Please try again.",
                      style: TextStyle(color: success ? Color(0xFF021A13) : Color(0xFF0F172A), fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            },
            child: Text(approved ? "Yes, Approve & Credit" : "Yes, Reject", style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Interactive Pan / Zoom / Rotate Receipt Dialog
  void _openProofViewerDialog(BuildContext context, int id, String name, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => _ProofViewerModal(depositId: id, customerName: name, amount: amount),
    );
  }
}

// Dedicated Modal with Fetch, Rotate & Pinch-to-Zoom
class _ProofViewerModal extends StatefulWidget {
  final int depositId;
  final String customerName;
  final double amount;

  const _ProofViewerModal({
    required this.depositId,
    required this.customerName,
    required this.amount,
  });

  @override
  State<_ProofViewerModal> createState() => _ProofViewerModalState();
}

class _ProofViewerModalState extends State<_ProofViewerModal> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _screenshotData;
  String? _error;
  int _rotationQuarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _fetchProof();
  }

  Future<void> _fetchProof() async {
    try {
      final res = await _api.dio.get(
        '',
        queryParameters: {'action': 'get_deposit_proof', 'id': widget.depositId, '_t': DateTime.now().millisecondsSinceEpoch},
      );
      if (res.data['status'] == 'success') {
        setState(() {
          _screenshotData = res.data['screenshot'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Proof not available";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load proof image";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppConstants.surface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 800),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Payment Receipt Proof #${widget.depositId}", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text("${widget.customerName} • ₨ ${widget.amount.toStringAsFixed(2)}", style: const TextStyle(color: AppConstants.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.rotate_left_rounded, color: AppConstants.accentBlue),
                      tooltip: "Rotate Counter-Clockwise",
                      onPressed: () => setState(() => _rotationQuarterTurns = (_rotationQuarterTurns - 1) % 4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right_rounded, color: AppConstants.accentBlue),
                      tooltip: "Rotate Clockwise",
                      onPressed: () => setState(() => _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2E8F0), height: 20),

            // Image Container with Interactive Pan & Zoom
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppConstants.accentGreen)
                      : _error != null
                      ? Text(_error!, style: const TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.bold))
                      : (_screenshotData == null || _screenshotData!.isEmpty)
                      ? const Text("No screenshot attached by customer", style: TextStyle(color: Color(0xFF64748B)))
                      : RotatedBox(
                    quarterTurns: _rotationQuarterTurns,
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: _buildProofImage(_screenshotData!),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tip: Pinch or double-click to Zoom in / Drag to pan image",
              style: TextStyle(color: AppConstants.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofImage(String data) {
    if (data.startsWith("http://") || data.startsWith("https://")) {
      return Image.network(
        data,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text("Image link broken or unreachable", style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    try {
      String cleanBase64 = data;
      if (data.contains(",")) {
        cleanBase64 = data.split(",").last;
      }
      final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text("Unable to render Base64 image", style: TextStyle(color: Color(0xFF64748B))),
      );
    } catch (_) {
      return const Text("Corrupted screenshot data", style: TextStyle(color: Color(0xFF64748B)));
    }
  }
}
