import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class ManualPayoutsDeskScreen extends StatefulWidget {
  const ManualPayoutsDeskScreen({super.key});

  @override
  State<ManualPayoutsDeskScreen> createState() =>
      _ManualPayoutsDeskScreenState();
}

class _ManualPayoutsDeskScreenState extends State<ManualPayoutsDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, PENDING, COMPLETED, REJECTED
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final payouts = admin.payouts;

    int pendingCount = 0;
    double pendingVolume = 0;
    int completedCount = 0;
    double completedVolume = 0;
    int rejectedCount = 0;

    for (final p in payouts) {
      if (p is! Map) continue;
      final st = (p['status'] ?? 'PENDING').toString().toUpperCase();
      final amt = double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
      if (st == 'PENDING') {
        pendingCount++;
        pendingVolume += amt;
      } else if (st == 'COMPLETED' || st == 'ACCEPTED') {
        completedCount++;
        completedVolume += amt;
      } else {
        rejectedCount++;
      }
    }

    final filteredList = payouts.where((p) {
      if (p is! Map) return false;
      final status = (p['status'] ?? '').toString().toUpperCase();
      if (_statusFilter == "PENDING" && status != "PENDING") return false;
      if (_statusFilter == "COMPLETED" &&
          (status != "COMPLETED" && status != "ACCEPTED")) {
        return false;
      }
      if (_statusFilter == "REJECTED" && status != "REJECTED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (p['sender_mobile'] ?? '').toString().toLowerCase();
        final tid = (p['tid'] ?? '').toString().toLowerCase();
        final bank = (p['target_bank'] ?? '').toString().toLowerCase();
        final acc = (p['beneficiary_account'] ?? '').toString().toLowerCase();
        final title = (p['beneficiary_title'] ?? '').toString().toLowerCase();
        final name = (p['sender_name'] ?? '').toString().toLowerCase();
        return mob.contains(q) ||
            tid.contains(q) ||
            bank.contains(q) ||
            acc.contains(q) ||
            title.contains(q) ||
            name.contains(q);
      }
      return true;
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Manual Transfers & Payouts Desk',
        subtitle:
        'Review customer withdrawal requests, copy beneficiary IBANs, dispatch to banks or auto-refund',
        badgeText: pendingCount > 0 ? '$pendingCount PENDING' : 'QUEUE CLEAR',
        badgeColor: pendingCount > 0
            ? AppConstants.dangerRed
            : AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.sync_rounded, size: 17),
            label: const Text('Sync Payout Queue'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Pending Dispatch',
            value: '$pendingCount Requests',
            sublabel: 'Rs. ${_currencyFormat.format(pendingVolume)} queued',
            icon: Icons.outbox_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Completed Transfers',
            value: '$completedCount Settled',
            sublabel:
            'Rs. ${_currencyFormat.format(completedVolume)} disbursed',
            icon: Icons.check_circle_outline_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Rejected & Refunded',
            value: '$rejectedCount Returned',
            sublabel: 'Auto-credited back to sender wallets',
            icon: Icons.undo_rounded,
            color: AppConstants.dangerRed,
          ),
          NexPayStatItem(
            label: 'Total Payout Volume',
            value:
            'Rs. ${_currencyFormat.format(pendingVolume + completedVolume)}',
            sublabel: '${payouts.length} total outward requests',
            icon: Icons.account_balance_rounded,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search TID, Mobile, Bank, IBAN, or Account Title...',
        onSearchChanged: (v) => setState(() => _searchQuery = v.trim()),
        filters: const ['ALL', 'PENDING', 'COMPLETED', 'REJECTED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary:
        'Showing ${filteredList.length} of ${payouts.length} payouts',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1240,
        emptyState: NexPayEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No Payout Transfers Found',
          subtitle: 'No withdrawal requests match your active filter ($_statusFilter).',
        ),
        columns: const [
          DataColumn(label: Text('TIMESTAMP')),
          DataColumn(label: Text('CUSTOMER (SENDER)')),
          DataColumn(label: Text('TARGET BANK / WALLET')),
          DataColumn(label: Text('BENEFICIARY TITLE')),
          DataColumn(label: Text('ACCOUNT / IBAN')),
          DataColumn(label: Text('AMOUNT (PKR)'), numeric: true),
          DataColumn(label: Text('TID')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('EXECUTIVE ACTION')),
        ],
        rows: filteredList.map((raw) {
          final p = Map<String, dynamic>.from(raw as Map);
          final status = (p['status'] ?? 'PENDING').toString().toUpperCase();
          final isPending = status == 'PENDING';
          final isCompleted = status == 'COMPLETED' || status == 'ACCEPTED';
          final amount =
              double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
          final dateStr = _formatTimestamp(p['created_at']);
          final accountNo = (p['beneficiary_account'] ?? '-').toString();
          final tid = (p['tid'] ?? '-').toString();

          return DataRow(
            cells: [
              DataCell(Text(dateStr,
                  style: TextStyle(
                      color: AppConstants.textMuted, fontSize: 12))),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (p['sender_name'] ?? 'Customer').toString(),
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    Text(
                      (p['sender_mobile'] ?? '-').toString(),
                      style: TextStyle(
                          color: AppConstants.accentBlue,
                          fontSize: 11.5,
                          fontFamily: 'Consolas'),
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    (p['target_bank'] ?? 'Bank').toString(),
                    style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5),
                  ),
                ),
              ),
              DataCell(
                Text(
                  (p['beneficiary_title'] ?? '-').toString(),
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5),
                ),
              ),
              DataCell(
                NexPayCopyableId(text: accountNo, label: 'Account/IBAN'),
              ),
              DataCell(
                Text(
                  'Rs. ${_currencyFormat.format(amount)}',
                  style: TextStyle(
                    color: AppConstants.dangerRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              DataCell(NexPayCopyableId(text: tid, label: 'TID')),
              DataCell(
                NexPayStatusBadge(
                  status: isPending
                      ? 'PENDING DISPATCH'
                      : (isCompleted ? 'COMPLETED' : 'REJECTED & REFUNDED'),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPending) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                        ),
                        onPressed: () =>
                            _confirmCompletePayout(context, p, admin),
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: const Text('Accept',
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
                        onPressed: () =>
                            _confirmRejectAndRefund(context, p, admin),
                        icon: const Icon(Icons.close_rounded, size: 15),
                        label: const Text('Reject',
                            style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    IconButton(
                      tooltip: 'Inspect Full Payout Ticket',
                      icon: Icon(Icons.open_in_new_rounded,
                          size: 18, color: AppConstants.textSecondary),
                      onPressed: () =>
                          _openPayoutInspector(context, p, admin),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openPayoutInspector(
      BuildContext context, Map<String, dynamic> p, AdminProvider admin) {
    final status = (p['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';
    final amount = double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
    final tid = (p['tid'] ?? '-').toString();

    showNexPayInspectorDrawer(
      context: context,
      title: 'Payout Dispatch Ticket',
      subtitle: 'TID: $tid • ${p['target_bank'] ?? 'Bank'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISPATCH AMOUNT',
                  style: TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_currencyFormat.format(amount)}',
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                NexPayStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NexPayDetailSection(
            title: 'Beneficiary Bank Coordinates',
            children: [
              NexPayKeyValueRow(
                  label: 'Target Bank',
                  value: (p['target_bank'] ?? '-').toString()),
              NexPayKeyValueRow(
                  label: 'Account Title',
                  value: (p['beneficiary_title'] ?? '-').toString(),
                  copyable: true),
              NexPayKeyValueRow(
                  label: 'Account / IBAN',
                  value: (p['beneficiary_account'] ?? '-').toString(),
                  copyable: true),
            ],
          ),
          NexPayDetailSection(
            title: 'Originating Customer',
            children: [
              NexPayKeyValueRow(
                  label: 'Sender Name',
                  value: (p['sender_name'] ?? 'Customer').toString()),
              NexPayKeyValueRow(
                  label: 'Sender Mobile',
                  value: (p['sender_mobile'] ?? '-').toString(),
                  copyable: true),
              NexPayKeyValueRow(
                  label: 'Transaction TID', value: tid, copyable: true),
              NexPayKeyValueRow(
                  label: 'Submitted At',
                  value: _formatTimestamp(p['created_at'])),
            ],
          ),
        ],
      ),
      footerActions: isPending
          ? [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.dangerRed),
          onPressed: () {
            Navigator.pop(context);
            _confirmRejectAndRefund(context, p, admin);
          },
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Reject & Auto-Refund'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _confirmCompletePayout(context, p, admin);
          },
          icon: const Icon(Icons.check_rounded, size: 17),
          label: const Text('Accept & Mark Completed'),
        ),
      ]
          : [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
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

  Future<void> _confirmCompletePayout(
      BuildContext context, dynamic payout, AdminProvider admin) async {
    final amount = double.tryParse(payout['amount']?.toString() ?? '0') ?? 0;
    final confirmed = await showNexPayConfirmDialog(
      context: context,
      title: 'Complete Bank Transfer',
      message:
      'Have you dispatched Rs. ${_currencyFormat.format(amount)} to ${payout['beneficiary_title']} (${payout['beneficiary_account']})?\n\nThis will mark the payout as COMPLETED.',
      confirmLabel: 'Yes, Mark Completed',
      icon: Icons.check_circle_rounded,
    );
    if (!confirmed || !context.mounted) return;

    final id = int.tryParse(payout['id']?.toString() ?? '0') ?? 0;
    final tid = payout['tid']?.toString() ?? '';
    final success = await admin.completePayout(id, tid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          success ? AppConstants.accentGreen : AppConstants.dangerRed,
          content: Text(success
              ? 'Payout #$tid marked as Completed!'
              : 'Failed to update payout.'),
        ),
      );
    }
  }

  Future<void> _confirmRejectAndRefund(
      BuildContext context, dynamic payout, AdminProvider admin) async {
    final amount = double.tryParse(payout['amount']?.toString() ?? '0') ?? 0.0;
    final senderMobile = payout['sender_mobile']?.toString() ?? '';
    final tid = payout['tid']?.toString() ?? '';

    final confirmed = await showNexPayConfirmDialog(
      context: context,
      title: 'Reject & Auto-Refund',
      message:
      'Are you sure you want to REJECT payout TID: $tid?\n\nRs. ${_currencyFormat.format(amount)} will be automatically credited back into customer\'s ($senderMobile) primary wallet ledger.',
      confirmLabel: 'Reject & Refund Funds',
      confirmColor: AppConstants.dangerRed,
      icon: Icons.warning_amber_rounded,
    );
    if (!confirmed || !context.mounted) return;

    final id = int.tryParse(payout['id']?.toString() ?? '0') ?? 0;
    final success = await admin.rejectPayout(id, tid, senderMobile, amount);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          success ? AppConstants.accentGreen : AppConstants.dangerRed,
          content: Text(success
              ? 'Payout rejected. Rs. ${_currencyFormat.format(amount)} refunded to $senderMobile!'
              : 'Failed to refund payout.'),
        ),
      );
    }
  }
}