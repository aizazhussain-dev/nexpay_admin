import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class KycVerificationDeskScreen extends StatefulWidget {
  const KycVerificationDeskScreen({super.key});

  @override
  State<KycVerificationDeskScreen> createState() => _KycVerificationDeskScreenState();
}

class _KycVerificationDeskScreenState extends State<KycVerificationDeskScreen> {
  final ApiClient _api = ApiClient();
  String _searchQuery = "";
  String _statusFilter = "PENDING"; // ALL, PENDING, APPROVED, REJECTED, NOT_SUBMITTED
  bool _isActionBusy = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final usersMap = admin.users;

    // Build user list with KYC metadata
    final List userList = [];
    int pendingCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;

    usersMap.forEach((mob, u) {
    if (u is Map) {
    final isVerified = u['isKycVerified'] == true || u['is_kyc_verified'] == 1 || u['is_kyc_verified'] == '1';
    final kycDocs = u['kycDocuments'] ?? u['kycDocs'];
    final hasSubmitted = (kycDocs is Map && (kycDocs['hasSubmitted'] == true || kycDocs['submittedAt'] != null));
    String status = (u['kycStatus'] ?? u['kyc_status'] ?? '').toString().toUpperCase();

    if (status.isEmpty || status == 'NULL') {
    status = isVerified ? 'APPROVED' : (hasSubmitted ? 'PENDING' : 'NOT_SUBMITTED');
    }

    if (status == 'PENDING') pendingCount++;
    if (status == 'APPROVED' || isVerified) approvedCount++;
    if (status == 'REJECTED') rejectedCount++;

    userList.add(Map<String, dynamic>.from(u)
    ..['mobile'] = mob
    ..['computedKycStatus'] = status
    ..['isVerified'] = isVerified
    ..['hasDocs'] = hasSubmitted || (status == 'PENDING'));
    }
    });

