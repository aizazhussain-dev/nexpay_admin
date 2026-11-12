import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class GoldDispatchDeskScreen extends StatefulWidget {
  const GoldDispatchDeskScreen({super.key});

  @override
  State<GoldDispatchDeskScreen> createState() => _GoldDispatchDeskScreenState();
}

class _GoldDispatchDeskScreenState extends State<GoldDispatchDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  String _statusFilter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _extractGoldOrders(AdminProvider admin) {
    final List orders = [];

    admin.users.forEach((mobile, rawUser) {
    if (rawUser is! Map) return;
    final customerName = (rawUser['name'] ?? 'Bullion Client').toString();
    final defaultAddress = (rawUser['address'] ?? '').toString();
    final txs = rawUser['transactions'] ?? rawUser['history'] ?? [];

    if (txs is List) {
    for (final item in txs) {
    if (item is! Map) continue;
    final type = (item['type'] ?? item['category'] ?? '').toString().toUpperCase();
    final title = (item['title'] ?? item['note'] ?? '').toString().toLowerCase();
    final isGoldDispatch = type.contains('GOLD_DELIV') ||
    type.contains('GOLD_DISPATCH') ||
    type.contains('PHYSICAL_GOLD') ||
    title.contains('gold delivery') ||
    title.contains('physical gold') ||
    title.contains('bullion dispatch');

    if (!isGoldDispatch) continue;

    final tid = (item['tid'] ?? item['id'] ?? '').toString();
    final grams = double.tryParse(item['grams']?.toString() ?? item['goldGrams']?.toString() ?? '0') ?? 0;
    final fee = double.tryParse(item['fee']?.toString() ?? item['deliveryFee']?.toString() ?? item['amount']?.toString() ?? '0') ?? 0;
    final address = (item['deliveryAddress'] ?? item['shipping_address'] ?? item['address'] ?? defaultAddress).toString();
    final tracking = (item['tracking'] ?? item['trackingId'] ?? item['courier_tracking'] ?? '').toString();
    final status = (item['status'] ?? 'PENDING').toString().toUpperCase();
    final date = (item['date'] ?? item['created_at'] ?? '-').toString();

    orders.add({
    'tid': tid,
    'mobile': mobile,
    'customerName': customerName,
    'grams': grams,
    'fee': fee.abs(),
    'address': address.isEmpty ? 'Address not specified' : address,
    'tracking': tracking,
    'status': status,
    'date': date,
    });
    }
    }
    });

    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final orders = _extractGoldOrders(admin);

    double totalVaultGrams = 0;
    admin.users.forEach((_, u) {
      if (u is Map) {
        totalVaultGrams += double.tryParse(u['goldGrams']?.toString() ?? u['gold']?.toString() ?? '0') ?? 0;
      }
    });

    int pendingCount = 0;
    double pendingGrams = 0;
    int dispatchedCount = 0;
    double dispatchedGrams = 0;

    for (final o in orders) {
      final st = o['status'].toString();
      final g = (o['grams'] as double?) ?? 0;
      if (st == 'PENDING' || st == 'PROCESSING') {
        pendingCount++;
        pendingGrams += g;
      } else if (st == 'DISPATCHED' || st == 'COMPLETED' || st == 'DELIVERED') {
        dispatchedCount++;
        dispatchedGrams += g;
      }
    }

