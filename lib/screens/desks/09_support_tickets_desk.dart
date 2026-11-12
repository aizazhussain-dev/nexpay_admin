import '../../widgets/institutional_scroll.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class SupportTicketsDeskScreen extends StatefulWidget {
  const SupportTicketsDeskScreen({super.key});

  @override
  State<SupportTicketsDeskScreen> createState() => _SupportTicketsDeskScreenState();
}

class _SupportTicketsDeskScreenState extends State<SupportTicketsDeskScreen> {
  final ApiClient _api = ApiClient();
  String _searchQuery = "";
  String _statusFilter = "ALL"; // ALL, OPEN, RESOLVED
  bool _isReplying = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final tickets = admin.tickets;

    // Filter Logic
    final filteredList = tickets.where((t) {
      final status = (t['status'] ?? 'OPEN').toString().toUpperCase();
      if (_statusFilter == "OPEN" && status != "OPEN") return false;
      if (_statusFilter == "RESOLVED" && status != "RESOLVED") return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (t['user_mobile'] ?? '').toString().toLowerCase();
        final name = (t['user_name'] ?? '').toString().toLowerCase();
        final sub = (t['subject'] ?? '').toString().toLowerCase();
        final msg = (t['message'] ?? '').toString().toLowerCase();
        final reply = (t['admin_reply'] ?? '').toString().toLowerCase();
        final id = (t['id'] ?? '').toString();
        return mob.contains(q) || name.contains(q) || sub.contains(q) || msg.contains(q) || reply.contains(q) || id.contains(q);
      }
      return true;
    }).toList();

    // Operational Counters
    int openCount = 0;
    int resolvedCount = 0;

    for (var t in tickets) {
      final s = (t['status'] ?? 'OPEN').toString().toUpperCase();
      if (s == 'OPEN') {
        openCount++;
      } else if (s == 'RESOLVED') {
        resolvedCount++;
      }
    }

    final resolutionRate = tickets.isNotEmpty ? ((resolvedCount / tickets.length) * 100).toStringAsFixed(1) : "100.0";

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
                          "Customer Support & Helpdesk Console",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (openCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.dangerRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              "$openCount OPEN INQUIRIES",
                              style: const TextStyle(color: AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Review customer inquiries, technical disputes, and dispatch official NexPay resolutions",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => admin.fetchAllData(),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metric Badges
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("OPEN INQUIRIES", "$openCount Tickets", openCount > 0 ? AppConstants.dangerRed : AppConstants.accentGreen, isDesktop),
              _buildMetricCard("RESOLVED TICKETS", "$resolvedCount Tickets", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("TOTAL INQUIRIES", "${tickets.length} Logged", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("RESOLUTION RATE", "$resolutionRate%", AppConstants.accentGold, isDesktop),
            ],
          ),
          const SizedBox(height: 20),

          // Search & Filter Controls
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
                    hintText: "Search Mobile, Name, Subject, Query...",
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
              _buildFilterChip("ALL", "All Tickets (${tickets.length})"),
              _buildFilterChip("OPEN", "Open / Action Required ($openCount)"),
              _buildFilterChip("RESOLVED", "Resolved ($resolvedCount)"),
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
                  Icon(Icons.headset_mic_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No support tickets found matching criteria",
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
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
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
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppConstants.accentGreen : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _statusFilter = key),
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
        child: InstitutionalVScroll(
          scrollDirection: Axis.vertical,
          child: InstitutionalHScroll(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text("TICKET ID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("SUBJECT / CATEGORY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("INQUIRY MESSAGE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("OFFICIAL RESPONSE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                DataColumn(label: Text("ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
              rows: list.map((t) {
                final status = (t['status'] ?? 'OPEN').toString().toUpperCase();
                final isOpen = status == 'OPEN';
                final id = t['id'].toString();
                final mobile = (t['user_mobile'] ?? '').toString();
                final name = (t['user_name'] ?? 'Customer').toString();
                final sub = (t['subject'] ?? 'Inquiry').toString();
                final msg = (t['message'] ?? '-').toString();
                final reply = (t['admin_reply'] ?? '').toString();

                return DataRow(
                  cells: [
                    DataCell(Text("#$id", style: const TextStyle(color: AppConstants.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(mobile, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0xFFA855F7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFA855F7).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          sub,
                          style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w800, fontSize: 11.5),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ),
                    ),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          reply.isNotEmpty ? reply : "No official reply dispatched yet",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: reply.isNotEmpty ? AppConstants.accentGreen : AppConstants.textMuted,
                            fontSize: 11.5,
                            fontStyle: reply.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOpen ? AppConstants.accentGreen : AppConstants.surfaceCard,
                          foregroundColor: isOpen ? Color(0xFF021A13) : Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isReplying ? null : () => _openReplyDialog(context, t, admin),
                        icon: Icon(isOpen ? Icons.reply_rounded : Icons.edit_note_rounded, size: 14),
                        label: Text(
                          isOpen ? "Reply & Resolve" : "Update Reply",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
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

  Widget _buildMobileCards(List<dynamic> list, AdminProvider admin) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final t = list[idx];
        final status = (t['status'] ?? 'OPEN').toString().toUpperCase();
        final isOpen = status == 'OPEN';
        final id = t['id'].toString();
        final mobile = (t['user_mobile'] ?? '').toString();
        final name = (t['user_name'] ?? 'Customer').toString();
        final sub = (t['subject'] ?? 'Inquiry').toString();
        final msg = (t['message'] ?? '-').toString();
        final reply = (t['admin_reply'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isOpen ? Colors.amber.withValues(alpha: 0.3) : Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("#$id", style: const TextStyle(color: AppConstants.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFA855F7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(sub, style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              Text(msg, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, height: 1.4)),
              if (reply.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.support_agent_rounded, size: 16, color: AppConstants.accentGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reply,
                          style: const TextStyle(color: AppConstants.accentGreen, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(color: Color(0xFFE2E8F0), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Customer: $name ($mobile)", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppConstants.accentGreen, padding: EdgeInsets.zero),
                    onPressed: _isReplying ? null : () => _openReplyDialog(context, t, admin),
                    icon: Icon(isOpen ? Icons.reply_rounded : Icons.edit_note_rounded, size: 16),
                    label: Text(isOpen ? "Reply & Resolve" : "Update Response", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final isOpen = status == 'OPEN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isOpen ? Colors.amber : AppConstants.accentGreen).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOpen ? "OPEN INQUIRY" : "RESOLVED",
        style: TextStyle(
          color: isOpen ? Colors.amber : AppConstants.accentGreen,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Reply Dispatcher Modal Dialog
  void _openReplyDialog(BuildContext context, dynamic ticket, AdminProvider admin) {
    final id = int.tryParse(ticket['id']?.toString() ?? '0') ?? 0;
    final name = (ticket['user_name'] ?? 'Customer').toString();
    final mobile = (ticket['user_mobile'] ?? '').toString();
    final sub = (ticket['subject'] ?? 'Inquiry').toString();
    final msg = (ticket['message'] ?? '').toString();
    final currentReply = (ticket['admin_reply'] ?? '').toString();

    final replyController = TextEditingController(text: currentReply);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
        title: Row(
          children: [
            const Icon(Icons.headset_mic_rounded, color: AppConstants.accentGreen),
            const SizedBox(width: 8),
            Text("Dispatch Support Resolution #$id", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Customer: $name ($mobile)", style: const TextStyle(color: AppConstants.accentBlue, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text("Subject: $sub", style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Text(
                  msg,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, height: 1.35),
                ),
              ),
              const SizedBox(height: 16),
              const Text("OFFICIAL NEXPAY RESOLUTION REPLY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: replyController,
                maxLines: 4,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Enter official response to dispatch to customer...",
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: AppConstants.surfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final replyText = replyController.text.trim();
              if (replyText.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isReplying = true);

              try {
                final res = await _api.dio.post(
                  '',
                  queryParameters: {'action': 'reply_ticket'},
                  data: {
                    'ticketId': id,
                    'reply': replyText,
                    'status': 'RESOLVED',
                  },
                );

                if (res.data['status'] == 'success') {
                  await admin.fetchAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppConstants.accentGreen,
                        content: Text("✓ Response dispatched & Ticket #$id resolved!", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Failed to save reply.")),
                    );
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while replying to ticket.")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isReplying = false);
              }
            },
            child: const Text("Send Reply & Resolve Ticket", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