    // Filter Logic
    final filteredList = userList.where((u) {
    final status = u['computedKycStatus'].toString();

    if (_statusFilter == "PENDING" && status != "PENDING") return false;
    if (_statusFilter == "APPROVED" && status != "APPROVED") return false;
    if (_statusFilter == "REJECTED" && status != "REJECTED") return false;
    if (_statusFilter == "NOT_SUBMITTED" && status != "NOT_SUBMITTED") return false;

    if (_searchQuery.isNotEmpty) {
    final q = _searchQuery.toLowerCase();
    final name = (u['name'] ?? '').toString().toLowerCase();
    final mob = (u['mobile'] ?? '').toString().toLowerCase();
    final cnic = (u['cnic'] ?? '').toString().toLowerCase();
    final email = (u['email'] ?? '').toString().toLowerCase();
    return name.contains(q) || mob.contains(q) || cnic.contains(q) || email.contains(q);
    }
    return true;
    }).toList();

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
    "Biometric KYC & National Identity Center",
    style: TextStyle(
    color: Color(0xFF0F172A),
    fontSize: isDesktop ? 22 : 18,
    fontWeight: FontWeight.w900,
    ),
    ),
    if (pendingCount > 0) ...[
    const SizedBox(width: 10),
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
    color: AppConstants.dangerRed.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.3)),
    ),
    child: Text(
    "$pendingCount PENDING VERIFICATION",
    style: const TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w900),
    ),
    ),
    ],
    ],
    ),
    const SizedBox(height: 4),
    const Text(
    "Inspect CNIC Front, Back, live facial tokens and verify Tier-2 spending limits",
    style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
    ),
    ],
    ),
    ),
    ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
    backgroundColor: AppConstants.accentGreen,
    foregroundColor: Color(0xFF021A13),
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

    // Operational Metric Cards
    Wrap(
    spacing: 14,
    runSpacing: 10,
    children: [
    _buildMetricCard("PENDING VERIFICATION", "$pendingCount Dossiers", pendingCount > 0 ? AppConstants.dangerRed : AppConstants.accentGreen, isDesktop),
    _buildMetricCard("TIER-2 VIP APPROVED", "$approvedCount Verified", AppConstants.accentGreen, isDesktop),
    _buildMetricCard("REJECTED SUBMISSIONS", "$rejectedCount Rejected", AppConstants.accentGold, isDesktop),
    _buildMetricCard("TOTAL CUSTOMERS", "${userList.length} Accounts", AppConstants.accentBlue, isDesktop),
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
    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
    decoration: InputDecoration(
    hintText: "Search Mobile, Name, CNIC, Email...",
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
    _buildFilterChip("PENDING", "Pending Review ($pendingCount)"),
    _buildFilterChip("APPROVED", "Tier-2 Approved ($approvedCount)"),
    _buildFilterChip("REJECTED", "Rejected ($rejectedCount)"),
    _buildFilterChip("NOT_SUBMITTED", "Not Submitted"),
    _buildFilterChip("ALL", "All Customers (${userList.length})"),
    ],
    ),
    const SizedBox(height: 18),

    // Content Area
    Expanded(
    child: filteredList.isEmpty
    ? const Center(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.badge_outlined, size: 54, color: AppConstants.textMuted),
    SizedBox(height: 12),
    Text(
    "No customer KYC dossiers found in this filter",
    style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold),
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
        border: Border.all(color: Color(0xFFE2E8F0)),
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
        color: isSelected ? Color(0xFF021A13) : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppConstants.accentGreen : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  Widget _buildDesktopTable(List list, AdminProvider admin) {
  return Container(
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Color(0xFFE2E8F0)),
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
  DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("NATIONAL CNIC", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("RESIDENTIAL LOCATION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("KYC DOSSIER STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("LIMIT ALLOWANCE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("INSPECTION CONSOLE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((u) {
  final mob = (u['mobile'] ?? '').toString();
  final name = (u['name'] ?? 'Customer').toString();
  final cnic = (u['cnic'] ?? 'Pending Update').toString();
  final address = (u['address'] ?? 'Not Recorded').toString();
  final status = u['computedKycStatus'].toString();
  final isVerified = u['isVerified'] == true;

  return DataRow(
  cells: [
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
  Text(mob, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
  ],
  ),
  ),
  DataCell(Text(cnic, style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12.5))),
  DataCell(
  Container(
  constraints: const BoxConstraints(maxWidth: 240),
  child: Text(
  address,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
  ),
  ),
  ),
  DataCell(_buildKycBadge(status)),
  DataCell(
  Text(
  isVerified ? "Tier-2 (₨ 10 Lakh Monthly)" : "Tier-1 (₨ 50k Monthly)",
  style: TextStyle(
  color: isVerified ? AppConstants.accentGreen : Colors.amber,
  fontWeight: FontWeight.w800,
  fontSize: 12,
  ),
  ),
  ),
  DataCell(
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: status == 'PENDING' ? AppConstants.accentGreen : AppConstants.surfaceCard,
  foregroundColor: status == 'PENDING' ? Color(0xFF021A13) : Color(0xFF0F172A),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: () => _openTriDocumentInspectionModal(context, mob, u, admin),
  icon: const Icon(Icons.document_scanner_rounded, size: 15),
  label: Text(
  status == 'PENDING' ? "Review Dossier" : "Inspect Dossier",
  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
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

  Widget _buildMobileCards(List list, AdminProvider admin) {
  return ListView.builder(
  itemCount: list.length,
  itemBuilder: (context, idx) {
  final u = list[idx];
  final mob = (u['mobile'] ?? '').toString();
  final name = (u['name'] ?? 'Customer').toString();
  final cnic = (u['cnic'] ?? 'Pending').toString();
  final status = u['computedKycStatus'].toString();
  final isVerified = u['isVerified'] == true;

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: status == 'PENDING' ? AppConstants.dangerRed.withValues(alpha: 0.3) : Color(0xFFE2E8F0)),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
  Text(mob, style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 11.5)),
  ],
  ),
  _buildKycBadge(status),
  ],
  ),
  const SizedBox(height: 8),
  Row(
  children: [
  const Text("CNIC: ", style: TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  Text(cnic, style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
  ],
  ),
  const SizedBox(height: 4),
  Text("Quota: ${isVerified ? 'Tier-2 (₨ 10 Lakh)' : 'Tier-1 (₨ 50k)'}", style: TextStyle(color: isVerified ? AppConstants.accentGreen : Colors.amber, fontSize: 11.5, fontWeight: FontWeight.bold)),
  const Divider(color: Color(0xFFE2E8F0), height: 20),
  SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: status == 'PENDING' ? AppConstants.accentGreen : AppConstants.surfaceCard,
  foregroundColor: status == 'PENDING' ? Color(0xFF021A13) : Color(0xFF0F172A),
  padding: const EdgeInsets.symmetric(vertical: 9),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: () => _openTriDocumentInspectionModal(context, mob, u, admin),
  icon: const Icon(Icons.document_scanner_rounded, size: 16),
  label: Text(
  status == 'PENDING' ? "Review & Verify Documents" : "Inspect Biometric Dossier",
  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
  ),
  ),
  ),
  ],
  ),
  );
  },
  );
  }

  Widget _buildKycBadge(String status) {
  Color bg;
  Color text;

  if (status == 'APPROVED') {
  bg = AppConstants.accentGreen.withValues(alpha: 0.15);
  text = AppConstants.accentGreen;
  } else if (status == 'PENDING') {
  bg = Colors.amber.withValues(alpha: 0.15);
  text = Colors.amber;
  } else if (status == 'REJECTED') {
  bg = AppConstants.dangerRed.withValues(alpha: 0.15);
  text = AppConstants.dangerRed;
  } else {
  bg = Color(0xFFE2E8F0);
  text = AppConstants.textMuted;
  }

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
  child: Text(status, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w900)),
  );
  }

  // =========================================================================
  // TRI-DOCUMENT INSPECTION CONSOLE MODAL
  // =========================================================================
  void _openTriDocumentInspectionModal(BuildContext context, String mobile, Map<String, dynamic> user, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => _KycInspectionModal(mobile: mobile, user: user, admin: admin, api: _api),
  );
  }
}

