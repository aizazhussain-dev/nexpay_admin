import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class KycVerificationDeskScreen extends StatefulWidget {
  const KycVerificationDeskScreen({super.key});

  @override
  State<KycVerificationDeskScreen> createState() =>
      _KycVerificationDeskScreenState();
}

class _KycVerificationDeskScreenState extends State<KycVerificationDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'PENDING';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final List allCustomers = [];

    int pendingCount = 0;
    int verifiedCount = 0;
    int unverifiedCount = 0;

    admin.users.forEach((mobile, raw) {
    if (raw is! Map) return;
    final u = Map<String, dynamic>.from(raw);
    u['mobile'] = (u['mobile'] ?? mobile).toString();
    allCustomers.add(u);

    final isVerified = u['isKycVerified'] == true ||
    u['isKycVerified'] == 1 ||
    (u['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    final st = (u['kycStatus'] ?? (isVerified ? 'VERIFIED' : 'UNVERIFIED'))
        .toString()
        .toUpperCase();

    if (st == 'PENDING') {
    pendingCount++;
    } else if (isVerified || st == 'VERIFIED') {
    verifiedCount++;
    } else {
    unverifiedCount++;
    }
    });

    final filtered = allCustomers.where((u) {
    final isVerified = u['isKycVerified'] == true ||
    u['isKycVerified'] == 1 ||
    (u['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    final st = (u['kycStatus'] ?? (isVerified ? 'VERIFIED' : 'UNVERIFIED'))
        .toString()
        .toUpperCase();

    if (_statusFilter == 'PENDING' && st != 'PENDING') return false;
    if (_statusFilter == 'VERIFIED' && !(isVerified || st == 'VERIFIED')) {
    return false;
    }
    if (_statusFilter == 'UNVERIFIED' &&
    (isVerified || st == 'VERIFIED' || st == 'PENDING')) {
    return false;
    }

    if (_query.isEmpty) return true;
    final hay = '${u['name']} ${u['mobile']} ${u['cnic']} ${u['email']}'
        .toLowerCase();
    return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
    header: NexPayDeskHeader(
    title: 'Biometric KYC & NADRA Identity Compliance Desk',
    subtitle:
    'Inspect CNIC front/back scans, live selfie liveness proofs, and approve or reset customer verification',
    badgeText: 'AML / KYC COMPLIANCE',
    badgeColor: AppConstants.accentGold,
    actions: [
    ElevatedButton.icon(
    onPressed: () => admin.fetchAllData(),
    icon: const Icon(Icons.refresh_rounded, size: 17),
    label: const Text('Sync KYC Queue'),
    ),
    ],
    ),
    statStrip: NexPayStatStrip(
    items: [
    NexPayStatItem(
    label: 'Pending KYC Queue',
    value: '$pendingCount Applicants',
    sublabel: 'Awaiting document & selfie review',
    icon: Icons.pending_actions_rounded,
    color: AppConstants.accentGold,
    ),
    NexPayStatItem(
    label: 'Verified Level-2 Accounts',
    value: '$verifiedCount Verified',
    sublabel: 'Full daily transaction limits unlocked',
    icon: Icons.verified_user_rounded,
    color: AppConstants.accentGreen,
    ),
    NexPayStatItem(
    label: 'Unverified / Rejected',
    value: '$unverifiedCount Accounts',
    sublabel: 'Basic tier or resubmission required',
    icon: Icons.person_search_rounded,
    color: AppConstants.dangerRed,
    ),
    NexPayStatItem(
    label: 'Total Customer Base',
    value: '${allCustomers.length} Profiles',
    sublabel: 'Live identity database',
    icon: Icons.shield_outlined,
    color: AppConstants.accentBlue,
    ),
    ],
    ),
    filterBar: NexPayFilterBar(
    searchController: _searchCtrl,
    searchHint: 'Search applicant by name, mobile, or CNIC number...',
    onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
    filters: const ['PENDING', 'VERIFIED', 'UNVERIFIED', 'ALL'],
    selectedFilter: _statusFilter,
    onFilterChanged: (f) => setState(() => _statusFilter = f),
    resultSummary:
    'Showing ${filtered.length} of ${allCustomers.length} profiles',
    ),
    body: NexPayFullWidthTable(
    minTableWidth: 1120,
    emptyState: const NexPayEmptyState(
    icon: Icons.verified_user_outlined,
    title: 'No KYC Applications In This Queue',
    subtitle:
    'Switch filter tabs above (e.g., VERIFIED or ALL) to inspect other customer records.',
    ),
    columns: const [
    DataColumn(label: Text('APPLICANT NAME')),
    DataColumn(label: Text('MOBILE NUMBER')),
    DataColumn(label: Text('SUBMITTED CNIC')),
    DataColumn(label: Text('RESIDENTIAL ADDRESS')),
    DataColumn(label: Text('KYC STATUS')),
    DataColumn(label: Text('DOCUMENT AUDIT')),
    ],
    rows: filtered.map((u) {
    final mobile = u['mobile'].toString();
    final name = (u['name'] ?? 'Applicant').toString();
    final cnic = (u['cnic'] ?? 'Not Provided').toString();
    final address = (u['address'] ?? '-').toString();
    final isVerified = u['isKycVerified'] == true ||
    u['isKycVerified'] == 1 ||
    (u['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    final st = (u['kycStatus'] ?? (isVerified ? 'VERIFIED' : 'UNVERIFIED'))
        .toString()
        .toUpperCase();

    return DataRow(
    cells: [
    DataCell(Text(name,
    style: TextStyle(
    color: AppConstants.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 13.5))),
    DataCell(NexPayCopyableId(text: mobile, label: 'Mobile')),
    DataCell(cnic != 'Not Provided'
    ? NexPayCopyableId(text: cnic, label: 'CNIC')
        : Text(cnic,
    style: TextStyle(
    color: AppConstants.textMuted,
    fontWeight: FontWeight.w600))),
    DataCell(
    SizedBox(
    width: 240,
    child: Text(address,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
    color: AppConstants.textSecondary, fontSize: 12.5)),
    ),
    ),
    DataCell(NexPayStatusBadge(status: st)),
    DataCell(
    ElevatedButton.icon(
    onPressed: () => _openKycAuditDrawer(context, admin, u),
    icon: const Icon(Icons.badge_outlined, size: 16),
    label: Text(
    st == 'PENDING' ? 'Inspect & Approve' : 'View Proofs'),
    ),
    ),
    ],
    );
    }).toList(),
    ),
    );
  }

  void _openKycAuditDrawer(
      BuildContext context, AdminProvider admin, Map<String, dynamic> u) {
    final mobile = u['mobile'].toString();
    final name = (u['name'] ?? '').toString();
    final email = (u['email'] ?? '').toString();
    final cnic = (u['cnic'] ?? '').toString();
    final address = (u['address'] ?? '').toString();
    final isVerified = u['isKycVerified'] == true ||
        u['isKycVerified'] == 1 ||
        (u['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    final status = (u['kycStatus'] ?? (isVerified ? 'VERIFIED' : 'UNVERIFIED'))
        .toString()
        .toUpperCase();

    showNexPayInspectorDrawer(
      context: context,
      width: 650,
      title: 'Biometric KYC Dossier: $name',
      subtitle: 'Mobile: $mobile • CNIC: $cnic',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name,
                          style: TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    NexPayStatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    NexPayCopyableId(text: mobile, label: 'Mobile'),
                    if (cnic.isNotEmpty)
                      NexPayCopyableId(text: cnic, label: 'CNIC'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Email: $email   •   Address: $address',
                    style:
                    TextStyle(color: AppConstants.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'SUBMITTED IDENTITY DOCUMENTS (SCROLL / PINCH OR OPEN LIGHTBOX)',
            style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FutureBuilder(
          future: admin.getKycProof(mobile),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppConstants.accentGreen)),
              );
            }
            final docs = snap.data ?? {};
            final front = (docs['cnicFront'] ??
                docs['front'] ??
                u['cnicFront'] ??
                '')
                .toString();
            final back =
            (docs['cnicBack'] ?? docs['back'] ?? u['cnicBack'] ?? '')
                .toString();
            final selfie = (docs['selfie'] ??
                docs['liveSelfie'] ??
                u['selfie'] ??
                '')
                .toString();

            return Column(
              children: [
                _docCard(context, 'CNIC Front Scan', front),
                const SizedBox(height: 14),
                _docCard(context, 'CNIC Back Scan', back),
                const SizedBox(height: 14),
                _docCard(context, 'Biometric Live Selfie', selfie),
              ],
            );
          },
          ),
        ],
      ),
      footerActions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.dangerRed),
          onPressed: () async {
            final confirmed = await showNexPayConfirmDialog(
              context: context,
              title: 'Reject & Reset KYC',
              message:
              'Decline submitted documents for $name ($mobile) and require fresh biometric upload?',
              confirmLabel: 'Reject & Reset',
              confirmColor: AppConstants.dangerRed,
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.resetUserKyc(mobile);
            if (context.mounted) {
              _toast(
                  context,
                  ok
                      ? 'KYC rejected & reset for resubmission.'
                      : 'Reset failed.',
                  ok);
            }
          },
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Reject & Reset KYC'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final confirmed = await showNexPayConfirmDialog(
              context: context,
              title: 'Approve Level-2 KYC',
              message:
              'Verify identity for $name ($mobile) and unlock full Tier-2 transaction limits?',
              confirmLabel: 'Approve Level-2 KYC',
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.updateUserFullProfile(
              oldMobile: mobile,
              newMobile: mobile,
              name: name,
              email: email,
              cnic: cnic,
              address: address,
              isKycVerified: true,
              kycStatus: 'VERIFIED',
            );
            if (context.mounted) {
              _toast(
                  context,
                  ok ? 'Customer $name KYC Verified!' : 'Approval failed.',
                  ok);
            }
          },
          icon: const Icon(Icons.verified_rounded, size: 17),
          label: const Text('Approve Level-2 KYC'),
        ),
      ],
    );
  }

  Widget _docCard(BuildContext context, String title, String rawImg) {
    final hasImage = rawImg.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
              if (hasImage &&
                  (rawImg.startsWith('http://') ||
                      rawImg.startsWith('https://')))
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => showNexPayImageViewer(
                    context: context,
                    title: title,
                    imageUrl: rawImg,
                  ),
                  icon: Icon(Icons.fullscreen_rounded,
                      size: 16, color: AppConstants.accentBlue),
                  label: Text('Full Zoom',
                      style: TextStyle(
                          color: AppConstants.accentBlue,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: !hasImage
                ? Center(
                child: Text('No image uploaded for this slot.',
                    style: TextStyle(
                        color: AppConstants.textMuted, fontSize: 12)))
                : InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.5,
              child: _decodeImg(rawImg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decodeImg(String src) {
    try {
      if (src.startsWith('http://') || src.startsWith('https://')) {
        return Image.network(src, fit: BoxFit.contain);
      }
      final clean = src.contains(',') ? src.split(',').last : src;
      return Image.memory(base64Decode(clean), fit: BoxFit.contain);
    } catch (_) {
      return Center(
          child: Text('Invalid image encoding',
              style: TextStyle(color: AppConstants.dangerRed)));
    }
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