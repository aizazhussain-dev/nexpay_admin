import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class OutwardLedgerDeskScreen extends StatefulWidget {
  const OutwardLedgerDeskScreen({super.key});

  @override
  State<OutwardLedgerDeskScreen> createState() =>
      _OutwardLedgerDeskScreenState();
}

class _OutwardLedgerDeskScreenState extends State<OutwardLedgerDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  String _typeFilter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _extractAllLedgerEntries(AdminProvider admin) {
    final List rows = [];
    final Set<String> seenTids = {};

    // 1. Extract live transactions embedded inside customer records
    admin.users.forEach((mobile, userRaw) {
    if (userRaw is! Map) return;
    final userName = (userRaw['name'] ?? 'Customer').toString();
    final txRaw = userRaw['transactions'] ?? userRaw['history'] ?? [];
    if (txRaw is List) {
    for (final item in txRaw) {
    if (item is! Map) continue;
    final tid = (item['tid'] ?? item['id'] ?? '').toString();
    final type = (item['type'] ?? item['category'] ?? 'TRANSFER')
        .toString()
        .toUpperCase();
    final amount =
    double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    final recipient = (item['recipientMobile'] ??
    item['to'] ??
    item['recipient'] ??
    '-')
        .toString();
    final date = (item['date'] ??
    item['created_at'] ??
    item['timestamp'] ??
    '-')
        .toString();
    final status =
    (item['status'] ?? 'COMPLETED').toString().toUpperCase();
    final note =
    (item['note'] ?? item['title'] ?? item['description'] ?? type)
        .toString();

    final key = '${tid}_${mobile}_$amount';
    if (tid.isNotEmpty) seenTids.add(tid);

    rows.add({
    'key': key,
    'tid': tid.isEmpty ? 'LEDGER-${rows.length + 1}' : tid,
    'senderMobile': mobile,
    'senderName': userName,
    'recipientMobile': recipient,
    'type': type,
    'amount': amount.abs(),
    'date': date,
    'status': status,
    'note': note,
    });
    }
    }
    });