// Dedicated Modal with live document fetch from `get_kyc_proof`
class _KycInspectionModal extends StatefulWidget {
  final String mobile;
  final Map<String, dynamic> user;
  final AdminProvider admin;
  final ApiClient api;

  const _KycInspectionModal({
    required this.mobile,
    required this.user,
    required this.admin,
    required this.api,
  });

  @override
  State<_KycInspectionModal> createState() => _KycInspectionModalState();
}

class _KycInspectionModalState extends State<_KycInspectionModal> {
  bool _isLoadingDocs = true;
  Map<String, dynamic> _kycDocs = {};
  bool _isProcessingDecision = false;

  @override
  void initState() {
    super.initState();
    _fetchKycProof();
  }

  Future<void> _fetchKycProof() async {
    try {
      final res = await widget.api.dio.get(
        '',
        queryParameters: {
          'action': 'get_kyc_proof',
          'mobile': widget.mobile,
          '_t': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (res.data['status'] == 'success') {
        setState(() {
          _kycDocs = (res.data['kycDocs'] is Map) ? Map<String, dynamic>.from(res.data['kycDocs']) : {};
          _isLoadingDocs = false;
        });
      } else {
        setState(() => _isLoadingDocs = false);
      }
    } catch (_) {
      setState(() => _isLoadingDocs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] ?? 'Customer';
    final cnic = widget.user['cnic'] ?? 'Pending';
    final address = _kycDocs['address'] ?? widget.user['address'] ?? 'Not Recorded';
    final motherName = _kycDocs['motherName'] ?? 'Not Recorded';
    final birthCity = _kycDocs['birthCity'] ?? 'Not Recorded';
    final cnicExpiry = _kycDocs['cnicExpiry'] ?? 'Not Recorded';

    final cnicFront = _kycDocs['cnicFront'] ?? _kycDocs['lCnicFront'];
    final cnicBack = _kycDocs['cnicBack'] ?? _kycDocs['lCnicBack'];
    final face = _kycDocs['face'] ?? _kycDocs['selfie'] ?? _kycDocs['liveFace'];

    return Dialog(
      backgroundColor: AppConstants.surface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 850),
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Identity Dossier: $name", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text("Mobile: ${widget.mobile} • CNIC: $cnic", style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2E8F0), height: 20),

            // Dossier Body
            Expanded(
              child: _isLoadingDocs
                  ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tri-Document Scans Display
                    const Text("📸 TRI-DOCUMENT REGULATORY SCANS", style: TextStyle(color: AppConstants.accentGreen, fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildDocCard("CNIC FRONT SIDE", cnicFront)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDocCard("CNIC BACK SIDE", cnicBack)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDocCard("LIVE FACIAL TOKEN", face)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Biometric Text Attributes Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("NATIONAL IDENTITY REGULATORY ATTRIBUTES", style: TextStyle(color: Color(0xFF0F172A), fontSize: 11.5, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildInfoTile("MOTHER'S NAME", motherName)),
                              Expanded(child: _buildInfoTile("CITY OF BIRTH", birthCity)),
                              Expanded(child: _buildInfoTile("CNIC EXPIRY DATE", cnicExpiry)),
                            ],
                          ),
                          const Divider(color: Color(0xFFE2E8F0), height: 18),
                          _buildInfoTile("RESIDENTIAL / HOUSE LOCATION", address),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGreen,
                      foregroundColor: Color(0xFF021A13),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isProcessingDecision ? null : () => _executeDecision(true),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text("✓ Approve & Verify Tier-2", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.dangerRed,
                      side: BorderSide(color: AppConstants.dangerRed.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isProcessingDecision ? null : () => _executeDecision(false),
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text("✕ Reject Dossier", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.amber.withValues(alpha: 0.15),
                    foregroundColor: Colors.amber,
                  ),
                  tooltip: "Wipe KYC (Allow customer to re-submit)",
                  onPressed: _isProcessingDecision ? null : _wipeKycData,
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(String title, dynamic imgData) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppConstants.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: AppConstants.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (imgData == null || imgData.toString().isEmpty)
                  ? const Center(child: Text("Not Attached", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)))
                  : _renderImage(imgData.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderImage(String data) {
    if (data.startsWith("http://") || data.startsWith("https://")) {
      return Image.network(
        data,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Color(0xFF94A3B8))),
      );
    }
    try {
      String clean = data;
      if (data.contains(",")) clean = data.split(",").last;
      final bytes = base64Decode(clean.replaceAll(RegExp(r'\s+'), ''));
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Color(0xFF94A3B8))),
      );
    } catch (_) {
      return const Center(child: Text("Corrupted Scan", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)));
    }
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Execute Decision (Approve / Reject)
  Future<void> _executeDecision(bool approved) async {
    setState(() => _isProcessingDecision = true);

    try {
      final userRaw = widget.admin.users[widget.mobile];
      if (userRaw != null) {
        final userCopy = Map<String, dynamic>.from(userRaw);
        userCopy['isKycVerified'] = approved;
        userCopy['kycStatus'] = approved ? 'APPROVED' : 'REJECTED';

        final res = await widget.api.dio.post(
          '',
          queryParameters: {'action': 'save_all'},
          data: {
            'users': {widget.mobile: userCopy}
          },
        );

        if (res.data['status'] == 'success') {
          await widget.admin.fetchAllData();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: approved ? AppConstants.accentGreen : AppConstants.dangerRed,
                content: Text(
                  approved ? "✓ KYC Approved! Customer upgraded to Tier-2 VIP." : "✕ KYC Dossier marked as Rejected.",
                  style: TextStyle(color: approved ? Color(0xFF021A13) : Color(0xFF0F172A), fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to save KYC decision.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingDecision = false);
    }
  }

  // Wipe KYC
  Future<void> _wipeKycData() async {
    setState(() => _isProcessingDecision = true);
    try {
      final res = await widget.api.dio.post(
        '',
        queryParameters: {'action': 'admin_reset_kyc'},
        data: {'mobile': widget.mobile},
      );
      if (res.data['status'] == 'success') {
        await widget.admin.fetchAllData();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppConstants.accentGreen,
              content: Text("✓ KYC data wiped! Customer can now re-submit from mobile app.", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
            ),
          );
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isProcessingDecision = false);
    }
  }
}
