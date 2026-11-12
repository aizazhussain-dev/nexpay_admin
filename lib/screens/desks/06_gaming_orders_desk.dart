import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class GamingOrdersDeskScreen extends StatefulWidget {
  const GamingOrdersDeskScreen({super.key});

  @override
  State<GamingOrdersDeskScreen> createState() => _GamingOrdersDeskScreenState();
}

class _GamingOrdersDeskScreenState extends State<GamingOrdersDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, PENDING, ACCEPTED, REJECTED
  String _gameFilter = "ALL"; // ALL, PUBG, FREEFIRE

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final orders = admin.voucherOrders;

    // Filter Logic matching backend
    final filteredList = orders.where((o) {
      final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
      final gameKey = (o['game_key'] ?? '').toString().toUpperCase();

      if (_statusFilter == "PENDING" && status != "PENDING") return false;
      if (_statusFilter == "ACCEPTED" && (status != "ACCEPTED" && status != "FULFILLED")) return false;
      if (_statusFilter == "REJECTED" && status != "REJECTED") return false;

      if (_gameFilter != "ALL" && !gameKey.contains(_gameFilter)) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (o['user_mobile'] ?? '').toString().toLowerCase();
        final name = (o['user_name'] ?? '').toString().toLowerCase();
        final playerId = (o['player_id'] ?? '').toString().toLowerCase();
        final title = (o['voucher_title'] ?? '').toString().toLowerCase();
        final tid = (o['order_tid'] ?? '').toString().toLowerCase();
        return mob.contains(q) || name.contains(q) || playerId.contains(q) || title.contains(q) || tid.contains(q);
      }
      return true;
    }).toList();

    // Financial Counters
    int pendingCount = 0;
    double totalGamingSales = 0;
    double pendingFulfillmentAmt = 0;

    for (var o in orders) {
      final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
      final amt = double.tryParse(o['amount']?.toString() ?? '0') ?? 0.0;
      totalGamingSales += amt;

      if (status == 'PENDING') {
        pendingCount++;
        pendingFulfillmentAmt += amt;
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
                          "Gaming Shop Top-Up & Voucher Queue",
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
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              "$pendingCount TO DELIVER",
                              style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Deliver PUBG Mobile UC and Free Fire Diamonds vouchers directly to player UIDs",
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
                onPressed: () => admin.fetchAllData(),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metrics
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("PENDING ORDERS", "$pendingCount Orders", Colors.amber, isDesktop),
              _buildMetricCard("PENDING VOLUME", "₨ ${_currencyFormat.format(pendingFulfillmentAmt)}", AppConstants.dangerRed, isDesktop),
              _buildMetricCard("TOTAL SHOP SALES", "₨ ${_currencyFormat.format(totalGamingSales)}", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("ALL ORDERS", "${orders.length} Placed", AppConstants.accentBlue, isDesktop),
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
                    hintText: "Search Mobile, UID, Voucher, TID...",
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
              _buildFilterChip("ALL", "All Statuses"),
              _buildFilterChip("PENDING", "Pending ($pendingCount)"),
              _buildFilterChip("ACCEPTED", "Delivered / Accepted"),
              _buildFilterChip("REJECTED", "Rejected & Refunded"),
              const SizedBox(width: 8),
              // Game Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppConstants.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gameFilter,
                    dropdownColor: AppConstants.surfaceCard,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: "ALL", child: Text("All Games")),
                      DropdownMenuItem(value: "PUBG", child: Text("🎯 PUBG Mobile")),
                      DropdownMenuItem(value: "FREEFIRE", child: Text("🔥 Free Fire")),
                    ],
                    onChanged: (val) => setState(() => _gameFilter = val ?? "ALL"),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Content
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_esports_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No gaming voucher orders found",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildDesktopTable(List<dynamic> list, AdminProvider admin) {
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
                DataColumn(label: Text("ORDER DATE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("GAME", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("PLAYER UID / IGN", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("VOUCHER ITEM", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("AMOUNT (PKR)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("TID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("FULFILLMENT ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((o) {
                final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
                final isPending = status == 'PENDING';
                final isAccepted = status == 'ACCEPTED' || status == 'FULFILLED';
                final amount = double.tryParse(o['amount']?.toString() ?? '0') ?? 0.0;
                final dateStr = _formatTimestamp(o['created_at']);
                final orderId = (o['id'] ?? o['order_tid']).toString();
                final userMob = (o['user_mobile'] ?? '').toString();
                final gameKey = (o['game_key'] ?? 'PUBG').toString().toUpperCase();
                final playerId = (o['player_id'] ?? '-').toString();

                return DataRow(
                  cells: [
                    DataCell(Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(o['user_name'] ?? 'Player', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(userMob, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (gameKey.contains("PUBG") ? Colors.amber : Colors.deepOrange).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: (gameKey.contains("PUBG") ? Colors.amber : Colors.deepOrange).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          gameKey,
                          style: TextStyle(
                            color: gameKey.contains("PUBG") ? Colors.amber : Colors.deepOrange,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Text(
                            playerId,
                            style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 14, color: AppConstants.textMuted),
                            tooltip: "Copy Player UID",
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Copied UID: $playerId"), duration: const Duration(seconds: 1)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(o['voucher_title'] ?? 'Gaming Voucher', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5))),
                    DataCell(
                      Text(
                        "₨ ${_currencyFormat.format(amount)}",
                        style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                    DataCell(Text(o['order_tid'] ?? '-', style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'))),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      isPending
                          ? Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.accentGreen,
                              foregroundColor: const Color(0xFF021A13),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmVoucherDecision(context, orderId, 'ACCEPTED', amount, userMob, playerId, admin),
                            child: const Text("✓ Deliver", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.dangerRed,
                              side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmVoucherDecision(context, orderId, 'REJECTED', amount, userMob, playerId, admin),
                            child: const Text("✕ Reject & Refund", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                          ),
                        ],
                      )
                          : Text(
                        isAccepted ? "✓ Delivered" : "✕ Refunded",
                        style: TextStyle(
                          color: isAccepted ? AppConstants.accentGreen : AppConstants.dangerRed,
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
        final o = list[idx];
        final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
        final isPending = status == 'PENDING';
        final amount = double.tryParse(o['amount']?.toString() ?? '0') ?? 0.0;
        final dateStr = _formatTimestamp(o['created_at']);
        final orderId = (o['id'] ?? o['order_tid']).toString();
        final userMob = (o['user_mobile'] ?? '').toString();
        final gameKey = (o['game_key'] ?? 'PUBG').toString().toUpperCase();
        final playerId = (o['player_id'] ?? '-').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isPending ? Colors.amber.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (gameKey.contains("PUBG") ? Colors.amber : Colors.deepOrange).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gameKey,
                      style: TextStyle(
                        color: gameKey.contains("PUBG") ? Colors.amber : Colors.deepOrange,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
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
                      Text(o['voucher_title'] ?? 'Gaming Voucher', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text("Player UID: ", style: TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                          Text(playerId, style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    "₨ ${_currencyFormat.format(amount)}",
                    style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Customer: ${o['user_name']} ($userMob)", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  Text(dateStr, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              Text("TID: ${o['order_tid'] ?? '-'}", style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontFamily: 'monospace')),
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentGreen,
                          foregroundColor: const Color(0xFF021A13),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmVoucherDecision(context, orderId, 'ACCEPTED', amount, userMob, playerId, admin),
                        child: const Text("Deliver Voucher", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
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
                        onPressed: () => _confirmVoucherDecision(context, orderId, 'REJECTED', amount, userMob, playerId, admin),
                        child: const Text("Reject & Refund", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
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
      label = "PENDING DELIVERY";
    } else if (status == 'ACCEPTED' || status == 'FULFILLED') {
      bg = AppConstants.accentGreen.withValues(alpha: 0.15);
      text = AppConstants.accentGreen;
      label = "DELIVERED";
    } else {
      bg = AppConstants.dangerRed.withValues(alpha: 0.15);
      text = AppConstants.dangerRed;
      label = "REJECTED & REFUNDED";
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

  // Confirm Decision Dialog (Accept or Reject & Refund)
  void _confirmVoucherDecision(
      BuildContext context,
      String orderId,
      String decision,
      double amount,
      String userMobile,
      String playerId,
      AdminProvider admin,
      ) {
    final isReject = decision == 'REJECTED';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
        title: Row(
          children: [
            Icon(isReject ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: isReject ? AppConstants.dangerRed : AppConstants.accentGreen),
            const SizedBox(width: 8),
            Text(isReject ? "Reject & Auto-Refund" : "Deliver Voucher", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          isReject
              ? "Kya aap waqai Order #$orderId ko REJECT karna chahte hain?\n\n₨ ${_currencyFormat.format(amount)} customer ($userMobile) ke wallet balance me foran refund ho jayenge."
              : "Kya aapne Player UID: $playerId par voucher deliver kar diya hai?\n\nOrder ko DELIVERED mark kar diya jaye?",
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isReject ? AppConstants.dangerRed : AppConstants.accentGreen,
              foregroundColor: isReject ? Colors.white : const Color(0xFF021A13),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'review_voucher_order'},
                  data: {
                    'orderId': orderId,
                    'status': decision,
                    'userMobile': userMobile,
                    'amount': amount,
                    'adminName': 'Administrator',
                  },
                );

                if (res.data['status'] == 'success') {
                  await admin.fetchAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: isReject ? AppConstants.dangerRed : AppConstants.accentGreen,
                        content: Text(
                          isReject ? "✓ Order rejected & ₨ ${_currencyFormat.format(amount)} refunded to $userMobile!" : "✓ Voucher order marked as delivered!",
                          style: TextStyle(color: isReject ? Colors.white : const Color(0xFF021A13), fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Order update failed.")),
                    );
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while updating voucher order.")),
                  );
                }
              }
            },
            child: Text(isReject ? "Yes, Reject & Refund" : "Yes, Mark Delivered", style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}