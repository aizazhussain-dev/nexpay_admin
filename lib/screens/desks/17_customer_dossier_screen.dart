import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class CustomerDossierDeskScreen extends StatefulWidget {
  const CustomerDossierDeskScreen({super.key});

  @override
  State<CustomerDossierDeskScreen> createState() => _CustomerDossierDeskScreenState();
}

class _CustomerDossierDeskScreenState extends State<CustomerDossierDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  bool _isLoading = true;
  List<dynamic> _dossiersList = [];
  String _searchQuery = "";
  String _tierFilter = "ALL"; // ALL, VERIFIED, BASIC, FROZEN
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _fetchDossiers();
  }

  Future<void> _fetchDossiers() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '',
        queryParameters: {
          'action': 'get_customer_dossiers',
          '_t': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (res.data['status'] == 'success') {
        setState(() {
          _dossiersList = res.data['dossiers'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Fetch Dossiers Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _dossiersList.where((u) {
      final isVerified = u['isKycVerified'] == true || u['is_kyc_verified'] == 1;
      final isFrozen = u['isFrozen'] == true || u['is_frozen'] == 1;

      if (_tierFilter == "VERIFIED" && !isVerified) return false;
      if (_tierFilter == "BASIC" && (isVerified || isFrozen)) return false;
      if (_tierFilter == "FROZEN" && !isFrozen) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (u['name'] ?? '').toString().toLowerCase();
        final mob = (u['mobile'] ?? '').toString().toLowerCase();
        final cnic = (u['cnic'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final address = (u['address'] ?? '').toString().toLowerCase();
        return name.contains(q) || mob.contains(q) || cnic.contains(q) || email.contains(q) || address.contains(q);
      }
      return true;
    }).toList();

    // Operational Counters
    int verifiedCount = 0;
    int recordedAddressesCount = 0;
    double totalCapitalInDossiers = 0.0;

    for (var u in _dossiersList) {
      final isVerified = u['isKycVerified'] == true || u['is_kyc_verified'] == 1;
      final addr = (u['address'] ?? '').toString().trim();
      final bal = double.tryParse(u['balance']?.toString() ?? '0') ?? 0.0;

      totalCapitalInDossiers += bal;
      if (isVerified) verifiedCount++;
      if (addr.isNotEmpty && addr != 'Not Recorded') recordedAddressesCount++;
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
                    Text(
                      "Master Customer Dossier & Address Registry",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: isDesktop ? 22 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Central customer repository: Facial tokens, national identity scans, and residential house locations",
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
                onPressed: () {
                  _fetchDossiers();
                  admin.fetchAllData();
                },
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("Sync Registry", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metric Cards
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("REGISTERED DOSSIERS", "${_dossiersList.length} Customer Profiles", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("RESIDENTIAL ADDRESSES", "$recordedAddressesCount Locations On-File", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("TIER-2 BIOMETRIC VIP", "$verifiedCount Verified", AppConstants.accentGold, isDesktop),
              _buildMetricCard("TOTAL HELD CAPITAL", "₨ ${_currencyFormat.format(totalCapitalInDossiers)}", Color(0xFF0F172A), isDesktop),
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
                    hintText: "Search Name, Phone, CNIC, Address...",
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
              _buildFilterChip("ALL", "All Customers (${_dossiersList.length})"),
              _buildFilterChip("VERIFIED", "Tier-2 VIP ($verifiedCount)"),
              _buildFilterChip("BASIC", "Tier-1 Basic"),
              _buildFilterChip("FROZEN", "Locked / Frozen"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
                : filteredList.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.contact_page_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No customer dossiers found matching query",
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
    final isSelected = _tierFilter == key;
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
      onSelected: (_) => setState(() => _tierFilter = key),
    );
  }

  Widget _buildDesktopTable(List<dynamic> list, AdminProvider admin) {
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
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text("SELFIE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CUSTOMER IDENTITY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CNIC & SCANS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("HOUSE / RESIDENTIAL LOCATION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("RISK TIER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("WALLET BALANCES", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("EDIT DOSSIER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((u) {
                final mob = (u['mobile'] ?? '').toString();
                final name = (u['name'] ?? 'Customer').toString();
                final email = (u['email'] ?? '').toString();
                final cnic = (u['cnic'] ?? 'Pending').toString();
                final address = (u['address'] ?? 'Not Recorded').toString();

                final bal = double.tryParse(u['balance']?.toString() ?? '0') ?? 0.0;
                final crypto = double.tryParse(u['crypto']?.toString() ?? '0') ?? 0.0;

                final isVerified = u['isKycVerified'] == true || u['is_kyc_verified'] == 1;
                final isFrozen = u['isFrozen'] == true || u['is_frozen'] == 1;

                final face = (u['face'] ?? '').toString();
                final cnicFront = (u['cnicFront'] ?? '').toString();
                final cnicBack = (u['cnicBack'] ?? '').toString();

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: ClipOval(
                          child: face.isNotEmpty
                              ? _renderThumbnail(face)
                              : const Center(child: Icon(Icons.person_rounded, size: 20, color: AppConstants.textMuted)),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13.5)),
                          Text(mob, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                          if (email.isNotEmpty)
                            Text(email, style: const TextStyle(color: AppConstants.accentGreen, fontSize: 10.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cnic, style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12.5)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _buildDocumentBadge("Front", cnicFront.isNotEmpty),
                              const SizedBox(width: 4),
                              _buildDocumentBadge("Back", cnicBack.isNotEmpty),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          address != 'Not Recorded' ? "📍 $address" : "No house location recorded",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: address != 'Not Recorded' ? Color(0xFF64748B) : Colors.amber,
                            fontSize: 11.5,
                            fontStyle: address == 'Not Recorded' ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                    DataCell(_buildRiskTierBadge(isVerified, isFrozen)),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("₨ ${_currencyFormat.format(bal)}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 13.5)),
                          Text("\$ ${crypto.toStringAsFixed(2)} USDT", style: const TextStyle(color: Color(0xFFF3BA2F), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.surfaceCard,
                          foregroundColor: Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _openFullProfileEditorModal(context, mob, u, admin),
                        icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppConstants.accentGold),
                        label: const Text("Edit Dossier", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
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
        final u = list[idx];
        final mob = (u['mobile'] ?? '').toString();
        final name = (u['name'] ?? 'Customer').toString();
        final cnic = (u['cnic'] ?? 'Pending').toString();
        final address = (u['address'] ?? 'Not Recorded').toString();

        final bal = double.tryParse(u['balance']?.toString() ?? '0') ?? 0.0;
        final crypto = double.tryParse(u['crypto']?.toString() ?? '0') ?? 0.0;

        final isVerified = u['isKycVerified'] == true || u['is_kyc_verified'] == 1;
        final isFrozen = u['isFrozen'] == true || u['is_frozen'] == 1;
        final face = (u['face'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Color(0xFFE2E8F0)),
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.4)),
                        ),
                        child: ClipOval(
                          child: face.isNotEmpty
                              ? _renderThumbnail(face)
                              : const Icon(Icons.person_rounded, size: 20, color: AppConstants.textMuted),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
                          Text(mob, style: const TextStyle(color: AppConstants.accentBlue, fontFamily: 'monospace', fontSize: 11.5)),
                        ],
                      ),
                    ],
                  ),
                  _buildRiskTierBadge(isVerified, isFrozen),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("CNIC: $cnic", style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace', fontSize: 12)),
                  Text("₨ ${_currencyFormat.format(bal)}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                address != 'Not Recorded' ? "📍 $address" : "⚠️ No residential address recorded",
                style: TextStyle(color: address != 'Not Recorded' ? Color(0xFF64748B) : Colors.amber, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.surfaceCard,
                    foregroundColor: Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _openFullProfileEditorModal(context, mob, u, admin),
                  icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppConstants.accentGold),
                  label: const Text("Inspect & Edit Full Dossier", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentBadge(String label, bool isAttached) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: (isAttached ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (isAttached ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.3)),
      ),
      child: Text(
        isAttached ? "✓ $label" : "✕ $label",
        style: TextStyle(
          color: isAttached ? AppConstants.accentGreen : AppConstants.dangerRed,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRiskTierBadge(bool isVerified, bool isFrozen) {
    if (isFrozen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppConstants.dangerRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: const Text("FROZEN", style: TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w900)),
      );
    }
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppConstants.accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: const Text("TIER-2 VIP", style: TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w900)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: const Text("TIER-1 BASIC", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _renderThumbnail(String data) {
    if (data.startsWith("http://") || data.startsWith("https://")) {
      return Image.network(
        data,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFF94A3B8)),
      );
    }
    try {
      String clean = data;
      if (data.contains(",")) clean = data.split(",").last;
      final bytes = base64Decode(clean.replaceAll(RegExp(r'\s+'), ''));
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFF94A3B8)),
      );
    } catch (_) {
      return const Icon(Icons.person, color: Color(0xFF94A3B8));
    }
  }

  // =========================================================================
  // FULL PROFILE & IDENTITY DOSSIER EDITOR MODAL
  // =========================================================================
  void _openFullProfileEditorModal(BuildContext context, String mobile, dynamic user, AdminProvider admin) {
    final nameController = TextEditingController(text: user['name'] ?? '');
    final mobileController = TextEditingController(text: mobile);
    final emailController = TextEditingController(text: user['email'] ?? '');
    final cnicController = TextEditingController(text: user['cnic'] ?? '');
    final addressController = TextEditingController(text: user['address'] != 'Not Recorded' ? user['address'] : '');

    final motherController = TextEditingController();
    final birthCityController = TextEditingController();
    final cnicExpiryController = TextEditingController();

    bool isVerified = user['isKycVerified'] == true || user['is_kyc_verified'] == 1;
    String kycStatus = (user['kycStatus'] ?? (isVerified ? 'APPROVED' : 'PENDING')).toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppConstants.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE2E8F0))),
          title: Row(
            children: [
              const Icon(Icons.edit_document, color: AppConstants.accentGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Edit Dossier: ${user['name']}", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 17)),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PRIMARY CREDENTIALS", style: TextStyle(color: AppConstants.accentGreen, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: "FULL LEGAL NAME",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: mobileController,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: "MOBILE (LOGIN ID)",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: "GMAIL / EMAIL",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: cnicController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            labelText: "13-DIGIT CNIC",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5),
                    decoration: InputDecoration(
                      labelText: "RESIDENTIAL HOUSE LOCATION / ADDRESS",
                      labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppConstants.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("REGULATORY IDENTITY ATTRIBUTES", style: TextStyle(color: AppConstants.accentGold, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: motherController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                          decoration: InputDecoration(
                            labelText: "MOTHER'S NAME",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: birthCityController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                          decoration: InputDecoration(
                            labelText: "CITY OF BIRTH",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: cnicExpiryController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                          decoration: InputDecoration(
                            labelText: "CNIC EXPIRY",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: AppConstants.surfaceCard, borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: kycStatus,
                              dropdownColor: AppConstants.surfaceCard,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: "APPROVED", child: Text("🟢 APPROVED (Tier-2)")),
                                DropdownMenuItem(value: "PENDING", child: Text("🟡 PENDING")),
                                DropdownMenuItem(value: "NOT_SUBMITTED", child: Text("🔴 NOT_SUBMITTED")),
                                DropdownMenuItem(value: "REJECTED", child: Text("✕ REJECTED")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    kycStatus = val;
                                    isVerified = (val == "APPROVED");
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Text("Verified Badge: ", style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                          Switch(
                            value: isVerified,
                            activeColor: AppConstants.accentGreen,
                            onChanged: (v) => setModalState(() => isVerified = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: Color(0xFF021A13)),
              onPressed: _isSavingProfile
                  ? null
                  : () async {
                final newMob = mobileController.text.trim();
                final newName = nameController.text.trim();
                if (newMob.isEmpty || newName.isEmpty) return;

                Navigator.pop(ctx);
                setState(() => _isSavingProfile = true);

                try {
                  final payload = {
                    'oldMobile': mobile,
                    'newMobile': newMob,
                    'name': newName,
                    'email': emailController.text.trim(),
                    'cnic': cnicController.text.trim(),
                    'address': addressController.text.trim(),
                    'isKycVerified': isVerified ? 1 : 0,
                    'kycStatus': kycStatus,
                    'kycDetails': {
                      'motherName': motherController.text.trim(),
                      'birthCity': birthCityController.text.trim(),
                      'cnicExpiry': cnicExpiryController.text.trim(),
                    }
                  };

                  final res = await _api.dio.post(
                    '',
                    queryParameters: {'action': 'admin_update_user_full_profile'},
                    data: payload,
                  );

                  if (res.data['status'] == 'success') {
                    await _fetchDossiers();
                    await admin.fetchAllData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppConstants.accentGreen, content: Text("✓ Customer dossier updated successfully!", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Failed to update profile.")),
                      );
                    }
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while saving profile.")),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSavingProfile = false);
                }
              },
              child: const Text("Save & Synchronize Dossier", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
