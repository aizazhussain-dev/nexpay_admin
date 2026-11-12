import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class SupportTicketsDeskScreen extends StatefulWidget {
  const SupportTicketsDeskScreen({super.key});

  @override
  State<SupportTicketsDeskScreen> createState() => _SupportTicketsDeskScreenState();
}

class _SupportTicketsDeskScreenState extends State<SupportTicketsDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
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
    final tickets = admin.tickets;

    int openCount = 0;
    int resolvedCount = 0;
    int closedCount = 0;

    for (final raw in tickets) {
      if (raw is! Map) continue;
      final st = (raw['status'] ?? 'OPEN').toString().toUpperCase();
      if (st == 'OPEN' || st == 'PENDING') {
        openCount++;
      } else if (st == 'RESOLVED') {
        resolvedCount++;
      } else {
        closedCount++;
      }
    }

    final filtered = tickets.where((raw) {
      if (raw is! Map) return false;
      final st = (raw['status'] ?? 'OPEN').toString().toUpperCase();
      if (_statusFilter == 'OPEN' && !(st == 'OPEN' || st == 'PENDING')) return false;
      if (_statusFilter == 'RESOLVED' && st != 'RESOLVED') return false;
      if (_statusFilter == 'CLOSED' && st != 'CLOSED') return false;

      if (_query.isEmpty) return true;
      final hay = '${raw['id']} ${raw['user_mobile']} ${raw['user_name']} ${raw['subject']} ${raw['message']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Customer Support & Dispute Resolution Desk',
        subtitle: 'Respond to customer inquiries, resolve transaction disputes, and close support tickets in real time',
        badgeText: 'LIVE HELPDESK',
        badgeColor: AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Tickets'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Open Tickets',
            value: '$openCount Awaiting',
            sublabel: 'Requires official support response',
            icon: Icons.mark_chat_unread_outlined,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Resolved Cases',
            value: '$resolvedCount Resolved',
            sublabel: 'Answered by support desk',
            icon: Icons.check_circle_outline_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Closed Tickets',
            value: '$closedCount Archived',
            sublabel: 'Completed customer sessions',
            icon: Icons.archive_outlined,
            color: AppConstants.textMuted,
          ),
          NexPayStatItem(
            label: 'Total Inquiries',
            value: '${tickets.length} Tickets',
            sublabel: 'Live smartvest.tech helpdesk queue',
            icon: Icons.support_agent_rounded,
            color: AppConstants.accentBlue,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search by ticket ID, mobile, subject, or message...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'OPEN', 'RESOLVED', 'CLOSED'],
        selectedFilter: _statusFilter,
        onFilterChanged: (f) => setState(() => _statusFilter = f),
        resultSummary: 'Showing ${filtered.length} of ${tickets.length} tickets',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.support_agent_rounded,
          title: 'No Support Tickets Found',
          subtitle: 'There are no customer support tickets matching your filter in the live database.',
        ),
        columns: const [
          DataColumn(label: Text('TICKET ID')),
          DataColumn(label: Text('CUSTOMER & MOBILE')),
          DataColumn(label: Text('SUBJECT')),
          DataColumn(label: Text('MESSAGE PREVIEW')),
          DataColumn(label: Text('CREATED AT')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('RESPONSE')),
        ],
        rows: filtered.map((raw) {
          final t = Map<String, dynamic>.from(raw as Map);
          final id = int.tryParse(t['id']?.toString() ?? '0') ?? 0;
          final mobile = (t['user_mobile'] ?? t['mobile'] ?? '-').toString();
          final name = (t['user_name'] ?? 'Customer').toString();
          final subject = (t['subject'] ?? t['category'] ?? 'General Support').toString();
          final msg = (t['message'] ?? '').toString();
          final date = (t['created_at'] ?? t['date'] ?? '-').toString();
          final status = (t['status'] ?? 'OPEN').toString().toUpperCase();

          return DataRow(
            cells: [
              DataCell(Text('#TK-$id', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppConstants.accentBlue))),
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
              DataCell(Text(subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
              DataCell(
                SizedBox(
                  width: 260,
                  child: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
              DataCell(Text(date, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12))),
              DataCell(NexPayStatusBadge(status: status)),
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => _openTicketDrawer(context, admin, t),
                  icon: const Icon(Icons.reply_rounded, size: 15),
                  label: Text(status == 'OPEN' ? 'Reply' : 'View Thread'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openTicketDrawer(BuildContext context, AdminProvider admin, Map<String, dynamic> t) {
    final id = int.tryParse(t['id']?.toString() ?? '0') ?? 0;
    final mobile = (t['user_mobile'] ?? t['mobile'] ?? '-').toString();
    final name = (t['user_name'] ?? 'Customer').toString();
    final subject = (t['subject'] ?? t['category'] ?? 'General Support').toString();
    final message = (t['message'] ?? '').toString();
    final existingReply = (t['admin_reply'] ?? t['reply'] ?? '').toString();
    final replyCtrl = TextEditingController(text: existingReply);
    String nextStatus = 'RESOLVED';

    showNexPayInspectorDrawer(
      context: context,
      title: 'Support Ticket #TK-$id',
      subtitle: '$name ($mobile) • $subject',
      child: StatefulBuilder(
        builder: (ctx, setDrawerState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CUSTOMER INQUIRY', style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Text(message, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5, height: 1.5)),
              ),
              const SizedBox(height: 20),
              const Text('OFFICIAL ADMIN RESPONSE', style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: replyCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write official resolution message for the customer...',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: nextStatus,
                decoration: const InputDecoration(labelText: 'Update Ticket Status'),
                items: const ['RESOLVED', 'OPEN', 'CLOSED']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDrawerState(() => nextStatus = v);
                },
              ),
            ],
          );
        },
      ),
      footerActions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final replyText = replyCtrl.text.trim();
            if (replyText.isEmpty) return;
            Navigator.pop(context);
            final ok = await admin.replyTicket(id, replyText, nextStatus);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Reply sent & ticket #TK-$id updated to $nextStatus.' : 'Failed to send reply.'),
                  backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed,
                ),
              );
            }
          },
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Send Official Reply'),
        ),
      ],
    );
  }
}