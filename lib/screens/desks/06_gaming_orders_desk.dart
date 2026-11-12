import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
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
      final amt = double.tryParse(
          raw['amount']?.toString() ?? raw['price']?.toString() ?? '0') ??
          0;
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
      if (_statusFilter == 'COMPLETED' &&
          !(st == 'COMPLETED' || st == 'APPROVED' || st == 'DELIVERED')) {
        return false;
      }
      if (_statusFilter == 'REJECTED' && st != 'REJECTED') return false;

      if (_query.isEmpty) return true;
      final hay =
      '${raw['order_id']} ${raw['id']} ${raw['user_mobile']} ${raw['title']} ${raw['package']} ${raw['player_id']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Gaming Top-Ups & Digital Voucher Fulfillment',
        subtitle:
        'Process PUBG UC, Free Fire Diamonds, and digital gift cards or issue instant wallet refunds',
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
        resultSummary:
        'Showing ${filtered.length} of ${orders.length} orders',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const NexPayEmptyState(
          icon: Icons.sports_esports_rounded,
          title: 'No Gaming or Voucher Orders Found',
          subtitle:
          'There are no digital shop orders matching your filter in the live database.',
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
          final pkg = (o['title'] ??
              o['package'] ??
              o['product_name'] ??
              'Digital Voucher')
              .toString();
          final playerId =
          (o['player_id'] ?? o['target_id'] ?? o['account_id'] ?? '-')
              .toString();
          final amt = double.tryParse(
              o['amount']?.toString() ?? o['price']?.toString() ?? '0') ??
              0;
          final date = (o['created_at'] ?? o['date'] ?? '-').toString();
          final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
          final isPending = status == 'PENDING';

          return DataRow(
            cells: [
              DataCell(NexPayCopyableId(text: '#$orderId', label: 'Order ID')),
              DataCell(
                Text(mobile,
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              DataCell(
                Text(pkg,
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w700)),
              ),
              DataCell(
                playerId != '-'
                    ? NexPayCopyableId(text: playerId, label: 'Player UID')
                    : Text('-',
                    style: TextStyle(color: AppConstants.textMuted)),
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
              DataCell(
                Text(date,
                    style: TextStyle(
                        color: AppConstants.textMuted, fontSize: 12)),
              ),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => _openOrderDrawer(context, admin, o),
                  icon: Icon(Icons.bolt_rounded,
                      size: 15,
                      color: isPending
                          ? AppConstants.accentGreen
                          : AppConstants.textSecondary),
                  label: Text(isPending ? 'Fulfill' : 'Details'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openOrderDrawer(
      BuildContext context, AdminProvider admin, Map<String, dynamic> o) {
    final orderId = (o['order_id'] ?? o['id'] ?? '').toString();
    final mobile = (o['user_mobile'] ?? o['mobile'] ?? '').toString();
    final pkg = (o['title'] ??
        o['package'] ??
        o['product_name'] ??
        'Digital Voucher')
        .toString();
    final playerId =
    (o['player_id'] ?? o['target_id'] ?? o['account_id'] ?? '-')
        .toString();
    final amt = double.tryParse(
        o['amount']?.toString() ?? o['price']?.toString() ?? '0') ??
        0;
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
                Text(pkg,
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rs. ${_money.format(amt)}',
                    style: TextStyle(
                        color: AppConstants.accentGreen,
                        fontSize: 23,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                NexPayStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NexPayDetailSection(
            title: 'Fulfillment Target & Order Info',
            children: [
              NexPayKeyValueRow(
                  label: 'Player UID / Target',
                  value: playerId,
                  copyable: playerId != '-'),
              NexPayKeyValueRow(
                  label: 'Customer Mobile', value: mobile, copyable: true),
              NexPayKeyValueRow(
                  label: 'Order Reference', value: orderId, copyable: true),
              NexPayKeyValueRow(
                  label: 'Submitted Time',
                  value: (o['created_at'] ?? o['date'] ?? '-').toString()),
            ],
          ),
        ],
      ),
      footerActions: isPending
          ? [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.dangerRed),
          onPressed: () async {
            final confirmed = await showNexPayConfirmDialog(
              context: context,
              title: 'Reject & Refund Order',
              message:
              'Reject order #$orderId and refund Rs. ${_money.format(amt)} back to $mobile?',
              confirmLabel: 'Reject & Refund',
              confirmColor: AppConstants.dangerRed,
              icon: Icons.replay_rounded,
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.reviewVoucherOrder(
                orderId, 'REJECTED', mobile, amt);
            if (context.mounted) {
              _toast(
                  context,
                  ok
                      ? 'Order #$orderId rejected & Rs. ${_money.format(amt)} refunded.'
                      : 'Action failed.',
                  ok);
            }
          },
          icon: const Icon(Icons.replay_rounded, size: 17),
          label: const Text('Reject & Refund'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final confirmed = await showNexPayConfirmDialog(
              context: context,
              title: 'Confirm Top-Up Delivery',
              message:
              'Mark $pkg for Player ID ($playerId) as COMPLETED?',
              confirmLabel: 'Mark Delivered',
              icon: Icons.check_circle_rounded,
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.reviewVoucherOrder(
                orderId, 'COMPLETED', mobile, amt);
            if (context.mounted) {
              _toast(
                  context,
                  ok
                      ? 'Order #$orderId marked COMPLETED!'
                      : 'Action failed.',
                  ok);
            }
          },
          icon: const Icon(Icons.check_circle_rounded, size: 17),
          label: const Text('Mark Top-Up Delivered'),
        ),
      ]
          : [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
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