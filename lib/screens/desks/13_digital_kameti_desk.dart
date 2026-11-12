import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class DigitalKametiDeskScreen extends StatefulWidget {
  const DigitalKametiDeskScreen({super.key});

  @override
  State<DigitalKametiDeskScreen> createState() =>
      _DigitalKametiDeskScreenState();
}

class _DigitalKametiDeskScreenState extends State<DigitalKametiDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0', 'en_US');
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
    final pools = admin.kametiPools;
    final members = admin.kametiMembers;

    double totalMonthlyRunRate = 0;
    int activePools = 0;

    for (final raw in pools) {
      if (raw is! Map) continue;
      final st = (raw['status'] ?? 'ACTIVE').toString().toUpperCase();
      final monthly = double.tryParse(raw['monthly_amount']?.toString() ??
          raw['monthlyAmount']?.toString() ??
          '0') ??
          0;
      final cap = int.tryParse(raw['total_members']?.toString() ??
          raw['totalMembers']?.toString() ??
          '0') ??
          0;
      if (st == 'ACTIVE' || st == 'OPEN') activePools++;
      totalMonthlyRunRate += (monthly * cap);
    }

    final filtered = pools.where((raw) {
      if (raw is! Map) return false;
      final st = (raw['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_statusFilter == 'ACTIVE' && !(st == 'ACTIVE' || st == 'OPEN')) {
        return false;
      }
      if (_statusFilter == 'COMPLETED' && st != 'COMPLETED') return false;

      if (_query.isEmpty) return true;
      final hay = '${raw['id']} ${raw['title']} ${raw['status']}'.toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Digital Kameti ROSCA Committees & Pot Disbursement',
        subtitle:
        'Launch verified rotating savings committees, audit member installments, and release monthly payouts',
        badgeText: 'ROSCA TREASURY',
        badgeColor: AppConstants.accentGreen,
        actions: [
          OutlinedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Committees'),
          ),
          ElevatedButton.icon(
            onPressed: () => _openCreatePoolDrawer(context, admin),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Create Kameti Pool'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Active Kameti Pools',
            value: '$activePools Committees',
            sublabel: '${pools.length} total ROSCA pools created',
            icon: Icons.groups_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Enrolled Participants',
            value: '${members.length} Members',
            sublabel: 'KYC-verified committee subscribers',
            icon: Icons.person_pin_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Monthly Pool Liquidity',
            value: 'Rs. ${_money.format(totalMonthlyRunRate)}',
            sublabel: 'Aggregate monthly pot rotation',
            icon: Icons.account_balance_wallet_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Payout Governance',
            value: 'Admin Audited',
            sublabel: 'Manual or Lucky-Draw pot release',
            icon: Icons.verified_user_rounded,
            color: AppConstants.accentGreen,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search committee by pool ID or title...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'COMPLETED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary:
        'Showing ${filtered.length} of ${pools.length} Kameti pools',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1140,
        emptyState: const NexPayEmptyState(
          icon: Icons.groups_rounded,
          title: 'No Digital Kameti Pools Found',
          subtitle:
          'Click "Create Kameti Pool" above to launch a new rotating savings committee.',
        ),
        columns: const [
          DataColumn(label: Text('POOL ID')),
          DataColumn(label: Text('COMMITTEE TITLE')),
          DataColumn(label: Text('MONTHLY SHARE'), numeric: true),
          DataColumn(label: Text('ENROLLED / CAPACITY')),
          DataColumn(label: Text('DURATION')),
          DataColumn(label: Text('TOTAL POT VALUE'), numeric: true),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('POOL MANAGEMENT')),
        ],
        rows: filtered.map((raw) {
          final p = Map<String, dynamic>.from(raw as Map);
          final id = int.tryParse(p['id']?.toString() ?? '0') ?? 0;
          final title = (p['title'] ?? 'Kameti Committee').toString();
          final monthly = double.tryParse(p['monthly_amount']?.toString() ??
              p['monthlyAmount']?.toString() ??
              '0') ??
              0;
          final totalMembers = int.tryParse(p['total_members']?.toString() ??
              p['totalMembers']?.toString() ??
              '10') ??
              10;
          final totalMonths = int.tryParse(p['total_months']?.toString() ??
              p['totalMonths']?.toString() ??
              '$totalMembers') ??
              totalMembers;
          final poolMembers = members
              .where((m) =>
          m is Map &&
              (m['pool_id']?.toString() == '$id' ||
                  m['kameti_id']?.toString() == '$id'))
              .toList();
          final grossPot = monthly * totalMembers;
          final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();

          return DataRow(
            cells: [
              DataCell(NexPayCopyableId(text: '#KM-$id', label: 'Pool ID')),
              DataCell(
                Text(title,
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w700)),
              ),
              DataCell(
                Text('Rs. ${_money.format(monthly)}',
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              DataCell(
                Text(
                  '${poolMembers.length} / $totalMembers Members',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentBlue),
                ),
              ),
              DataCell(
                Text('$totalMonths Months',
                    style: TextStyle(
                        color: AppConstants.textSecondary, fontSize: 12.5)),
              ),
              DataCell(
                Text(
                  'Rs. ${_money.format(grossPot)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentGold,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openPoolInspectorDrawer(
                          context, admin, p, poolMembers),
                      icon: const Icon(Icons.emoji_events_outlined, size: 15),
                      label: const Text('Manage & Release Pot'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Delete Pool',
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final confirmed = await showNexPayConfirmDialog(
                          context: context,
                          title: 'Delete Kameti Pool #KM-$id',
                          message:
                          'Are you sure you want to delete "$title"? Active pools with enrolled members cannot be removed.',
                          confirmLabel: 'Delete Pool',
                          confirmColor: AppConstants.dangerRed,
                          icon: Icons.delete_outline_rounded,
                        );
                        if (!confirmed || !context.mounted) return;
                        final ok = await admin.deleteKametiPool(id);
                        if (context.mounted) {
                          _toast(
                              context,
                              ok
                                  ? 'Kameti pool #KM-$id deleted.'
                                  : 'Cannot delete active pool.',
                              ok);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openCreatePoolDrawer(BuildContext context, AdminProvider admin) {
    final titleCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController(text: '10000');
    final membersCtrl = TextEditingController(text: '10');
    final monthsCtrl = TextEditingController(text: '10');

    showNexPayInspectorDrawer(
      context: context,
      title: 'Launch New Digital Kameti Pool',
      subtitle:
      'Configure monthly contribution, slot capacity, and committee cycle',
      child: StatefulBuilder(
        builder: (ctx, setDrawerState) {
          final monthly = double.tryParse(monthlyCtrl.text.trim()) ?? 0;
          final slots = int.tryParse(membersCtrl.text.trim()) ?? 0;
          final potPreview = monthly * slots;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: AppConstants.textPrimary),
                decoration: const InputDecoration(
                    labelText:
                    'Committee Title (e.g. Executive 100K Gold Kameti)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: monthlyCtrl,
                onChanged: (_) => setDrawerState(() {}),
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppConstants.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Monthly Installment Per Member (PKR)',
                    prefixText: 'Rs. '),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: membersCtrl,
                      onChanged: (_) => setDrawerState(() {}),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Total Member Slots'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: monthsCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration:
                      const InputDecoration(labelText: 'Duration (Months)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Calculated Monthly Pot Payout:',
                        style: TextStyle(
                            color: AppConstants.textMuted, fontSize: 12.5)),
                    Text(
                      'Rs. ${_money.format(potPreview)}',
                      style: TextStyle(
                          color: AppConstants.accentGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      footerActions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: () async {
            final title = titleCtrl.text.trim();
            final monthly = double.tryParse(monthlyCtrl.text.trim()) ?? 0;
            final count = int.tryParse(membersCtrl.text.trim()) ?? 0;
            final months = int.tryParse(monthsCtrl.text.trim()) ?? count;
            if (title.isEmpty || monthly <= 0 || count < 2) {
              _toast(
                  context,
                  'Enter valid pool title, monthly amount, and at least 2 members.',
                  false);
              return;
            }
            Navigator.pop(context);
            final ok =
            await admin.createKametiPool(title, monthly, count, months);
            if (context.mounted) {
              _toast(
                  context,
                  ok
                      ? 'Kameti pool "$title" launched!'
                      : 'Failed to create pool.',
                  ok);
            }
          },
          icon: const Icon(Icons.rocket_launch_rounded, size: 17),
          label: const Text('Launch Committee'),
        ),
      ],
    );
  }

  void _openPoolInspectorDrawer(
      BuildContext context,
      AdminProvider admin,
      Map<String, dynamic> p,
      List<dynamic> poolMembers,
      ) {
    final id = int.tryParse(p['id']?.toString() ?? '0') ?? 0;
    final title = (p['title'] ?? 'Kameti Committee').toString();
    final monthly = double.tryParse(p['monthly_amount']?.toString() ??
        p['monthlyAmount']?.toString() ??
        '0') ??
        0;
    final totalMembers = int.tryParse(p['total_members']?.toString() ??
        p['totalMembers']?.toString() ??
        '10') ??
        10;
    final grossPot = monthly * totalMembers;
    String selectedWinnerMobile = '';

    showNexPayInspectorDrawer(
      context: context,
      width: 560,
      title: 'Committee #KM-$id: $title',
      subtitle:
      'Monthly Share: Rs. ${_money.format(monthly)} • Total Pot: Rs. ${_money.format(grossPot)}',
      child: StatefulBuilder(
        builder: (ctx, setDrawerState) {
          return Column(
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
                    Text('MONTHLY POT DISBURSEMENT VALUE',
                        style: TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Rs. ${_money.format(grossPot)}',
                        style: TextStyle(
                            color: AppConstants.accentGold,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Enrolled Slots: ${poolMembers.length} / $totalMembers',
                        style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'ENROLLED MEMBERS (SELECT SPECIFIC RECIPIENT OR LEAVE EMPTY FOR LUCKY DRAW)',
                style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (poolMembers.isEmpty)
                Text('No customers have joined this pool yet.',
                    style:
                    TextStyle(color: AppConstants.textMuted, fontSize: 13))
              else
                ...poolMembers.map((rawM) {
                  if (rawM is! Map) return const SizedBox.shrink();
                  final mob =
                  (rawM['user_mobile'] ?? rawM['mobile'] ?? '').toString();
                  final mName =
                  (rawM['user_name'] ?? rawM['name'] ?? 'Member')
                      .toString();
                  final hasWon = rawM['has_won'] == 1 ||
                      rawM['has_won'] == true ||
                      rawM['won'] == true;
                  final isSelected = selectedWinnerMobile == mob;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppConstants.accentGreenLight
                          : AppConstants.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected
                              ? AppConstants.accentGreen
                              : AppConstants.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mName,
                                  style: TextStyle(
                                      color: AppConstants.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(mob,
                                  style: TextStyle(
                                      color: AppConstants.textMuted,
                                      fontSize: 11.5)),
                            ],
                          ),
                        ),
                        if (hasWon)
                          const NexPayStatusBadge(status: 'POT RECEIVED')
                        else
                          OutlinedButton(
                            onPressed: () {
                              setDrawerState(() {
                                selectedWinnerMobile = isSelected ? '' : mob;
                              });
                            },
                            child: Text(isSelected
                                ? 'Selected Winner'
                                : 'Select Recipient'),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
      footerActions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        ElevatedButton.icon(
          onPressed: () async {
            final targetDesc = selectedWinnerMobile.isEmpty
                ? 'automated Lucky Draw across eligible members'
                : 'selected recipient $selectedWinnerMobile';
            final confirmed = await showNexPayConfirmDialog(
              context: context,
              title: 'Release Monthly Pot (#KM-$id)',
              message:
              'Disburse Rs. ${_money.format(grossPot)} via $targetDesc?',
              confirmLabel: 'Confirm Release',
              icon: Icons.emoji_events_rounded,
            );
            if (!confirmed || !context.mounted) return;
            Navigator.pop(context);
            final ok = await admin.releaseKametiPot(id,
                targetMobile: selectedWinnerMobile);
            if (context.mounted) {
              _toast(
                context,
                ok
                    ? (selectedWinnerMobile.isEmpty
                    ? 'Lucky Draw executed & pot disbursed for #KM-$id!'
                    : 'Kameti pot released to $selectedWinnerMobile!')
                    : 'Pot release failed.',
                ok,
              );
            }
          },
          icon: const Icon(Icons.emoji_events_rounded, size: 17),
          label: const Text('Release Monthly Pot'),
        ),
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