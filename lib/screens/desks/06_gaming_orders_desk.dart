import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class GamingOrdersDeskScreen extends StatefulWidget {
  const GamingOrdersDeskScreen({super.key});

  @override
  State<GamingOrdersDeskScreen> createState() => _GamingOrdersDeskScreenState();
}

class _GamingOrdersDeskScreenState extends State<GamingOrdersDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  String _statusFilter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final orders = admin.voucherOrders;

    int pendingCount = 0;
    double pendingSales = 0;
    int completedCount = 0;
    double completedSales = 0;
    int rejectedCount = 0;

    for (final raw in orders) {
      if (raw is! Map) continue;
      final st = (raw['status'] ?? 'PENDING').toString().toUpperCase();
      final amt = double.tryParse(raw['amount']?.toString() ?? raw['price']?.toString() ?? '0') ?? 0;
      if (st == 'PENDING') {
        pendingCount++;
        pendingSales += amt;
      } else if (st == 'COMPLETED' || st == 'APPROVED' || st == 'DELIVERED') {
        completedCount++;
        completedSales += amt;
      } else {
        rejectedCount++;
      }
    }

    final filtered = orders.where((raw) {
      if (raw is! Map) return false;
      final st = (raw['status'] ?? 'PENDING').toString().toUpperCase();
      if (_statusFilter == 'PENDING' && st != 'PENDING') return false;
      if (_statusFilter == 'COMPLETED' && !(st == 'COMPLETED' || st == 'APPROVED' || st == 'DELIVERED')) return false;
      if (_statusFilter == 'REJECTED' && st != 'REJECTED') return false;

      if (_query.isEmpty) return true;
      final hay = '${raw['order_id']} ${raw['id']} ${raw['user_mobile']} ${raw['title']} ${raw['package']} ${raw['player_id']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Gaming Top-Ups & Digital Voucher Fulfillment',
        subtitle: 'Process PUBG UC, Free Fire Diamonds, and digital gift cards or issue instant wallet refunds',
        badgeText: 'DIGITAL FULFILLMENT',
        badgeColor: AppConstants.accentBlue,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Voucher Queue'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Pending Top-Ups',
            value: '$pendingCount Orders',
            sublabel: 'Rs. ${_money.format(pendingSales)} awaiting delivery',
            icon: Icons.hourglass_bottom_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Fulfilled Vouchers',
            value: '$completedCount Delivered',
            sublabel: 'Rs. ${_money.format(completedSales)} settled volume',
            icon: Icons.sports_esports_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Cancelled / Refunded',
            value: '$rejectedCount Refunded',
            sublabel: 'Amount restored to user wallets',
            icon: Icons.replay_rounded,
            color: AppConstants.dangerRed,
          ),
          NexPayStatItem(
            label: 'Total Digital Sales',
            value: 'Rs. ${_money.format(pendingSales + completedSales)}',
            sublabel: '${orders.length} total digital shop orders',
            icon: Icons.shopping_bag_outlined,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search by order ID, mobile, game title, or Player UID...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'PENDING', 'COMPLETED', 'REJECTED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary: 'Showing ${filtered.length} of ${orders.length} orders',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.sports_esports_rounded,
          title: 'No Gaming or Voucher Orders Found',
          subtitle: 'There are no digital shop orders matching your filter in the live database.',
        ),
        columns: const [
          DataColumn(label: Text('ORDER ID')),
          DataColumn(label: Text('CUSTOMER MOBILE')),
          DataColumn(label: Text('PRODUCT / PACKAGE')),
          DataColumn(label: Text('PLAYER UID / TARGET')),
          DataColumn(label: Text('AMOUNT (PKR)'), numeric: true),
          DataColumn(label: Text('ORDER DATE')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('FULFILLMENT')),
        ],
        rows: filtered.map((raw) {
          final o = Map<String, dynamic>.from(raw as Map);
          final orderId = (o['order_id'] ?? o['id'] ?? '').toString();
          final mobile = (o['user_mobile'] ?? o['mobile'] ?? '-').toString();
          final pkg = (o['title'] ?? o['package'] ?? o['product_name'] ?? 'Digital Voucher').toString();
          final playerId = (o['player_id'] ?? o['target_id'] ?? o['account_id'] ?? '-').toString();
          final amt = double.tryParse(o['amount']?.toString() ?? o['price']?.toString() ?? '0') ?? 0;
          final date = (o['created_at'] ?? o['date'] ?? '-').toString();
          final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
          final isPending = status == 'PENDING';

          return DataRow(
            cells: [
              DataCell(Text('#$orderId', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppConstants.accentBlue))),
              DataCell(Text(mobile, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(pkg, style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(playerId, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                    if (playerId != '-')
                      IconButton(
                        tooltip: 'Copy Player ID',
                        icon: const Icon(Icons.copy_rounded, size: 15, color: AppConstants.textMuted),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: playerId));
                          _toast(context, 'Player ID copied.', true);
                        },
                      ),
                  ],
                ),
              ),
              DataCell(Text('Rs. ${_money.format(amt)}', style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text(date, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => _openOrderDrawer(context, admin, o),
                  icon: const Icon(Icons.bolt_rounded, size: 15),
                  label: Text(isPending ? 'Fulfill' : 'Details'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openOrderDrawer(BuildContext context, AdminProvider admin, Map<String, dynamic> o) {
    final orderId = (o['order_id'] ?? o['id'] ?? '').toString();
    final mobile = (o['user_mobile'] ?? o['mobile'] ?? '').toString();
    final pkg = (o['title'] ?? o['package'] ?? o['product_name'] ?? 'Digital Voucher').toString();
    final playerId = (o['player_id'] ?? o['target_id'] ?? o['account_id'] ?? '-').toString();
    final amt = double.tryParse(o['amount']?.toString() ?? o['price']?.toString() ?? '0') ?? 0;
    final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';

    showNexPayInspectorDrawer(
      context: context,
      title: 'Digital Order #$orderId',
      subtitle: '$pkg • $mobile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rs. ${_money.format(amt)}', style: const TextStyle(color: AppConstants.accentGreen, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                NexPayStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _kv('Player UID / Target Account', playerId),
          _kv('Customer NexPay Mobile', mobile),
          _kv('Order Reference', orderId),
          _kv('Submitted Timestamp', (o['created_at'] ?? o['date'] ?? '-').toString()),
        ],
      ),
      footerActions: isPending
          ? [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppConstants.dangerRed),
          onPressed: () async {
            Navigator.pop(context);
            final ok = await admin.reviewVoucherOrder(orderId, 'REJECTED', mobile, amt);
            if (context.mounted) {
              _toast(context, ok ? 'Order #$orderId rejected & Rs. ${_money.format(amt)} refunded.' : 'Action failed.', ok);
            }
          },
          icon: const Icon(Icons.replay_rounded, size: 17),
          label: const Text('Reject & Refund'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await admin.reviewVoucherOrder(orderId, 'COMPLETED', mobile, amt);
            if (context.mounted) {
              _toast(context, ok ? 'Order #$orderId marked COMPLETED!' : 'Action failed.', ok);
            }
          },
          icon: const Icon(Icons.check_circle_rounded, size: 17),
          label: const Text('Mark Top-Up Delivered'),
        ),
      ]
          : [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k.toUpperCase(), style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(v, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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