    // 2. Include outward IBFT payouts not already listed
    for (final p in admin.payouts) {
    if (p is! Map) continue;
    final tid = (p['tid'] ?? 'PAY-${p['id']}').toString();
    if (seenTids.contains(tid)) continue;
    rows.add({
    'key': 'payout_$tid',
    'tid': tid,
    'senderMobile': (p['sender_mobile'] ?? '-').toString(),
    'senderName': (p['beneficiary_title'] ?? 'IBFT Payout').toString(),
    'recipientMobile':
    '${p['target_bank'] ?? 'Bank'} (${p['beneficiary_account'] ?? '-'})',
    'type': 'BANK_PAYOUT',
    'amount': double.tryParse(p['amount']?.toString() ?? '0') ?? 0,
    'date': (p['created_at'] ?? p['date'] ?? '-').toString(),
    'status': (p['status'] ?? 'PENDING').toString().toUpperCase(),
    'note': 'Interbank Outward Settlement',
    });
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final entries = _extractAllLedgerEntries(admin);

    double totalVolume = 0;
    int reversedCount = 0;
    int p2pCount = 0;

    for (final e in entries) {
      final amt = (e['amount'] as double?) ?? 0;
      final st = (e['status'] ?? '').toString();
      final tp = (e['type'] ?? '').toString();
      totalVolume += amt;
      if (st.contains('REVERS')) reversedCount++;
      if (tp.contains('SEND') ||
          tp.contains('TRANSFER') ||
          tp.contains('P2P')) {
        p2pCount++;
      }
    }

    final filtered = entries.where((e) {
      final tp = (e['type'] ?? '').toString();
      final st = (e['status'] ?? '').toString();
      if (_typeFilter == 'REVERSED' && !st.contains('REVERS')) return false;
      if (_typeFilter == 'PAYOUT' && !tp.contains('PAYOUT')) return false;
      if (_typeFilter == 'P2P' &&
          !(tp.contains('SEND') ||
              tp.contains('TRANSFER') ||
              tp.contains('P2P'))) {
        return false;
      }
      if (_query.isEmpty) return true;
      final hay =
      '${e['tid']} ${e['senderMobile']} ${e['senderName']} ${e['recipientMobile']} ${e['note']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Master Outward Ledger & Transaction Reversals',
        subtitle:
        'Forensic stream of P2P transfers, outward bank settlements, and dispute chargeback reversals',
        badgeText: 'IMMUTABLE LEDGER',
        badgeColor: AppConstants.accentBlue,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Master Ledger'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Total Ledger Entries',
            value: '${entries.length} Records',
            sublabel: 'Live cross-wallet transaction feed',
            icon: Icons.receipt_long_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Gross Ledger Volume',
            value: 'Rs. ${_money.format(totalVolume)}',
            sublabel: 'Cumulative audited throughput',
            icon: Icons.account_balance_wallet_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'P2P Wallet Transfers',
            value: '$p2pCount Transfers',
            sublabel: 'Instant NexPay-to-NexPay rails',
            icon: Icons.swap_horiz_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Reversed Disputes',
            value: '$reversedCount Reversals',
            sublabel: 'Clawed-back & refunded transactions',
            icon: Icons.undo_rounded,
            color: AppConstants.dangerRed,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint:
        'Search by TID, sender mobile, name, recipient, or note...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'P2P', 'PAYOUT', 'REVERSED'],
        selectedFilter: _typeFilter,
        onFilterChanged: (f) => setState(() => _typeFilter = f),
        resultSummary:
        'Showing ${filtered.length} of ${entries.length} ledger rows',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1180,
        emptyState: const NexPayEmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No Ledger Transactions Found',
          subtitle:
          'No live wallet transactions match your search or filter criteria.',
        ),
        columns: const [
          DataColumn(label: Text('TID / REFERENCE')),
          DataColumn(label: Text('ORIGINATING ACCOUNT')),
          DataColumn(label: Text('RECIPIENT / DESTINATION')),
          DataColumn(label: Text('RAIL / TYPE')),
          DataColumn(label: Text('AMOUNT (PKR)'), numeric: true),
          DataColumn(label: Text('TIMESTAMP')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('FORENSIC ACTION')),
        ],
        rows: filtered.map((e) {
          final tid = e['tid'].toString();
          final senderMobile = e['senderMobile'].toString();
          final senderName = e['senderName'].toString();
          final recipient = e['recipientMobile'].toString();
          final type = e['type'].toString();
          final amt = (e['amount'] as double?) ?? 0;
          final date = e['date'].toString();
          final status = e['status'].toString();
          final isReversed = status.contains('REVERS');

          return DataRow(
            cells: [
              DataCell(NexPayCopyableId(text: tid, label: 'TID')),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(senderName,
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(senderMobile,
                        style: TextStyle(
                            color: AppConstants.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              DataCell(Text(recipient,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5))),
              DataCell(
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: Text(type,
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              DataCell(
                Text(
                  'Rs. ${_money.format(amt)}',
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              DataCell(Text(date,
                  style: TextStyle(
                      color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () =>
                      _openTransactionInspector(context, admin, e),
                  icon: Icon(
                    isReversed
                        ? Icons.visibility_outlined
                        : Icons.undo_rounded,
                    size: 15,
                    color: isReversed
                        ? AppConstants.textSecondary
                        : AppConstants.dangerRed,
                  ),
                  label: Text(isReversed ? 'Details' : 'Inspect / Reverse'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openTransactionInspector(
      BuildContext context, AdminProvider admin, Map<String, dynamic> e) {
    final tid = e['tid'].toString();
    final senderMobile = e['senderMobile'].toString();
    final senderName = e['senderName'].toString();
    final recipient = e['recipientMobile'].toString();
    final amt = (e['amount'] as double?) ?? 0;
    final status = e['status'].toString();
    final isReversed = status.contains('REVERS');

    showNexPayInspectorDrawer(
      context: context,
      title: 'Forensic Ledger Record',
      subtitle: 'TID: $tid • ${e['type']}',
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
                Text('SETTLED TRANSACTION VALUE',
                    style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rs. ${_money.format(amt)}',
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                NexPayStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NexPayDetailSection(
            title: 'Settlement Audit Trail',
            children: [
              NexPayKeyValueRow(
                  label: 'Transaction TID', value: tid, copyable: true),
              NexPayKeyValueRow(
                  label: 'Sender Name', value: senderName),
              NexPayKeyValueRow(
                  label: 'Sender Mobile', value: senderMobile, copyable: true),
              NexPayKeyValueRow(
                  label: 'Recipient / Target', value: recipient, copyable: true),
              NexPayKeyValueRow(
                  label: 'Ledger Narration', value: e['note'].toString()),
              NexPayKeyValueRow(
                  label: 'Timestamp', value: e['date'].toString()),
            ],
          ),
          if (!isReversed)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.dangerRedLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppConstants.dangerRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Warning: Reversing this transaction will debit the recipient (if internal P2P) and restore the principal amount back to the sender wallet.',
                style: TextStyle(
                    color: AppConstants.dangerRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      footerActions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        if (!isReversed && amt > 0)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.dangerRed),
            onPressed: () async {
              final confirmed = await showNexPayConfirmDialog(
                context: context,
                title: 'Execute Ledger Reversal',
                message:
                'Reverse transaction $tid for Rs. ${_money.format(amt)} and restore funds to $senderMobile?',
                confirmLabel: 'Confirm Reversal',
                confirmColor: AppConstants.dangerRed,
                icon: Icons.undo_rounded,
              );
              if (!confirmed || !context.mounted) return;
              Navigator.pop(context);
              final recipientMob =
              RegExp(r'^03\d{9}$').hasMatch(recipient.trim())
                  ? recipient.trim()
                  : '';
              final ok = await admin.reverseTransaction(
                senderMobile: senderMobile,
                tid: tid,
                amount: amt,
                recipientMobile: recipientMob,
              );
              if (context.mounted) {
                _toast(
                    context,
                    ok
                        ? 'Transaction $tid reversed successfully.'
                        : 'Reversal rejected by server.',
                    ok);
              }
            },
            icon: const Icon(Icons.undo_rounded, size: 17),
            label: const Text('Execute Reversal'),
          ),
      ],
    );
  }

  void _toast(BuildContext context, String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor:
          ok ? AppConstants.accentGreen : AppConstants.dangerRed),
    );
  }
}