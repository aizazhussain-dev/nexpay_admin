import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class ClosureRequestsDeskScreen extends StatefulWidget {
  const ClosureRequestsDeskScreen({super.key});

  @override
  State<ClosureRequestsDeskScreen> createState() =>
      _ClosureRequestsDeskScreenState();
}

class _ClosureRequestsDeskScreenState extends State<ClosureRequestsDeskScreen> {
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
    final requests = admin.closureRequests;

    int pendingCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;

    for (final raw in requests) {
      if (raw is! Map) continue;
      final st = (raw['status'] ?? 'PENDING').toString().toUpperCase();
      if (st == 'PENDING') {
        pendingCount++;
      } else if (st == 'APPROVED' || st == 'CLOSED' || st == 'COMPLETED') {
        approvedCount++;
      } else {
        rejectedCount++;
      }
    }

    final filtered = requests.where((raw) {
      if (raw is! Map) return false;
      final st = (raw['status'] ?? 'PENDING').toString().toUpperCase();
      if (_statusFilter == 'PENDING' && st != 'PENDING') return false;
      if (_statusFilter == 'APPROVED' &&
          !(st == 'APPROVED' || st == 'CLOSED' || st == 'COMPLETED')) {
        return false;
      }
      if (_statusFilter == 'REJECTED' && st != 'REJECTED') return false;

      if (_query.isEmpty) return true;
      final hay =
      '${raw['id']} ${raw['user_mobile']} ${raw['mobile']} ${raw['user_name']} ${raw['reason']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Account Closure & Offboarding Desk',
        subtitle:
        'Verify zero outstanding loan liabilities, audit residual balances, and execute permanent account closures',
        badgeText: 'COMPLIANCE OFFBOARDING',
        badgeColor: AppConstants.dangerRed,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Requests'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Pending Closures',
            value: '$pendingCount Requests',
            sublabel: 'Awaiting compliance clearance',
            icon: Icons.person_off_outlined,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Closed Accounts',
            value: '$approvedCount Terminated',
            sublabel: 'Offboarded and archived',
            icon: Icons.check_circle_outline_rounded,
            color: AppConstants.dangerRed,
          ),
          NexPayStatItem(
            label: 'Declined / Retained',
            value: '$rejectedCount Retained',
            sublabel: 'Blocked due to active liabilities',
            icon: Icons.verified_user_outlined,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Total Offboarding Queue',
            value: '${requests.length} Cases',
            sublabel: 'Live smartvest.tech database records',
            icon: Icons.folder_delete_outlined,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint:
        'Search by request ID, customer mobile, name, or reason...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'PENDING', 'APPROVED', 'REJECTED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary:
        'Showing ${filtered.length} of ${requests.length} requests',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const NexPayEmptyState(
          icon: Icons.person_off_rounded,
          title: 'No Account Closure Requests',
          subtitle:
          'There are no account termination requests matching your filter in the live database.',
        ),
        columns: const [
          DataColumn(label: Text('REQUEST ID')),
          DataColumn(label: Text('CUSTOMER & MOBILE')),
          DataColumn(label: Text('RESIDUAL WALLET'), numeric: true),
          DataColumn(label: Text('CLOSURE REASON')),
          DataColumn(label: Text('SUBMITTED AT')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CLEARANCE')),
        ],
        rows: filtered.map((raw) {
          final r = Map<String, dynamic>.from(raw as Map);
          final id = int.tryParse(r['id']?.toString() ?? '0') ?? 0;
          final mobile = (r['user_mobile'] ?? r['mobile'] ?? '-').toString();
          final userMap = admin.users[mobile] is Map
              ? Map<String, dynamic>.from(admin.users[mobile])
              : <String, dynamic>{};
          final name =
          (r['user_name'] ?? userMap['name'] ?? 'Customer').toString();
          final bal = double.tryParse(userMap['balance']?.toString() ??
              r['balance']?.toString() ??
              '0') ??
              0;
          final reason =
          (r['reason'] ?? 'Customer requested account closure').toString();
          final date = (r['created_at'] ?? r['date'] ?? '-').toString();
          final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
          final isPending = status == 'PENDING';

          return DataRow(
            cells: [
              DataCell(NexPayCopyableId(text: '#CLS-$id', label: 'Request ID')),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w700)),
                    Text(mobile,
                        style: TextStyle(
                            color: AppConstants.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              DataCell(
                Text(
                  'Rs. ${_money.format(bal)}',
                  style: TextStyle(
                    color: bal > 0
                        ? AppConstants.accentGold
                        : AppConstants.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 240,
                  child: Text(reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppConstants.textSecondary, fontSize: 12.5)),
                ),
              ),
              DataCell(
                Text(date,
                    style:
                    TextStyle(color: AppConstants.textMuted, fontSize: 12)),
              ),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () =>
                      _openClosureDrawer(context, admin, r, userMap),
                  icon: const Icon(Icons.assignment_turned_in_outlined,
                      size: 15),
                  label: Text(isPending ? 'Adjudicate' : 'Details'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openClosureDrawer(BuildContext context, AdminProvider admin,
      Map<String, dynamic> r, Map<String, dynamic> userMap) {
    final id = int.tryParse(r['id']?.toString() ?? '0') ?? 0;
    final mobile = (r['user_mobile'] ?? r['mobile'] ?? '-').toString();
    final name = (r['user_name'] ?? userMap['name'] ?? 'Customer').toString();
    final bal = double.tryParse(userMap['balance']?.toString() ??
        r['balance']?.toString() ??
        '0') ??
        0;
    final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';

    showNexPayInspectorDrawer(
      context: context,
      title: 'Account Closure #CLS-$id',
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
                Text('RESIDUAL WALLET BALANCE',
                    style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rs. ${_money.format(bal)}',
                    style: TextStyle(
                        color: bal > 0
                            ? AppConstants.accentGold
                            : AppConstants.accentGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                NexPayStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NexPayDetailSection(
            title: 'Offboarding Compliance Audit',
            children: [
              NexPayKeyValueRow(
                  label: 'Request ID', value: '#CLS-$id', copyable: true),
              NexPayKeyValueRow(label: 'Customer Name', value: name),
              NexPayKeyValueRow(
                  label: 'Mobile Account', value: mobile, copyable: true),
              NexPayKeyValueRow(
                  label: 'Stated Reason',
                  value: (r['reason'] ?? 'Customer requested closure')
                      .toString()),
              NexPayKeyValueRow(
                  label: 'Submitted At',
                  value: (r['created_at'] ?? r['date'] ?? '-').toString()),
            ],
          ),
          if (isPending && bal > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.dangerRedLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppConstants.dangerRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Compliance Warning: This account still holds Rs. ${_money.format(bal)}. Ensure residual funds are settled before approving permanent closure.',
                style: TextStyle(
                    color: AppConstants.dangerRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      footerActions: isPending
          ? [
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showNexPayConfirmDialog(
              context: context,
              title: 'Reject Closure Request',
              message:
              'Decline closure request #CLS-$id and retain $mobile as active?',
              confirmLabel: 'Reject Request',
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.reviewClosureRequest(
                id, mobile, 'REJECTED');
            if (context.mounted) {
              _toast(
                  context,
                  ok
                      ? 'Closure request #CLS-$id declined.'
                      : 'Action failed.',
                  ok);
            }
          },
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Reject Request'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.dangerRed),
          onPressed: () async {
            final confirmed = await showNexPayConfirmDialog(
              context: context,
              title: 'Approve Permanent Closure',
              message:
              'Permanently close and offboard account $mobile ($name)?',
              confirmLabel: 'Approve & Close',
              confirmColor: AppConstants.dangerRed,
              icon: Icons.person_off_rounded,
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.reviewClosureRequest(
                id, mobile, 'APPROVED');
            if (context.mounted) {
              _toast(
                  context,
                  ok
                      ? 'Account $mobile closed & offboarded.'
                      : 'Action failed.',
                  ok);
            }
          },
          icon: const Icon(Icons.person_off_rounded, size: 17),
          label: const Text('Approve & Close Account'),
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