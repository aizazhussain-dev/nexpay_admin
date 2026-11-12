import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class LoansDeskScreen extends StatefulWidget {
  const LoansDeskScreen({super.key});

  @override
  State<LoansDeskScreen> createState() => _LoansDeskScreenState();
}

class _LoansDeskScreenState extends State<LoansDeskScreen> {
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
    final allLoans = admin.loans;

    int reviewCount = 0;
    double reviewVolume = 0;
    int approvedCount = 0;
    double approvedVolume = 0;
    int rejectedCount = 0;

    for (final raw in allLoans) {
      if (raw is! Map) continue;
      final st = (raw['status'] ?? 'UNDER_REVIEW').toString().toUpperCase();
      final amt = double.tryParse(raw['amount']?.toString() ?? '0') ?? 0;
      if (st == 'UNDER_REVIEW' || st == 'PENDING') {
        reviewCount++;
        reviewVolume += amt;
      } else if (st == 'APPROVED' || st == 'ACTIVE' || st == 'DISBURSED') {
        approvedCount++;
        approvedVolume += amt;
      } else {
        rejectedCount++;
      }
    }

    final filtered = allLoans.where((raw) {
      if (raw is! Map) return false;
      final st = (raw['status'] ?? 'UNDER_REVIEW').toString().toUpperCase();
      if (_statusFilter == 'UNDER_REVIEW' &&
          !(st == 'UNDER_REVIEW' || st == 'PENDING')) {
        return false;
      }
      if (_statusFilter == 'APPROVED' &&
          !(st == 'APPROVED' || st == 'ACTIVE' || st == 'DISBURSED')) {
        return false;
      }
      if (_statusFilter == 'REJECTED' && st != 'REJECTED') return false;

      if (_query.isEmpty) return true;
      final hay =
      '${raw['id']} ${raw['user_mobile']} ${raw['mobile']} ${raw['user_name']} ${raw['purpose']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'EasyCash Micro-Loans & Credit Underwriting',
        subtitle:
        'Evaluate borrower KYC eligibility, review credit applications, and disburse approved loan principals',
        badgeText: 'CREDIT ENGINE',
        badgeColor: AppConstants.accentBlue,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Credit Queue'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Under Review Queue',
            value: '$reviewCount Applications',
            sublabel: 'Rs. ${_money.format(reviewVolume)} requested principal',
            icon: Icons.rate_review_outlined,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Approved & Disbursed',
            value: '$approvedCount Loans',
            sublabel: 'Rs. ${_money.format(approvedVolume)} active credit book',
            icon: Icons.verified_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Declined Applications',
            value: '$rejectedCount Rejected',
            sublabel: 'Did not meet credit score criteria',
            icon: Icons.cancel_outlined,
            color: AppConstants.dangerRed,
          ),
          NexPayStatItem(
            label: 'Total Credit Book',
            value: 'Rs. ${_money.format(reviewVolume + approvedVolume)}',
            sublabel: '${allLoans.length} total loan files in database',
            icon: Icons.account_balance_rounded,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search by loan ID, borrower mobile, name, or purpose...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'UNDER_REVIEW', 'APPROVED', 'REJECTED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary:
        'Showing ${filtered.length} of ${allLoans.length} loan applications',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1140,
        emptyState: const NexPayEmptyState(
          icon: Icons.account_balance_rounded,
          title: 'No Loan Applications Found',
          subtitle:
          'There are no credit requests matching your current filter in the live database.',
        ),
        columns: const [
          DataColumn(label: Text('LOAN ID')),
          DataColumn(label: Text('BORROWER & MOBILE')),
          DataColumn(label: Text('PRINCIPAL (PKR)'), numeric: true),
          DataColumn(label: Text('REPAYMENT / TENURE')),
          DataColumn(label: Text('PURPOSE')),
          DataColumn(label: Text('APPLIED DATE')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('UNDERWRITING')),
        ],
        rows: filtered.map((raw) {
          final l = Map<String, dynamic>.from(raw as Map);
          final id = int.tryParse(l['id']?.toString() ?? '0') ?? 0;
          final mobile = (l['user_mobile'] ?? l['mobile'] ?? '-').toString();
          final userMap = admin.users[mobile] is Map
              ? Map<String, dynamic>.from(admin.users[mobile])
              : <String, dynamic>{};
          final name =
          (l['user_name'] ?? userMap['name'] ?? 'Borrower').toString();
          final amt = double.tryParse(l['amount']?.toString() ?? '0') ?? 0;
          final repay = double.tryParse(l['repayment_amount']?.toString() ??
              l['total_repay']?.toString() ??
              '0') ??
              0;
          final tenure =
          (l['tenure_days'] ?? l['tenure'] ?? '30 Days').toString();
          final purpose = (l['purpose'] ?? 'Personal Cash').toString();
          final date = (l['created_at'] ?? l['date'] ?? '-').toString();
          final status =
          (l['status'] ?? 'UNDER_REVIEW').toString().toUpperCase();
          final isPending = status == 'UNDER_REVIEW' || status == 'PENDING';

          return DataRow(
            cells: [
              DataCell(NexPayCopyableId(text: '#LN-$id', label: 'Loan ID')),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(mobile,
                        style: TextStyle(
                            color: AppConstants.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              DataCell(
                Text(
                  'Rs. ${_money.format(amt)}',
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        repay > 0
                            ? 'Rs. ${_money.format(repay)}'
                            : 'Standard Schedule',
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5)),
                    Text('Term: $tenure',
                        style: TextStyle(
                            color: AppConstants.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(Text(purpose,
                  style: TextStyle(
                      color: AppConstants.textPrimary, fontSize: 12.5))),
              DataCell(Text(date,
                  style: TextStyle(
                      color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () =>
                      _openLoanInspector(context, admin, l, userMap),
                  icon: const Icon(Icons.policy_outlined, size: 15),
                  label: Text(isPending ? 'Underwrite' : 'Inspect'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openLoanInspector(BuildContext context, AdminProvider admin,
      Map<String, dynamic> l, Map<String, dynamic> userMap) {
    final id = int.tryParse(l['id']?.toString() ?? '0') ?? 0;
    final mobile = (l['user_mobile'] ?? l['mobile'] ?? '-').toString();
    final name = (l['user_name'] ?? userMap['name'] ?? 'Borrower').toString();
    final amt = double.tryParse(l['amount']?.toString() ?? '0') ?? 0;
    final walletBal =
        double.tryParse(userMap['balance']?.toString() ?? '0') ?? 0;
    final isKyc = userMap['isKycVerified'] == true ||
        userMap['isKycVerified'] == 1 ||
        (userMap['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    final status = (l['status'] ?? 'UNDER_REVIEW').toString().toUpperCase();
    final isPending = status == 'UNDER_REVIEW' || status == 'PENDING';

    showNexPayInspectorDrawer(
      context: context,
      title: 'Credit Underwriting #LN-$id',
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
                Text('REQUESTED PRINCIPAL',
                    style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rs. ${_money.format(amt)}',
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    NexPayStatusBadge(status: status),
                    NexPayStatusBadge(
                        status: isKyc ? 'KYC VERIFIED' : 'KYC UNVERIFIED'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NexPayDetailSection(
            title: 'Borrower Risk & Identity Profile',
            children: [
              NexPayKeyValueRow(label: 'Legal Name', value: name),
              NexPayKeyValueRow(
                  label: 'Mobile Account', value: mobile, copyable: true),
              NexPayKeyValueRow(
                  label: 'CNIC Number',
                  value: (userMap['cnic'] ?? 'Not on file').toString(),
                  copyable: userMap['cnic'] != null),
              NexPayKeyValueRow(
                label: 'KYC Status',
                value: isKyc ? 'VERIFIED LEVEL-2' : 'UNVERIFIED',
                valueColor:
                isKyc ? AppConstants.accentGreen : AppConstants.dangerRed,
              ),
              NexPayKeyValueRow(
                  label: 'Current Wallet Bal',
                  value: 'Rs. ${_money.format(walletBal)}'),
            ],
          ),
          NexPayDetailSection(
            title: 'Facility Terms',
            children: [
              NexPayKeyValueRow(
                  label: 'Loan Purpose',
                  value: (l['purpose'] ?? 'Personal Cash').toString()),
              NexPayKeyValueRow(
                  label: 'Submitted Date',
                  value: (l['created_at'] ?? l['date'] ?? '-').toString()),
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
              title: 'Reject Loan Application',
              message:
              'Decline loan #LN-$id for $name ($mobile)?',
              confirmLabel: 'Reject Application',
              confirmColor: AppConstants.dangerRed,
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.reviewLoan(id, false);
            if (context.mounted) {
              _toast(
                  context,
                  ok ? 'Loan #LN-$id rejected.' : 'Action failed.',
                  ok);
            }
          },
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Reject Application'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final confirmed = await showNexPayConfirmDialog(
              context: context,
              title: 'Approve & Disburse Loan',
              message:
              'Approve #LN-$id and disburse Rs. ${_money.format(amt)} directly into $mobile\'s wallet?',
              confirmLabel: 'Approve & Disburse',
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.reviewLoan(id, true);
            if (context.mounted) {
              _toast(
                  context,
                  ok
                      ? 'Loan #LN-$id approved & disbursed to $mobile.'
                      : 'Approval failed.',
                  ok);
            }
          },
          icon: const Icon(Icons.check_circle_rounded, size: 17),
          label: const Text('Approve & Disburse'),
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