import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class DepositGatewaysCmsScreen extends StatefulWidget {
  const DepositGatewaysCmsScreen({super.key});

  @override
  State<DepositGatewaysCmsScreen> createState() => _DepositGatewaysCmsScreenState();
}

class _DepositGatewaysCmsScreenState extends State<DepositGatewaysCmsScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  List _gatewaysList = [];
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, ACTIVE, DISABLED
  bool _isSaving = false;
  bool _isInitialized = false;

  // Default fallback deposit channels matching NexPay standards
  final List _defaultGateways = [
  {
  'id': 'gw_easypaisa',
  'method': 'EasyPaisa',
  'title': 'NexPay Official Treasury',
  'number': '03330640148',
  'minAmount': 100,
  'status': 'ACTIVE',
  'qrUrl': '',
  'note': 'Send funds and upload clear payment receipt screenshot.',
  },
  {
  'id': 'gw_jazzcash',
  'method': 'JazzCash',
  'title': 'NexPay Official Corporate',
  'number': '03001234567',
  'minAmount': 100,
  'status': 'ACTIVE',
  'qrUrl': '',
  'note': 'Verify account title before completing the transfer.',
  },
  {
  'id': 'gw_meezan',
  'method': 'Meezan Bank (Islamic)',
  'title': 'NexPay Financial Platform',
  'number': 'PK76MEZN0001020304050607',
  'minAmount': 500,
  'status': 'ACTIVE',
  'qrUrl': '',
  'note': 'Interbank IBFT settlement. Upload transaction receipt.',
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadGatewaysFromProvider();
      _isInitialized = true;
    }
  }

  void _loadGatewaysFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['depositAccounts'] is List && (cfg['depositAccounts'] as List).isNotEmpty) {
      final list = (cfg['depositAccounts'] as List)
          .whereType()
          .map((g) => Map<String, dynamic>.from(g))
          .toList();
      setState(() => _gatewaysList = list);
    } else {
      setState(() => _gatewaysList = List.from(_defaultGateways));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _gatewaysList.where((gw) {
      final status = (gw['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_statusFilter == "ACTIVE" && status != "ACTIVE") return false;
      if (_statusFilter == "DISABLED" && status != "DISABLED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final method = (gw['method'] ?? '').toString().toLowerCase();
        final title = (gw['title'] ?? '').toString().toLowerCase();
        final number = (gw['number'] ?? '').toString().toLowerCase();
        final note = (gw['note'] ?? '').toString().toLowerCase();
        return method.contains(q) || title.contains(q) || number.contains(q) || note.contains(q);
      }
      return true;
    }).toList();

    int activeCount = _gatewaysList.where((g) => (g['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE').length;
    int disabledCount = _gatewaysList.length - activeCount;
    int qrAttachedCount = _gatewaysList.where((g) => (g['qrUrl'] ?? '').toString().trim().isNotEmpty).length;

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
                        const Text(
                          "Deposit Gateways & Receiving Accounts CMS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "$activeCount ACTIVE CHANNELS",
                            style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage customer Add-Money bank accounts, wallets, QR codes, and receiving thresholds",
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
                    onPressed: () => _openAddEditGatewayDialog(context, null, admin),
                    icon: const Icon(Icons.add_card_rounded, size: 18),
                    label: const Text("Add Deposit Channel", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadGatewaysFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded deposit channels from memory.")),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 18, color: AppConstants.accentGreen),
                    label: const Text("Sync Memory", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metric Badges
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("ACTIVE CHANNELS", "$activeCount Gateways", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("DISABLED CHANNELS", "$disabledCount Inactive", disabledCount > 0 ? AppConstants.dangerRed : AppConstants.textMuted, isDesktop),
              _buildMetricCard("QR CODE ATTACHED", "$qrAttachedCount QR Codes", const Color(0xFFA855F7), isDesktop),
              _buildMetricCard("TOTAL METHODS", "${_gatewaysList.length} Receiving Accounts", AppConstants.accentBlue, isDesktop),
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
                    hintText: "Search Bank, Method, Account, IBAN...",
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
              _buildFilterChip("ALL", "All Gateways (${_gatewaysList.length})"),
              _buildFilterChip("ACTIVE", "Active Channels ($activeCount)"),
              _buildFilterChip("DISABLED", "Disabled ($disabledCount)"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Desk
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No deposit gateways found",
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
          Text(value, style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w900)),
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

  Widget _buildDesktopTable(List list, AdminProvider admin) {
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
  columnSpacing: 26,
  columns: const [
  DataColumn(label: Text("QR CODE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("METHOD / BANK", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ACCOUNT TITLE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("ACCOUNT NUMBER / IBAN", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("MIN LIMIT & NOTE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((gw) {
  final status = (gw['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final qrUrl = (gw['qrUrl'] ?? '').toString();
  final minAmt = double.tryParse(gw['minAmount']?.toString() ?? '100') ?? 100.0;
  final accNumber = (gw['number'] ?? '-').toString();

  return DataRow(
  cells: [
  DataCell(
  Container(
  width: 38,
  height: 38,
  decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: Colors.white12),
  ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: qrUrl.isNotEmpty
  ? Image.network(
  qrUrl,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => const Center(
  child: Icon(Icons.qr_code_2_rounded, color: Colors.black54, size: 22),
  ),
  )
      : const Center(
  child: Icon(Icons.credit_card_rounded, color: Colors.black54, size: 20),
  ),
  ),
  ),
  ),
  DataCell(
  Text(
  gw['method'] ?? 'Payment Method',
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
  ),
  ),
  DataCell(
  Text(
  gw['title'] ?? '-',
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
  ),
  ),
  DataCell(
  Row(
  children: [
  Text(
  accNumber,
  style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13),
  ),
  const SizedBox(width: 6),
  IconButton(
  icon: const Icon(Icons.copy_rounded, size: 14, color: AppConstants.textMuted),
  tooltip: "Copy Account Number",
  onPressed: () {
  Clipboard.setData(ClipboardData(text: accNumber));
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text("✓ Copied: $accNumber"), duration: const Duration(seconds: 1)),
  );
  },
  ),
  ],
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text("Min: ₨ ${_currencyFormat.format(minAmt)}", style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 11.5)),
  Container(
  constraints: const BoxConstraints(maxWidth: 220),
  child: Text(
  gw['note'] ?? '-',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  ),
  ),
  ],
  ),
  ),
  DataCell(_buildStatusBadge(isActive)),
  DataCell(
  Row(
  children: [
  IconButton(
  icon: Icon(
  isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
  color: isActive ? AppConstants.accentGreen : AppConstants.textMuted,
  size: 26,
  ),
  tooltip: isActive ? "Disable Channel" : "Enable Channel",
  onPressed: () => _toggleGatewayStatus(gw, admin),
  ),
  IconButton(
  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentBlue),
  tooltip: "Edit Channel",
  onPressed: () => _openAddEditGatewayDialog(context, gw, admin),
  ),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Delete Channel",
  onPressed: () => _confirmDeleteGateway(context, gw, admin),
  ),
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

  Widget _buildMobileCards(List list, AdminProvider admin) {
  return ListView.builder(
  itemCount: list.length,
  itemBuilder: (context, idx) {
  final gw = list[idx];
  final status = (gw['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final qrUrl = (gw['qrUrl'] ?? '').toString();
  final minAmt = double.tryParse(gw['minAmount']?.toString() ?? '100') ?? 100.0;
  final accNumber = (gw['number'] ?? '-').toString();

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: isActive ? AppConstants.accentGreen.withValues(alpha: 0.3) : Colors.white10),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Row(
  children: [
  Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(6),
  ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(6),
  child: qrUrl.isNotEmpty
  ? Image.network(qrUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, color: Colors.black, size: 18))
      : const Icon(Icons.account_balance_wallet, color: Colors.black, size: 18),
  ),
  ),
  const SizedBox(width: 8),
  Text(gw['method'] ?? 'Channel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
  ],
  ),
  _buildStatusBadge(isActive),
  ],
  ),
  const SizedBox(height: 12),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(gw['title'] ?? '-', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
  const SizedBox(height: 3),
  Text(accNumber, style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14)),
  ],
  ),
  Text("Min: ₨ ${_currencyFormat.format(minAmt)}", style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
  ],
  ),
  if (gw['note'] != null && gw['note'].toString().isNotEmpty) ...[
  const SizedBox(height: 8),
  Text("Note: ${gw['note']}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  ],
  const Divider(color: Colors.white10, height: 20),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: isActive ? AppConstants.dangerRed.withValues(alpha: 0.15) : AppConstants.accentGreen.withValues(alpha: 0.15),
  foregroundColor: isActive ? AppConstants.dangerRed : AppConstants.accentGreen,
  elevation: 0,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  onPressed: () => _toggleGatewayStatus(gw, admin),
  icon: Icon(isActive ? Icons.power_settings_new_rounded : Icons.check_circle_rounded, size: 14),
  label: Text(isActive ? "Disable" : "Enable", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
  ),
  Row(
  children: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openAddEditGatewayDialog(context, gw, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.dangerRed),
  onPressed: () => _confirmDeleteGateway(context, gw, admin),
  icon: const Icon(Icons.delete_outline_rounded, size: 16),
  label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  ],
  ),
  ],
  ),
  ],
  ),
  );
  },
  );
  }

  Widget _buildStatusBadge(bool isActive) {
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: (isActive ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
  isActive ? "ACTIVE" : "DISABLED",
  style: TextStyle(
  color: isActive ? AppConstants.accentGreen : AppConstants.dangerRed,
  fontSize: 10,
  fontWeight: FontWeight.w900,
  ),
  ),
  );
  }

  // Add / Edit Modal Dialog
  void _openAddEditGatewayDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final isEdit = existing != null;
  final methodController = TextEditingController(text: isEdit ? existing['method'] : '');
  final titleController = TextEditingController(text: isEdit ? existing['title'] : '');
  final numberController = TextEditingController(text: isEdit ? existing['number'] : '');
  final minAmountController = TextEditingController(text: isEdit ? existing['minAmount'].toString() : '100');
  final qrController = TextEditingController(text: isEdit ? existing['qrUrl'] : '');
  final noteController = TextEditingController(text: isEdit ? existing['note'] : 'Upload clear payment receipt screenshot');
  String status = isEdit ? (existing['status'] ?? 'ACTIVE') : 'ACTIVE';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setDialogState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
  title: Text(
  isEdit ? "Edit Channel: ${existing['method']}" : "Add Deposit Channel",
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 520),
  child: SingleChildScrollView(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  Expanded(
  child: TextField(
  controller: methodController,
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "BANK / WALLET NAME",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. EasyPaisa, Meezan Bank",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  Expanded(
  child: TextField(
  controller: titleController,
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
  labelText: "ACCOUNT TITLE",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. NexPay Official",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  TextField(
  controller: numberController,
  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "ACCOUNT NUMBER / IBAN",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "03XXXXXXXXX or PK76MEZN...",
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
  controller: minAmountController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
  labelText: "MIN DEPOSIT (PKR)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "100",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: status,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "ACTIVE", child: Text("🟢 Active (Visible)")),
  DropdownMenuItem(value: "DISABLED", child: Text("🔴 Disabled (Hidden)")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => status = val);
  },
  ),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  TextField(
  controller: qrController,
  style: const TextStyle(color: Colors.white, fontSize: 12),
  decoration: InputDecoration(
  labelText: "QR CODE IMAGE (DIRECT URL - OPTIONAL)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "https://example.com/qr.png",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 12),
  TextField(
  controller: noteController,
  maxLines: 2,
  style: const TextStyle(color: Colors.white, fontSize: 12),
  decoration: InputDecoration(
  labelText: "INSTRUCTIONS / NOTE FOR CUSTOMER",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "Upload clear payment receipt screenshot",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ],
  ),
  ),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: const Color(0xFF021A13)),
  onPressed: () async {
  final method = methodController.text.trim();
  final title = titleController.text.trim();
  final number = numberController.text.trim();
  if (method.isEmpty || number.isEmpty) return;

  Navigator.pop(ctx);

  final gwObj = {
  'id': isEdit ? existing['id'] : 'gw_${DateTime.now().millisecondsSinceEpoch}',
  'method': method,
  'title': title,
  'number': number,
  'minAmount': double.tryParse(minAmountController.text) ?? 100.0,
  'status': status,
  'qrUrl': qrController.text.trim(),
  'note': noteController.text.trim(),
  };

  final updatedList = List.from(_gatewaysList);
  if (isEdit) {
  final idx = updatedList.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updatedList[idx] = gwObj;
  } else {
  updatedList.add(gwObj);
  }

  await _saveGatewaysList(updatedList, admin);
  },
  child: const Text("Save Channel Live", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  ),
  );
  }

  // Toggle Gateway Status[cite: 2]
  Future<void> _toggleGatewayStatus(Map<String, dynamic> gw, AdminProvider admin) async {
  final currentStatus = (gw['status'] ?? 'ACTIVE').toString().toUpperCase();
  final newStatus = currentStatus == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';

  final updatedList = List.from(_gatewaysList);
  final idx = updatedList.indexWhere((x) => x['id'] == gw['id']);
  if (idx != -1) {
  updatedList[idx]['status'] = newStatus;
  await _saveGatewaysList(updatedList, admin);
  }
  }

  // Confirm Delete Gateway[cite: 2]
  void _confirmDeleteGateway(BuildContext context, Map<String, dynamic> gw, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Delete Channel?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
  content: Text("Kya aap waqai ${gw['method']} (${gw['number']}) ko receiving channels se delete karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = List.from(_bannersListFromState);
  updatedList.removeWhere((x) => x['id'] == gw['id']);
  await _saveGatewaysList(updatedList, admin);
  },
  child: const Text("Delete"),
  ),
  ],
  ),
  );
  }

  List get _bannersListFromState => _gatewaysList;

  Future<void> _saveGatewaysList(List updatedList, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'depositAccounts': updatedList},
  );

  if (res.data['status'] == 'success') {
  setState(() => _gatewaysList = updatedList);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Deposit gateways updated live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update deposit gateways.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}