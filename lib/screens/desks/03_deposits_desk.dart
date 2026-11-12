import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class DepositsDeskScreen extends StatefulWidget {
  const DepositsDeskScreen({super.key});

  @override
  State<DepositsDeskScreen> createState() => _DepositsDeskScreenState();
}

class _DepositsDeskScreenState extends State<DepositsDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, PENDING, APPROVED, REJECTED
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final deposits = admin.deposits;

    int pendingCount = 0;
    double pendingVolume = 0;
    int approvedCount = 0;
    double approvedVolume = 0;
    int rejectedCount = 0;

    for (final d in deposits) {
      if (d is! Map) continue;
      final st = (d['status'] ?? 'PENDING').toString().toUpperCase();
      final amt = double.tryParse(d['amount']?.toString() ?? '0') ?? 0;
      if (st == 'PENDING') {
        pendingCount++;
        pendingVolume += amt;
      } else if (st == 'APPROVED') {
        approvedCount++;
        approvedVolume += amt;
      } else {
        rejectedCount++;
      }
    }

    final filteredList = deposits.where((d) {
      if (d is! Map) return false;
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
        return mob.contains(q) ||
            name.contains(q) ||
            channel.contains(q) ||
            id.contains(q);
      }
      return true;
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Add Money & Deposits Clearing Desk',
        subtitle:
        'Inspect payment proofs, zoom & rotate bank transaction receipts, and credit verified customer wallets',
        badgeText:
        pendingCount > 0 ? '$pendingCount PENDING REVIEW' : 'ALL CLEARED',
        badgeColor: pendingCount > 0
            ? AppConstants.accentGold
            : AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.sync_rounded, size: 17),
            label: const Text('Sync Deposits'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Pending Verification',
            value: '$pendingCount Slips',
            sublabel: 'Rs. ${_currencyFormat.format(pendingVolume)} awaiting',
            icon: Icons.move_to_inbox_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Approved & Credited',
            value: '$approvedCount Deposits',
            sublabel:
            'Rs. ${_currencyFormat.format(approvedVolume)} settled in',
            icon: Icons.verified_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Rejected Submissions',
            value: '$rejectedCount Declined',
            sublabel: 'Invalid or duplicate payment proofs',
            icon: Icons.cancel_outlined,
            color: AppConstants.dangerRed,
          ),
          NexPayStatItem(
            label: 'Total Deposit Volume',
            value:
            'Rs. ${_currencyFormat.format(pendingVolume + approvedVolume)}',
            sublabel: '${deposits.length} total cash-in records',
            icon: Icons.account_balance_wallet_rounded,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search Reference ID, Mobile, Customer, or Channel...',
        onSearchChanged: (v) => setState(() => _searchQuery = v.trim()),
        filters: const ['ALL', 'PENDING', 'APPROVED', 'REJECTED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary:
        'Showing ${filteredList.length} of ${deposits.length} deposits',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1160,
        emptyState: NexPayEmptyState(
          icon: Icons.move_to_inbox_outlined,
          title: 'No Deposits Found',
          subtitle: 'No deposit proofs match your active filter ($_statusFilter).',
        ),
        columns: const [
          DataColumn(label: Text('REF ID')),
          DataColumn(label: Text('CUSTOMER')),
          DataColumn(label: Text('AMOUNT (PKR)'), numeric: true),
          DataColumn(label: Text('PAYMENT CHANNEL')),
          DataColumn(label: Text('PROOF RECEIPT')),
          DataColumn(label: Text('DATE / TIME')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('DECISION ACTION')),
        ],
        rows: filteredList.map((raw) {
          final d = Map<String, dynamic>.from(raw as Map);
          final status = (d['status'] ?? 'PENDING').toString().toUpperCase();
          final isPending = status == 'PENDING';
          final amount =
              double.tryParse(d['amount']?.toString() ?? '0') ?? 0.0;
          final id = int.tryParse(d['id']?.toString() ?? '0') ?? 0;
          final dateStr = _formatTimestamp(d['created_at']);
          final customerName = (d['user_name'] ?? 'Customer').toString();

          return DataRow(
            cells: [
              DataCell(NexPayCopyableId(text: '#$id', label: 'Deposit ID')),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    Text(
                      (d['user_mobile'] ?? '-').toString(),
                      style: TextStyle(
                          color: AppConstants.accentBlue,
                          fontSize: 11.5,
                          fontFamily: 'Consolas'),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  'Rs. ${_currencyFormat.format(amount)}',
                  style: TextStyle(
                    color: AppConstants.accentGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.accentGoldLight,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: AppConstants.accentGold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    (d['channel'] ?? 'Gateway').toString(),
                    style: TextStyle(
                        color: AppConstants.accentGold,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5),
                  ),
                ),
              ),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => _openProofViewerDialog(
                      context, id, customerName, amount, isPending, admin),
                  icon: Icon(Icons.photo_library_outlined,
                      size: 15, color: AppConstants.accentBlue),
                  label: const Text('Inspect Slip',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              DataCell(Text(dateStr,
                  style: TextStyle(
                      color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                isPending
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                      ),
                      onPressed: () => _confirmDepositDecision(
                          context, id, true, amount, customerName, admin),
                      icon: const Icon(Icons.check_rounded, size: 15),
                      label: const Text('Approve',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.dangerRed,
                        side: BorderSide(
                            color: AppConstants.dangerRed
                                .withValues(alpha: 0.45)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                      ),
                      onPressed: () => _confirmDepositDecision(context,
                          id, false, amount, customerName, admin),
                      icon: const Icon(Icons.close_rounded, size: 15),
                      label: const Text('Reject',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                )
                    : Text(
                  status == 'APPROVED'
                      ? '✓ Credited to Wallet'
                      : '✕ Rejected',
                  style: TextStyle(
                    color: status == 'APPROVED'
                        ? AppConstants.accentGreen
                        : AppConstants.dangerRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "-";
    try {
      final date = DateTime.parse(timestamp.toString());
      return DateFormat("dd MMM yyyy, hh:mm a").format(date);
    } catch (_) {
      return timestamp.toString();
    }
  }

  Future<void> _confirmDepositDecision(BuildContext context, int id,
      bool approved, double amount, String customerName, AdminProvider admin) async {
    final confirmed = await showNexPayConfirmDialog(
      context: context,
      title: approved ? 'Approve & Credit Deposit' : 'Reject Deposit Proof',
      message: approved
          ? 'Verify Deposit #$id? Rs. ${_currencyFormat.format(amount)} will be credited immediately into $customerName\'s primary wallet.'
          : 'Are you sure you want to reject Deposit #$id from $customerName?',
      confirmLabel: approved ? 'Yes, Approve & Credit' : 'Yes, Reject',
      confirmColor:
      approved ? AppConstants.accentGreen : AppConstants.dangerRed,
      icon: approved ? Icons.verified_rounded : Icons.cancel_rounded,
    );
    if (!confirmed || !context.mounted) return;

    final success = await admin.reviewDeposit(id, approved);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          success ? AppConstants.accentGreen : AppConstants.dangerRed,
          content: Text(
            success
                ? (approved
                ? 'Deposit #$id approved! Balance credited.'
                : 'Deposit #$id rejected.')
                : 'Process failed. Please try again.',
          ),
        ),
      );
    }
  }

  void _openProofViewerDialog(BuildContext context, int id, String name,
      double amount, bool isPending, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => _ProofViewerModal(
        depositId: id,
        customerName: name,
        amount: amount,
        isPending: isPending,
        onDecision: (approved) {
          Navigator.pop(ctx);
          _confirmDepositDecision(context, id, approved, amount, name, admin);
        },
      ),
    );
  }
}

class _ProofViewerModal extends StatefulWidget {
  final int depositId;
  final String customerName;
  final double amount;
  final bool isPending;
  final ValueChanged<bool> onDecision;

  const _ProofViewerModal({
    required this.depositId,
    required this.customerName,
    required this.amount,
    required this.isPending,
    required this.onDecision,
  });

  @override
  State<_ProofViewerModal> createState() => _ProofViewerModalState();
}

class _ProofViewerModalState extends State<_ProofViewerModal> {
  final ApiClient _api = ApiClient();
  final TransformationController _transformController =
  TransformationController();
  bool _isLoading = true;
  String? _screenshotData;
  String? _error;
  int _rotationQuarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _fetchProof();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _adjustZoom(double factor) {
    final current = _transformController.value.clone();
    current.scale(factor);
    _transformController.value = current;
  }

  Future<void> _fetchProof() async {
    try {
      final res = await _api.dio.get(
        '',
        queryParameters: {
          'action': 'get_deposit_proof',
          'id': widget.depositId,
          '_t': DateTime.now().millisecondsSinceEpoch
        },
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
    final money = NumberFormat("#,##0.00", "en_US");
    return Dialog(
      backgroundColor: AppConstants.surface,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppConstants.borderColor),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 740, maxHeight: 820),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment Receipt Proof #${widget.depositId}",
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${widget.customerName} • Rs. ${money.format(widget.amount)}",
                        style: TextStyle(
                            color: AppConstants.accentGreen,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: Icon(Icons.zoom_in_rounded,
                          color: AppConstants.textSecondary),
                      tooltip: "Zoom In",
                      onPressed: () => _adjustZoom(1.25),
                    ),
                    IconButton(
                      icon: Icon(Icons.zoom_out_rounded,
                          color: AppConstants.textSecondary),
                      tooltip: "Zoom Out",
                      onPressed: () => _adjustZoom(0.8),
                    ),
                    IconButton(
                      icon: Icon(Icons.restart_alt_rounded,
                          color: AppConstants.textSecondary),
                      tooltip: "Reset View",
                      onPressed: () {
                        setState(() => _rotationQuarterTurns = 0);
                        _transformController.value = Matrix4.identity();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.rotate_left_rounded,
                          color: AppConstants.accentBlue),
                      tooltip: "Rotate Left",
                      onPressed: () => setState(() =>
                      _rotationQuarterTurns = (_rotationQuarterTurns - 1) % 4),
                    ),
                    IconButton(
                      icon: Icon(Icons.rotate_right_rounded,
                          color: AppConstants.accentBlue),
                      tooltip: "Rotate Right",
                      onPressed: () => setState(() =>
                      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: AppConstants.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: AppConstants.borderColor, height: 20),

            // Image Container with Interactive Pan & Zoom
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: _isLoading
                      ? CircularProgressIndicator(
                      color: AppConstants.accentGreen)
                      : _error != null
                      ? Text(_error!,
                      style: TextStyle(
                          color: AppConstants.dangerRed,
                          fontWeight: FontWeight.bold))
                      : (_screenshotData == null ||
                      _screenshotData!.isEmpty)
                      ? const Text("No screenshot attached by customer",
                      style: TextStyle(color: Colors.white70))
                      : RotatedBox(
                    quarterTurns: _rotationQuarterTurns,
                    child: InteractiveViewer(
                      transformationController:
                      _transformController,
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: _buildProofImage(_screenshotData!),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Scroll, pinch, or use toolbar controls to zoom & rotate slip",
                  style:
                  TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                ),
                if (widget.isPending)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.dangerRed,
                        ),
                        onPressed: () => widget.onDecision(false),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => widget.onDecision(true),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve & Credit'),
                      ),
                    ],
                  ),
              ],
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
        errorBuilder: (_, error, stack) => const Text(
            "Image link broken or unreachable",
            style: TextStyle(color: Colors.white70)),
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
        errorBuilder: (_, error, stack) => const Text(
            "Unable to render Base64 image",
            style: TextStyle(color: Colors.white70)),
      );
    } catch (_) {
      return const Text("Corrupted screenshot data",
          style: TextStyle(color: Colors.white70));
    }
  }
}