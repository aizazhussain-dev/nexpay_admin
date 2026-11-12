import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class OutwardLedgerDeskScreen extends StatefulWidget {
  const OutwardLedgerDeskScreen({super.key});

  @override
  State<OutwardLedgerDeskScreen> createState() => _OutwardLedgerDeskScreenState();
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
    final type = (item['type'] ?? item['category'] ?? 'TRANSFER').toString().toUpperCase();
    final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    final recipient = (item['recipientMobile'] ?? item['to'] ?? item['recipient'] ?? '-').toString();
    final date = (item['date'] ?? item['created_at'] ?? item['timestamp'] ?? '-').toString();
    final status = (item['status'] ?? 'COMPLETED').toString().toUpperCase();
    final note = (item['note'] ?? item['title'] ?? item['description'] ?? type).toString();

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
    'recipientMobile': '${p['target_bank'] ?? 'Bank'} (${p['beneficiary_account'] ?? '-'})',
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
      if (tp.contains('SEND') || tp.contains('TRANSFER') || tp.contains('P2P')) p2pCount++;
    }

    final filtered = entries.where((e) {
      final tp = (e['type'] ?? '').toString();
      final st = (e['status'] ?? '').toString();
      if (_typeFilter == 'REVERSED' && !st.contains('REVERS')) return false;
      if (_typeFilter == 'PAYOUT' && !tp.contains('PAYOUT')) return false;
      if (_typeFilter == 'P2P' && !(tp.contains('SEND') || tp.contains('TRANSFER') || tp.contains('P2P'))) {
        return false;
      }
      if (_query.isEmpty) return true;
      final hay = '${e['tid']} ${e['senderMobile']} ${e['senderName']} ${e['recipientMobile']} ${e['note']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Master Outward Ledger & Transaction Reversals',
        subtitle: 'Forensic stream of P2P transfers, outward bank settlements, and dispute chargeback reversals',
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
        searchHint: 'Search by TID, sender mobile, name, recipient, or note...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'P2P', 'PAYOUT', 'REVERSED'],
        selectedFilter: _typeFilter,
        onFilterChanged: (f) => setState(() => _typeFilter = f),
        resultSummary: 'Showing ${filtered.length} of ${entries.length} ledger rows',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1180,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No Ledger Transactions Found',
          subtitle: 'No live wallet transactions match your search or filter criteria.',
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
        rows: filtered.take(250).map((e) {
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
              DataCell(
                Text(
                  tid,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: AppConstants.accentBlue,
                  ),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(senderName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(senderMobile, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              DataCell(Text(recipient, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
              DataCell(
                Text(
                  'Rs. ${_money.format(amt)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              DataCell(Text(date, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => _openTransactionInspector(context, admin, e),
                  icon: Icon(
                    isReversed ? Icons.visibility_outlined : Icons.undo_rounded,
                    size: 15,
                    color: isReversed ? AppConstants.textSecondary : AppConstants.dangerRed,
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

  void _openTransactionInspector(BuildContext context, AdminProvider admin, Map<String, dynamic> e) {
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
                const Text('SETTLED TRANSACTION VALUE', style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rs. ${_money.format(amt)}', style: const TextStyle(color: AppConstants.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                NexPayStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _detailRow('Transaction ID (TID)', tid)),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppConstants.accentBlue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: tid));
                  _toast(context, 'TID copied to clipboard.', true);
                },
              ),
            ],
          ),
          _detailRow('Originating Customer', '$senderName ($senderMobile)'),
          _detailRow('Recipient / Target', recipient),
          _detailRow('Ledger Narration', e['note'].toString()),
          _detailRow('Timestamp', e['date'].toString()),
          if (!isReversed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.dangerRedLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Warning: Reversing this transaction will debit the recipient (if internal P2P) and restore the principal amount back to the sender wallet.',
                style: TextStyle(color: AppConstants.dangerRed, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      footerActions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (!isReversed && amt > 0) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed),
            onPressed: () async {
              Navigator.pop(context);
              final recipientMob = RegExp(r'^03\d{9}$').hasMatch(recipient.trim()) ? recipient.trim() : '';
              final ok = await admin.reverseTransaction(
                senderMobile: senderMobile,
                tid: tid,
                amount: amt,
                recipientMobile: recipientMob,
              );
              if (context.mounted) {
                _toast(context, ok ? 'Transaction $tid reversed successfully.' : 'Reversal rejected by server.', ok);
              }
            },
            icon: const Icon(Icons.undo_rounded, size: 17),
            label: const Text('Execute Reversal'),
          ),
        ],
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
    );
  }
}