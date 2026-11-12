import '../../widgets/institutional_scroll.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class BroadcastCmsScreen extends StatefulWidget {
  const BroadcastCmsScreen({super.key});

  @override
  State<BroadcastCmsScreen> createState() => _BroadcastCmsScreenState();
}

class _BroadcastCmsScreenState extends State<BroadcastCmsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _messageController;

  String _status = "DISABLED"; // ACTIVE or DISABLED
  String _timestamp = "-";
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadBroadcastConfig();
      _isInitialized = true;
    }
  }

  void _loadBroadcastConfig() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;
    final bcast = (cfg['broadcastNotice'] is Map)
        ? Map<String, dynamic>.from(cfg['broadcastNotice'])
        : <String, dynamic>{};

    _titleController.text = (bcast['title'] ?? '').toString();
    _messageController.text = (bcast['message'] ?? '').toString();
    _status = (bcast['status'] ?? 'DISABLED').toString().toUpperCase();
    if (_status != "ACTIVE" && _status != "DISABLED") {
      _status = "DISABLED";
    }

    final rawTs = bcast['timestamp']?.toString() ?? '';
    if (rawTs.isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawTs);
        _timestamp = DateFormat("dd MMM yyyy, hh:mm a").format(parsed);
      } catch (_) {
        _timestamp = rawTs;
      }
    } else {
      _timestamp = "No broadcast published yet";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isActive = _status == "ACTIVE";

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
                        const Text(
                          "Bank Broadcast Notification CMS",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isActive ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isActive ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isActive ? "● BROADCAST LIVE" : "○ BROADCAST DISABLED",
                            style: TextStyle(
                              color: isActive ? AppConstants.accentGreen : AppConstants.dangerRed,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Publish system notices, regulatory alerts, and maintenance popups across all customer terminals",
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
                onPressed: () {
                  _loadBroadcastConfig();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✓ Reloaded broadcast settings from memory.")),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Reload Config", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Telemetry Metric Badges
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard(
                "BROADCAST STATUS",
                isActive ? "ACTIVE & LIVE" : "DISABLED",
                isActive ? AppConstants.accentGreen : AppConstants.dangerRed,
                isDesktop,
              ),
              _buildMetricCard("TARGET AUDIENCE", "All Active Terminals", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("LAST DEPLOYED", _timestamp, Color(0xFFA855F7), isDesktop),
              _buildMetricCard("CHANNEL VISIBILITY", "App Banner & Alert Dialog", Color(0xFF64748B), isDesktop),
            ],
          ),
          const SizedBox(height: 24),

          // Main Editor & Live Preview Body
          Expanded(
            child: InstitutionalVScroll(
              child: isDesktop ? _buildDesktopLayout(admin, isActive) : _buildMobileLayout(admin, isActive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AdminProvider admin, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Form
        Expanded(
          flex: 6,
          child: _buildFormCard(admin, isActive),
        ),
        const SizedBox(width: 20),
        // Right Column: Live Mobile Preview Card
        Expanded(
          flex: 4,
          child: _buildLivePreviewCard(isActive),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AdminProvider admin, bool isActive) {
    return Column(
      children: [
        _buildFormCard(admin, isActive),
        const SizedBox(height: 20),
        _buildLivePreviewCard(isActive),
      ],
    );
  }

  Widget _buildFormCard(AdminProvider admin, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "BROADCAST DISPATCH CONTROLLER",
                  style: TextStyle(
                    color: Color(0xFFA855F7),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                // Toggle Button for Active / Disabled
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _status = "ACTIVE"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? AppConstants.accentGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "LIVE (ON)",
                            style: TextStyle(
                              color: isActive ? Color(0xFF021A13) : AppConstants.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _status = "DISABLED"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: !isActive ? AppConstants.dangerRed : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "DISABLED (OFF)",
                            style: TextStyle(
                              color: !isActive ? Color(0xFF0F172A) : AppConstants.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title Field
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              decoration: InputDecoration(
                labelText: "BROADCAST ANNOUNCEMENT TITLE",
                labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                hintText: "e.g. Scheduled Core Banking Upgrade Notice",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: AppConstants.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (isActive && (v == null || v.trim().isEmpty)) {
                  return "Notice title is required when broadcast is Active";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message Field
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, height: 1.4),
              decoration: InputDecoration(
                labelText: "ANNOUNCEMENT BODY MESSAGE",
                labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                hintText: "Enter the detailed message displayed to customers across the application...",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: AppConstants.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (isActive && (v == null || v.trim().isEmpty)) {
                  return "Message body is required when broadcast is Active";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Guidance Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign_outlined, color: Color(0xFFA855F7), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Publishing an active broadcast will immediately surface this notice banner on customer dashboard cards and verification screens across Android, iOS, and Web terminals.",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 11.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save / Publish Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppConstants.accentGreen : AppConstants.surfaceCard,
                  foregroundColor: isActive ? Color(0xFF021A13) : Color(0xFF0F172A),
                  side: isActive ? null : const BorderSide(color: Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : () => _saveBroadcast(admin),
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2))
                    : Icon(isActive ? Icons.campaign_rounded : Icons.save_rounded, size: 20),
                label: Text(
                  _isSaving
                      ? "Deploying Announcement..."
                      : (isActive ? "Publish Bank Announcement Live" : "Save Changes (Notice Disabled)"),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Live Mobile Screen Preview Card
  Widget _buildLivePreviewCard(bool isActive) {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CUSTOMER APP PREVIEW",
                style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (isActive ? AppConstants.accentGreen : Color(0xFFE2E8F0)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? "VISIBLE" : "HIDDEN",
                  style: TextStyle(
                    color: isActive ? AppConstants.accentGreen : AppConstants.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Render simulated Mobile Notice Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [Color(0xFF1E1B4B), Color(0xFF0F172A)]
                    : [Color(0xFF1E293B).withValues(alpha: 0.5), Color(0xFF0F172A).withValues(alpha: 0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? Color(0xFFA855F7).withValues(alpha: 0.4) : Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFA855F7).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Color(0xFFA855F7), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : "Bank Announcement Title",
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message.isNotEmpty
                      ? message
                      : "The full broadcast announcement text will be formatted cleanly and rendered inside the user's dashboard view.",
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "NexPay Treasury Bulletin",
                      style: TextStyle(color: Color(0xFF0F172A).withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat("dd MMM, hh:mm a").format(DateTime.now()),
                      style: TextStyle(color: Color(0xFF0F172A).withValues(alpha: 0.4), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isActive
                ? "✓ This card is currently live across all active user terminals."
                : "○ Notice is disabled and hidden from customer applications.",
            style: TextStyle(
              color: isActive ? AppConstants.accentGreen : AppConstants.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
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
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _saveBroadcast(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'title': _titleController.text.trim(),
      'message': _messageController.text.trim(),
      'status': _status,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'save_config'},
        data: {
          'broadcastNotice': payload,
        },
      );

      if (res.data['status'] == 'success') {
        await admin.fetchAllData();
        _loadBroadcastConfig();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConstants.accentGreen,
              content: Text(
                _status == "ACTIVE" ? "✓ Bank Announcement broadcasted live!" : "✓ Broadcast disabled and hidden.",
                style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Save failed.")),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while deploying broadcast.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
