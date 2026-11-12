import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class DigitalKametiDeskScreen extends StatefulWidget {
  const DigitalKametiDeskScreen({super.key});

  @override
  State<DigitalKametiDeskScreen> createState() => _DigitalKametiDeskScreenState();
}

class _DigitalKametiDeskScreenState extends State<DigitalKametiDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  bool _isLoading = true;
  List<dynamic> _poolsList = [];
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, OPEN, RUNNING, COMPLETED
  bool _isActionBusy = false;

  @override
  void initState() {
    super.initState();
    _fetchKametiPools();
  }

  Future<void> _fetchKametiPools() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '',
        queryParameters: {'action': 'get_kametis', '_t': DateTime.now().millisecondsSinceEpoch},
      );
      if (res.data['status'] == 'success') {
        setState(() {
          _poolsList = res.data['pools'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Kameti API Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _poolsList.where((p) {
      final status = (p['status'] ?? 'OPEN').toString().toUpperCase();
      if (_statusFilter == "OPEN" && status != "OPEN") return false;
      if (_statusFilter == "RUNNING" && status != "RUNNING") return false;
      if (_statusFilter == "COMPLETED" && status != "COMPLETED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (p['title'] ?? '').toString().toLowerCase();
        final id = (p['id'] ?? '').toString();
        final winnerName = (p['current_winner'] != null ? (p['current_winner']['user_name'] ?? '') : '').toString().toLowerCase();
        return title.contains(q) || id.contains(q) || winnerName.contains(q);
      }
      return true;
    }).toList();

    // Operational Counters
    int runningPools = 0;
    int openPools = 0;
    double totalActivePotCapital = 0.0;
    int totalEnrolledMembers = 0;

    for (var p in _poolsList) {
      final status = (p['status'] ?? 'OPEN').toString().toUpperCase();
      final qist = double.tryParse(p['monthly_amount']?.toString() ?? '0') ?? 0.0;
      final membersCount = int.tryParse(p['total_members']?.toString() ?? '10') ?? 10;
      final joinedCount = int.tryParse(p['joined_count']?.toString() ?? '0') ?? 0;

      totalEnrolledMembers += joinedCount;

      if (status == 'RUNNING') {
        runningPools++;
        totalActivePotCapital += (qist * membersCount);
      } else if (status == 'OPEN') {
        openPools++;
      }
    }

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Launch & Sync Action
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
                          "Digital Kameti (Bachat Committee) Command",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (runningPools > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              "$runningPools ACTIVE COMMITTEES",
                              style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Automated 10-seat savings pools, 10th monthly cutoff tracker, risk-weighted lucky draws & safe pot release",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGreen,
                      foregroundColor: const Color(0xFF021A13),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openCreatePoolDialog(context),
                    icon: const Icon(Icons.add_circle_rounded, size: 18),
                    label: const Text("Launch New Pool", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _fetchKametiPools();
                      admin.fetchAllData();
                    },
                    icon: const Icon(Icons.sync_rounded, size: 18, color: AppConstants.accentGreen),
                    label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metric Cards
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("ACTIVE RUNNING POOLS", "$runningPools Pools", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("ACTIVE CAPITAL VOLUME", "₨ ${_currencyFormat.format(totalActivePotCapital)}", AppConstants.accentGold, isDesktop),
              _buildMetricCard("ENROLLED PARTICIPANTS", "$totalEnrolledMembers Members", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("SLOTS ACCEPTING MEMBERS", "$openPools Open Pools", const Color(0xFFA855F7), isDesktop),
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
                    hintText: "Search Pool Title, ID, Winner Name...",
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
              _buildFilterChip("ALL", "All Pools (${_poolsList.length})"),
              _buildFilterChip("RUNNING", "Running / Active ($runningPools)"),
              _buildFilterChip("OPEN", "Open for Joining ($openPools)"),
              _buildFilterChip("COMPLETED", "Matured & Completed"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Desk
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
                : filteredList.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No digital kameti pools found",
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
              columnSpacing: 22,
              columns: const [
                DataColumn(label: Text("POOL DETAILS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("MONTHLY QIST", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("POT VALUE & FEE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("MEMBERS & 10TH CUTOFF", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CYCLE & RIGHTFUL WINNER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("EXECUTIVE ACTIONS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((p) {
                final poolId = int.tryParse(p['id']?.toString() ?? '0') ?? 0;
                final status = (p['status'] ?? 'OPEN').toString().toUpperCase();
                final isRunning = status == 'RUNNING';

                final qist = double.tryParse(p['monthly_amount']?.toString() ?? '0') ?? 0.0;
                final totalMembers = int.tryParse(p['total_members']?.toString() ?? '10') ?? 10;
                final totalMonths = int.tryParse(p['total_months']?.toString() ?? '10') ?? 10;
                final currentMonth = int.tryParse(p['current_month']?.toString() ?? '1') ?? 1;

                final joinedCount = int.tryParse(p['joined_count']?.toString() ?? '0') ?? 0;
                final paidCount = int.tryParse(p['current_month_paid_count']?.toString() ?? '0') ?? 0;

                final grossPot = qist * totalMembers;
                final fee = grossPot * 0.015; // 1.5% NexPay platform fee
                final netPayout = grossPot - fee;

                final isFull = joinedCount >= totalMembers;
                final isCollectionComplete = paidCount >= totalMembers;
                final isPast10th = (p['is_past_10th'] == 1 || p['is_past_10th'] == true);

                final winner = p['current_winner'];
                final winnerName = winner != null ? (winner['user_name'] ?? 'Pending') : 'Pending';
                final winnerMob = winner != null ? (winner['user_mobile'] ?? '') : '';

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p['title'] ?? 'Digital Kameti', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                          Text("ID: #$poolId • Duration: $totalMonths Months", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        "₨ ${_currencyFormat.format(qist)}",
                        style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("₨ ${_currencyFormat.format(grossPot)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w900, fontSize: 13)),
                          Text("Net: ₨ ${_currencyFormat.format(netPayout)} (1.5% Fee)", style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text("$joinedCount / $totalMembers Members", style: TextStyle(color: isFull ? AppConstants.accentGreen : AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 4),
                              Text("($paidCount Paid)", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          if (isPast10th && !isCollectionComplete && isRunning) ...[
                            const SizedBox(height: 2),
                            const Text("⚠️ 10th Cutoff Deficit", style: TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Month #$currentMonth of $totalMonths", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          if (isRunning && winnerMob.isNotEmpty) ...[
                            Text("👑 $winnerName ($winnerMob)", style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11, fontFamily: 'monospace')),
                          ],
                        ],
                      ),
                    ),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.surfaceCard,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openMembersAuditDialog(context, p),
                            icon: const Icon(Icons.people_alt_rounded, size: 14, color: AppConstants.accentBlue),
                            label: Text("Members ($joinedCount)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentGold),
                            tooltip: "Edit Pool Settings",
                            onPressed: () => _openEditPoolDialog(context, p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
                            tooltip: "Delete & Auto-Refund Pool",
                            onPressed: () => _confirmDeletePool(context, poolId, p['title'] ?? 'Kameti'),
                          ),
                          if (isRunning) ...[
                            const SizedBox(width: 4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCollectionComplete ? AppConstants.accentGreen : Colors.amber.withValues(alpha: 0.2),
                                foregroundColor: isCollectionComplete ? const Color(0xFF021A13) : Colors.amber,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isActionBusy
                                  ? null
                                  : () => _confirmReleasePot(context, poolId, p['title'] ?? 'Kameti', winnerMob, winnerName, netPayout, isCollectionComplete, totalMembers - paidCount),
                              child: Text(
                                isCollectionComplete ? "Release Pot" : "Deficit (${totalMembers - paidCount} Due)",
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ),
                          ],
                        ],
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
        final p = list[idx];
        final poolId = int.tryParse(p['id']?.toString() ?? '0') ?? 0;
        final status = (p['status'] ?? 'OPEN').toString().toUpperCase();
        final isRunning = status == 'RUNNING';

        final qist = double.tryParse(p['monthly_amount']?.toString() ?? '0') ?? 0.0;
        final totalMembers = int.tryParse(p['total_members']?.toString() ?? '10') ?? 10;
        final totalMonths = int.tryParse(p['total_months']?.toString() ?? '10') ?? 10;
        final currentMonth = int.tryParse(p['current_month']?.toString() ?? '1') ?? 1;

        final joinedCount = int.tryParse(p['joined_count']?.toString() ?? '0') ?? 0;
        final paidCount = int.tryParse(p['current_month_paid_count']?.toString() ?? '0') ?? 0;

        final grossPot = qist * totalMembers;
        final fee = grossPot * 0.015;
        final netPayout = grossPot - fee;
        final isCollectionComplete = paidCount >= totalMembers;

        final winner = p['current_winner'];
        final winnerName = winner != null ? (winner['user_name'] ?? 'Pending') : 'Pending';
        final winnerMob = winner != null ? (winner['user_mobile'] ?? '') : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isRunning ? AppConstants.accentGreen.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p['title'] ?? 'Digital Kameti', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 4),
              Text("ID: #$poolId • Month #$currentMonth of $totalMonths", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5, fontFamily: 'monospace')),
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Monthly Qist", style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                      Text("₨ ${_currencyFormat.format(qist)}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Net Pot Release", style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                      Text("₨ ${_currencyFormat.format(netPayout)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Capacity: $joinedCount / $totalMembers Members ($paidCount Paid)", style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  if (isRunning && winnerMob.isNotEmpty)
                    Text("👑 $winnerName", style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.accentBlue,
                        side: BorderSide(color: AppConstants.accentBlue.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _openMembersAuditDialog(context, p),
                      icon: const Icon(Icons.people_alt_rounded, size: 16),
                      label: Text("Audit Members ($joinedCount)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ),
                  ),
                  if (isRunning) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCollectionComplete ? AppConstants.accentGreen : Colors.amber.withValues(alpha: 0.2),
                          foregroundColor: isCollectionComplete ? const Color(0xFF021A13) : Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isActionBusy
                            ? null
                            : () => _confirmReleasePot(context, poolId, p['title'] ?? 'Kameti', winnerMob, winnerName, netPayout, isCollectionComplete, totalMembers - paidCount),
                        child: Text(
                          isCollectionComplete ? "Release Pot" : "Deficit Alert",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;

    if (status == 'RUNNING') {
      bg = AppConstants.accentGreen.withValues(alpha: 0.15);
      text = AppConstants.accentGreen;
    } else if (status == 'OPEN') {
      bg = Colors.amber.withValues(alpha: 0.15);
      text = Colors.amber;
    } else {
      bg = const Color(0xFFA855F7).withValues(alpha: 0.15);
      text = const Color(0xFFA855F7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: text, fontSize: 10.5, fontWeight: FontWeight.w900)),
    );
  }

  // Dialog 1: Create Pool Modal
  void _openCreatePoolDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final membersController = TextEditingController(text: "10");
    final monthsController = TextEditingController(text: "10");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_rounded, color: AppConstants.accentGreen),
            SizedBox(width: 8),
            Text("Launch Digital Kameti", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "KAMETI TITLE / NAME",
                  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                  hintText: "e.g. Monthly 5k Bachat Committee",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: AppConstants.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  labelText: "MONTHLY QIST AMOUNT (PKR)",
                  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                  hintText: "5000",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: AppConstants.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: membersController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "TOTAL MEMBERS",
                        labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                        filled: true,
                        fillColor: AppConstants.surfaceCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: monthsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "MONTHS (DURATION)",
                        labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                        filled: true,
                        fillColor: AppConstants.surfaceCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: const Color(0xFF021A13)),
            onPressed: () async {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0.0;
              final members = int.tryParse(membersController.text) ?? 10;
              final months = int.tryParse(monthsController.text) ?? 10;

              if (title.isEmpty || amount <= 0) return;
              Navigator.pop(ctx);
              setState(() => _isActionBusy = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'create_kameti_pool'},
                  data: {
                    'title': title,
                    'monthly_amount': amount,
                    'total_members': members,
                    'total_months': months,
                  },
                );

                if (res.data['status'] == 'success') {
                  await _fetchKametiPools();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.accentGreen, content: Text("✓ $title launched live!", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
                    );
                  }
                }
              } catch (_) {} finally {
                if (mounted) setState(() => _isActionBusy = false);
              }
            },
            child: const Text("Launch Pool Live", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // Dialog 2: Edit Pool Modal
  void _openEditPoolDialog(BuildContext context, dynamic pool) {
    final titleController = TextEditingController(text: pool['title']);
    final amountController = TextEditingController(text: pool['monthly_amount'].toString());
    final membersController = TextEditingController(text: pool['total_members'].toString());
    final monthsController = TextEditingController(text: pool['total_months'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
        title: Text("Edit ${pool['title']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "POOL TITLE",
                  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: AppConstants.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  labelText: "MONTHLY QIST (PKR)",
                  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: AppConstants.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: const Color(0xFF021A13)),
            onPressed: () async {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0.0;
              final members = int.tryParse(membersController.text) ?? 10;
              final months = int.tryParse(monthsController.text) ?? 10;

              Navigator.pop(ctx);
              setState(() => _isActionBusy = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'edit_kameti_pool'},
                  data: {
                    'poolId': pool['id'],
                    'title': title,
                    'monthly_amount': amount,
                    'total_members': members,
                    'total_months': months,
                  },
                );

                if (res.data['status'] == 'success') {
                  await _fetchKametiPools();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: AppConstants.accentGreen, content: Text("✓ Pool settings updated!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
                    );
                  }
                }
              } catch (_) {} finally {
                if (mounted) setState(() => _isActionBusy = false);
              }
            },
            child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // Dialog 3: Members Payment Audit Modal
  void _openMembersAuditDialog(BuildContext context, dynamic pool) {
    final members = pool['members'] is List ? pool['members'] as List : [];
    final currentMonth = int.tryParse(pool['current_month']?.toString() ?? '1') ?? 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
        title: Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: AppConstants.accentBlue),
            const SizedBox(width: 8),
            Expanded(child: Text("${pool['title']} (Members Audit)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
          child: members.isEmpty
              ? const Center(child: Text("Is kameti pool me abhi tak koi member join nahi hua.", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, idx) {
              final m = members[idx];
              final turnMonth = int.tryParse(m['turn_month']?.toString() ?? '0') ?? 0;
              final isCurrentWinner = turnMonth == currentMonth;
              final isPaid = (m['is_current_paid'] == 1 || m['is_current_paid'] == true);
              final isOverdue = (m['is_overdue'] == 1 || m['is_overdue'] == true);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentWinner ? const Color(0xFFFBBF24).withValues(alpha: 0.1) : AppConstants.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isCurrentWinner ? const Color(0xFFFBBF24) : Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(m['user_name'] ?? 'Member', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                            if (isCurrentWinner) ...[
                              const SizedBox(width: 6),
                              const Text("👑 WINNER", style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w900, fontSize: 10)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text("📱 ${m['user_mobile']}", style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11, fontFamily: 'monospace')),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(turnMonth > 0 ? "Turn: Month #$turnMonth" : "Pending Lucky Draw", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11.5)),
                        const SizedBox(height: 3),
                        isPaid
                            ? const Text("✓ Qist Paid", style: TextStyle(color: AppConstants.accentGreen, fontSize: 10.5, fontWeight: FontWeight.w900))
                            : Text(isOverdue ? "⚠️ Overdue (10th Passed)" : "⏳ Unpaid", style: TextStyle(color: isOverdue ? AppConstants.dangerRed : Colors.amber, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  // Dialog 4: Release Pot to Winner
  void _confirmReleasePot(BuildContext context, int poolId, String title, String winnerMob, String winnerName, double netPayout, bool isReady, int shortfall) {
    if (!isReady) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConstants.surface,
          title: const Text("Deficit Warning", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
          content: Text("Is mahine abhi $shortfall members ki qist baqi hai! Poori collection ke baghair pot release nahi kiya ja sakta.", style: const TextStyle(color: AppConstants.textMuted)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: AppConstants.accentGreen)))],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
        title: const Row(
          children: [
            Icon(Icons.monetization_on_rounded, color: AppConstants.accentGreen),
            SizedBox(width: 8),
            Text("Authorize Pot Payout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          "Kya aap waqai ₨ ${_currencyFormat.format(netPayout)} ka poora pot rightful winner $winnerName ($winnerMob) ke primary wallet balance me transfer karna chahte hain?",
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: const Color(0xFF021A13)),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isActionBusy = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'release_kameti_pot'},
                  data: {'poolId': poolId, 'targetMobile': winnerMob},
                );

                if (res.data['status'] == 'success') {
                  await _fetchKametiPools();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.accentGreen, content: Text("✓ Pot released to $winnerName!", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
                    );
                  }
                }
              } catch (_) {} finally {
                if (mounted) setState(() => _isActionBusy = false);
              }
            },
            child: const Text("Disburse Pot", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // Dialog 5: Delete Pool with Auto-Refund Safeguard
  void _confirmDeletePool(BuildContext context, int poolId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        title: const Text("Delete Pool with Auto-Refund?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
        content: Text("Kya aap waqai Kameti \"$title\" (#$poolId) ko DELETE karna chahte hain?\n\nAgar members ne is mahine qist bhari hui hai to unka paisa foran unke wallet me AUTO-REFUND ho jayega!", style: const TextStyle(color: AppConstants.textMuted, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isActionBusy = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'delete_kameti_pool'},
                  data: {'poolId': poolId},
                );

                if (res.data['status'] == 'success') {
                  await _fetchKametiPools();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.accentGreen, content: Text(res.data['message'] ?? "Pool deleted & refunded.", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
                    );
                  }
                }
              } catch (_) {} finally {
                if (mounted) setState(() => _isActionBusy = false);
              }
            },
            child: const Text("Delete & Refund", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}