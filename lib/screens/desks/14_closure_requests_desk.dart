import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class ClosureRequestsDeskScreen extends StatefulWidget {
  const ClosureRequestsDeskScreen({super.key});

  @override
  State<ClosureRequestsDeskScreen> createState() => _ClosureRequestsDeskScreenState();
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
      if (_statusFilter == 'APPROVED' && !(st == 'APPROVED' || st == 'CLOSED' || st == 'COMPLETED')) return false;
      if (_statusFilter == 'REJECTED' && st != 'REJECTED') return false;

      if (_query.isEmpty) return true;
      final hay = '${raw['id']} ${raw['user_mobile']} ${raw['mobile']} ${raw['user_name']} ${raw['reason']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Account Closure & Offboarding Desk',
        subtitle: 'Verify zero outstanding loan liabilities, audit residual balances, and execute permanent account closures',
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
        searchHint: 'Search by request ID, customer mobile, name, or reason...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'PENDING', 'APPROVED', 'REJECTED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary: 'Showing ${filtered.length} of ${requests.length} requests',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.person_off_rounded,
          title: 'No Account Closure Requests',
          subtitle: 'There are no account termination requests matching your filter in the live database.',
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
          final userMap = admin.users[mobile] is Map ? Map<String, dynamic>.from(admin.users[mobile]) : <String, dynamic>{};
          final name = (r['user_name'] ?? userMap['name'] ?? 'Customer').toString();
          final bal = double.tryParse(userMap['balance']?.toString() ?? r['balance']?.toString() ?? '0') ?? 0;
          final reason = (r['reason'] ?? 'Customer requested account closure').toString();
          final date = (r['created_at'] ?? r['date'] ?? '-').toString();
          final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
          final isPending = status == 'PENDING';

          return DataRow(
            cells: [
              DataCell(Text('#CLS-$id', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppConstants.accentBlue))),
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
              DataCell(Text('Rs. ${_money.format(bal)}', style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(
                SizedBox(
                  width: 240,
                  child: Text(reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
              DataCell(Text(date, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => _openClosureDrawer(context, admin, r, userMap),
                  icon: const Icon(Icons.assignment_turned_in_outlined, size: 15),
                  label: Text(isPending ? 'Adjudicate' : 'Details'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openClosureDrawer(BuildContext context, AdminProvider admin, Map<String, dynamic> r, Map<String, dynamic> userMap) {
    final id = int.tryParse(r['id']?.toString() ?? '0') ?? 0;
    final mobile = (r['user_mobile'] ?? r['mobile'] ?? '-').toString();
    final name = (r['user_name'] ?? userMap['name'] ?? 'Customer').toString();
    final bal = double.tryParse(userMap['balance']?.toString() ?? r['balance']?.toString() ?? '0') ?? 0;
    final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';

    showNexPayInspectorDrawer(
      context: context,
      title: 'Account Closure #CLS-$id',
      subtitle: '$name ($mobile)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Customer Name', name),
          _kv('Mobile Account', mobile),
          _kv('Residual PKR Balance', 'Rs. ${_money.format(bal)}'),
          _kv('Stated Reason', (r['reason'] ?? 'Customer requested closure').toString()),
          _kv('Submitted Timestamp', (r['created_at'] ?? r['date'] ?? '-').toString()),
          _kv('Current Status', status),
        ],
      ),
      footerActions: isPending
          ? [
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await admin.reviewClosureRequest(id, mobile, 'REJECTED');
            if (context.mounted) {
              _toast(context, ok ? 'Closure request #CLS-$id declined.' : 'Action failed.', ok);
            }
          },
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Reject Request'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed),
          onPressed: () async {
            Navigator.pop(context);
            final ok = await admin.reviewClosureRequest(id, mobile, 'APPROVED');
            if (context.mounted) {
              _toast(context, ok ? 'Account $mobile closed & offboarded.' : 'Action failed.', ok);
            }
          },
          icon: const Icon(Icons.person_off_rounded, size: 17),
          label: const Text('Approve & Close Account'),
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