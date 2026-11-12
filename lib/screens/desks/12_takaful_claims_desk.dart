import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class TakafulClaimsDeskScreen extends StatefulWidget {
  const TakafulClaimsDeskScreen({super.key});

  @override
  State<TakafulClaimsDeskScreen> createState() => _TakafulClaimsDeskScreenState();
}

class _TakafulClaimsDeskScreenState extends State<TakafulClaimsDeskScreen> {
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
    final claims = admin.takafulClaims;

    int pendingCount = 0;
    double pendingClaimAmt = 0;
    int approvedCount = 0;
    double approvedClaimAmt = 0;
    int rejectedCount = 0;

    for (final raw in claims) {
      if (raw is! Map) continue;
      final st = (raw['status'] ?? 'PENDING').toString().toUpperCase();
      final amt = double.tryParse(raw['claim_amount']?.toString() ?? raw['amount']?.toString() ?? '0') ?? 0;
      if (st == 'PENDING' || st == 'UNDER_REVIEW') {
        pendingCount++;
        pendingClaimAmt += amt;
      } else if (st == 'APPROVED' || st == 'SETTLED' || st == 'COMPLETED') {
        approvedCount++;
        approvedClaimAmt += amt;
      } else {
        rejectedCount++;
      }
    }

    final filtered = claims.where((raw) {
      if (raw is! Map) return false;
      final st = (raw['status'] ?? 'PENDING').toString().toUpperCase();
      if (_statusFilter == 'PENDING' && !(st == 'PENDING' || st == 'UNDER_REVIEW')) return false;
      if (_statusFilter == 'APPROVED' && !(st == 'APPROVED' || st == 'SETTLED' || st == 'COMPLETED')) return false;
      if (_statusFilter == 'REJECTED' && st != 'REJECTED') return false;

      if (_query.isEmpty) return true;
      final hay = '${raw['id']} ${raw['claim_id']} ${raw['user_mobile']} ${raw['user_name']} ${raw['plan_name']} ${raw['incident_type']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Islamic Takaful Claims & Coverage Adjudication',
        subtitle: 'Review Shariah-compliant Takaful protection claims, verify incident evidence, and disburse settlements',
        badgeText: 'TAKAFUL RISK DESK',
        badgeColor: AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Claims Queue'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Pending Adjudication',
            value: '$pendingCount Claims',
            sublabel: 'Rs. ${_money.format(pendingClaimAmt)} awaiting review',
            icon: Icons.pending_actions_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Settled Takaful Claims',
            value: '$approvedCount Approved',
            sublabel: 'Rs. ${_money.format(approvedClaimAmt)} paid from Waqf pool',
            icon: Icons.health_and_safety_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Declined Claims',
            value: '$rejectedCount Rejected',
            sublabel: 'Did not meet policy terms',
            icon: Icons.gpp_bad_outlined,
            color: AppConstants.dangerRed,
          ),
          NexPayStatItem(
            label: 'Total Claims Filed',
            value: '${claims.length} Files',
            sublabel: 'Live smartvest.tech Takaful ledger',
            icon: Icons.shield_outlined,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search by claim ID, participant mobile, name, or plan...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'PENDING', 'APPROVED', 'REJECTED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary: 'Showing ${filtered.length} of ${claims.length} claims',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1140,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.health_and_safety_outlined,
          title: 'No Takaful Claims Found',
          subtitle: 'There are no Islamic Takaful claims matching your filter in the live database.',
        ),
        columns: const [
          DataColumn(label: Text('CLAIM ID')),
          DataColumn(label: Text('PARTICIPANT & MOBILE')),
          DataColumn(label: Text('TAKAFUL PLAN')),
          DataColumn(label: Text('INCIDENT / REASON')),
          DataColumn(label: Text('CLAIM AMOUNT'), numeric: true),
          DataColumn(label: Text('FILED DATE')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('ADJUDICATION')),
        ],
        rows: filtered.map((raw) {
          final c = Map<String, dynamic>.from(raw as Map);
          final claimId = (c['claim_id'] ?? c['id'] ?? '').toString();
          final mobile = (c['user_mobile'] ?? c['mobile'] ?? '-').toString();
          final name = (c['user_name'] ?? 'Participant').toString();
          final plan = (c['plan_name'] ?? c['policy_name'] ?? 'Takaful Shield').toString();
          final reason = (c['incident_type'] ?? c['reason'] ?? c['description'] ?? 'Medical / Protection Claim').toString();
          final amt = double.tryParse(c['claim_amount']?.toString() ?? c['amount']?.toString() ?? '0') ?? 0;
          final date = (c['created_at'] ?? c['date'] ?? '-').toString();
          final status = (c['status'] ?? 'PENDING').toString().toUpperCase();
          final isPending = status == 'PENDING' || status == 'UNDER_REVIEW';

          return DataRow(
            cells: [
              DataCell(Text('#TKF-$claimId', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppConstants.accentBlue))),
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
              DataCell(Text(plan, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
              DataCell(Text('Rs. ${_money.format(amt)}', style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text(date, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => _openClaimDrawer(context, admin, c),
                  icon: const Icon(Icons.gavel_rounded, size: 15),
                  label: Text(isPending ? 'Review' : 'Details'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openClaimDrawer(BuildContext context, AdminProvider admin, Map<String, dynamic> c) {
    final claimId = (c['claim_id'] ?? c['id'] ?? '').toString();
    final mobile = (c['user_mobile'] ?? c['mobile'] ?? '-').toString();
    final name = (c['user_name'] ?? 'Participant').toString();
    final plan = (c['plan_name'] ?? c['policy_name'] ?? 'Takaful Shield').toString();
    final amt = double.tryParse(c['claim_amount']?.toString() ?? c['amount']?.toString() ?? '0') ?? 0;
    final status = (c['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING' || status == 'UNDER_REVIEW';

    showNexPayInspectorDrawer(
      context: context,
      title: 'Takaful Claim #TKF-$claimId',
      subtitle: '$name ($mobile) • $plan',
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
                const Text('REQUESTED COVERAGE SETTLEMENT', style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rs. ${_money.format(amt)}', style: const TextStyle(color: AppConstants.accentGreen, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                NexPayStatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _kv('Participant Name', name),
          _kv('Mobile Number', mobile),
          _kv('Policy / Plan', plan),
          _kv('Incident Category', (c['incident_type'] ?? 'General Claim').toString()),
          _kv('Claim Narrative', (c['description'] ?? c['reason'] ?? 'No additional notes provided.').toString()),
          _kv('Submitted Timestamp', (c['created_at'] ?? c['date'] ?? '-').toString()),
        ],
      ),
      footerActions: isPending
          ? [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppConstants.dangerRed),
          onPressed: () async {
            Navigator.pop(context);
            final ok = await admin.reviewTakafulClaim(claimId, 'REJECTED');
            if (context.mounted) {
              _toast(context, ok ? 'Claim #TKF-$claimId rejected.' : 'Action failed.', ok);
            }
          },
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Reject Claim'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await admin.reviewTakafulClaim(claimId, 'APPROVED');
            if (context.mounted) {
              _toast(context, ok ? 'Claim #TKF-$claimId approved & settled!' : 'Action failed.', ok);
            }
          },
          icon: const Icon(Icons.check_circle_rounded, size: 17),
          label: const Text('Approve & Settle Claim'),
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