    final filtered = orders.where((o) {
      final st = o['status'].toString();
      if (_statusFilter == 'PENDING' && !(st == 'PENDING' || st == 'PROCESSING')) return false;
      if (_statusFilter == 'DISPATCHED' && !(st == 'DISPATCHED' || st == 'COMPLETED' || st == 'DELIVERED')) return false;
      if (_statusFilter == 'REJECTED' && !st.contains('REJECT')) return false;

      if (_query.isEmpty) return true;
      final hay = '${o['tid']} ${o['customerName']} ${o['mobile']} ${o['address']} ${o['tracking']}'.toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: '24K Physical Gold Mint & Courier Dispatch',
        subtitle: 'Fulfill physical 999.9 bullion redemption requests, assign insured courier tracking, or refund grams',
        badgeText: 'BULLION LOGISTICS',
        badgeColor: AppConstants.accentGold,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Bullion Queue'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Pending Mint Dispatch',
            value: '$pendingCount Parcels',
            sublabel: '${pendingGrams.toStringAsFixed(3)} g 24K gold awaiting courier',
            icon: Icons.inventory_2_outlined,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Dispatched & Insured',
            value: '$dispatchedCount Shipped',
            sublabel: '${dispatchedGrams.toStringAsFixed(3)} g delivered via armored post',
            icon: Icons.local_shipping_outlined,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Total Customer Vault Reserve',
            value: '${totalVaultGrams.toStringAsFixed(3)} g',
            sublabel: 'Aggregate digital 24K holdings',
            icon: Icons.diamond_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Total Redemption Orders',
            value: '${orders.length} Requests',
            sublabel: 'Live smartvest.tech bullion ledger',
            icon: Icons.verified_outlined,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search by TID, customer name, mobile, city/address, or tracking ID...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'PENDING', 'DISPATCHED', 'REJECTED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary: 'Showing ${filtered.length} of ${orders.length} bullion orders',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1160,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.diamond_outlined,
          title: 'No Physical Gold Dispatch Orders',
          subtitle: 'There are no physical 24K bullion delivery requests matching your filter in the live database.',
        ),
        columns: const [
          DataColumn(label: Text('ORDER TID')),
          DataColumn(label: Text('CLIENT & MOBILE')),
          DataColumn(label: Text('BULLION WEIGHT'), numeric: true),
          DataColumn(label: Text('DELIVERY FEE'), numeric: true),
          DataColumn(label: Text('SHIPPING DESTINATION')),
          DataColumn(label: Text('COURIER TRACKING')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('LOGISTICS')),
        ],
        rows: filtered.map((o) {
          final tid = o['tid'].toString();
          final mobile = o['mobile'].toString();
          final name = o['customerName'].toString();
          final grams = (o['grams'] as double?) ?? 0;
          final fee = (o['fee'] as double?) ?? 0;
          final address = o['address'].toString();
          final tracking = o['tracking'].toString();
          final status = o['status'].toString();
          final isPending = status == 'PENDING' || status == 'PROCESSING';

          return DataRow(
            cells: [
              DataCell(Text(tid, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppConstants.accentBlue))),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(mobile, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              DataCell(
                Text(
                  '${grams.toStringAsFixed(3)} g (24K)',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGold),
                ),
              ),
              DataCell(Text('Rs. ${_money.format(fee)}', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(
                SizedBox(
                  width: 240,
                  child: Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
              DataCell(
                Text(
                  tracking.isEmpty ? 'Awaiting Dispatch' : tracking,
                  style: TextStyle(
                    fontFamily: tracking.isEmpty ? null : 'monospace',
                    fontWeight: FontWeight.w600,
                    color: tracking.isEmpty ? AppConstants.textMuted : AppConstants.accentGreen,
                  ),
                ),
              ),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => _openDispatchDrawer(context, admin, o),
                  icon: const Icon(Icons.local_shipping_outlined, size: 15),
                  label: Text(isPending ? 'Dispatch' : 'Inspect'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openDispatchDrawer(BuildContext context, AdminProvider admin, Map<String, dynamic> o) {
    final tid = o['tid'].toString();
    final mobile = o['mobile'].toString();
    final name = o['customerName'].toString();
    final grams = (o['grams'] as double?) ?? 0;
    final fee = (o['fee'] as double?) ?? 0;
    final address = o['address'].toString();
    final status = o['status'].toString();
    final isPending = status == 'PENDING' || status == 'PROCESSING';
    final trackingCtrl = TextEditingController(text: o['tracking'].toString());

    showNexPayInspectorDrawer(
      context: context,
      title: '24K Bullion Dispatch: $tid',
      subtitle: '$name ($mobile)',
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
                const Text('MINT BAR ALLOCATION', style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${grams.toStringAsFixed(3)} Grams 24K Bullion', style: const TextStyle(color: AppConstants.accentGold, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Courier & Minting Fee Paid: Rs. ${_money.format(fee)}', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _kv('Delivery Destination Address', address)),
              IconButton(
                tooltip: 'Copy Address',
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppConstants.accentBlue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: address));
                  _toast(context, 'Shipping address copied.', true);
                },
              ),
            ],
          ),
          _kv('Order Date', o['date'].toString()),
          _kv('Current Logistics Status', status),
          const SizedBox(height: 12),
          const Text('INSURED COURIER TRACKING NUMBER (TCS / LEOPARDS / M&P)', style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: trackingCtrl,
            readOnly: !isPending,
            decoration: const InputDecoration(
              hintText: 'Enter courier tracking ID e.g. TCS-884920192',
              prefixIcon: Icon(Icons.qr_code_rounded, size: 18),
            ),
          ),
        ],
      ),
      footerActions: isPending
          ? [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppConstants.dangerRed),
          onPressed: () async {
            Navigator.pop(context);
            final ok = await admin.rejectGoldDelivery(mobile, tid, grams, fee);
            if (context.mounted) {
              _toast(context, ok ? 'Dispatch rejected; ${grams.toStringAsFixed(3)}g + Rs. ${_money.format(fee)} refunded.' : 'Action failed.', ok);
            }
          },
          icon: const Icon(Icons.replay_rounded, size: 17),
          label: const Text('Reject & Refund Gold'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final trk = trackingCtrl.text.trim();
            if (trk.isEmpty) {
              _toast(context, 'Please enter a valid courier tracking number first.', false);
              return;
            }
            Navigator.pop(context);
            final ok = await admin.dispatchGoldDelivery(mobile, tid, trk);
            if (context.mounted) {
              _toast(context, ok ? 'Bullion dispatched with tracking $trk!' : 'Dispatch update failed.', ok);
            }
          },
          icon: const Icon(Icons.local_shipping_rounded, size: 17),
          label: const Text('Confirm Dispatch'),
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
          Text(v, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
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