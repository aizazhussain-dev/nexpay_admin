import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_image_picker.dart';
import '../../widgets/nexpay_ui_kit.dart';

class BroadcastCmsScreen extends StatefulWidget {
  const BroadcastCmsScreen({super.key});

  @override
  State<BroadcastCmsScreen> createState() => _BroadcastCmsScreenState();
}

class _BroadcastCmsScreenState extends State<BroadcastCmsScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _imageUrl = '';
  bool _isActive = true;
  bool _initialized = false;
  bool _saving = false;

  void _sync(AdminProvider admin) {
    final b = (admin.cmsConfig['broadcastNotice'] is Map)
        ? Map<String, dynamic>.from(admin.cmsConfig['broadcastNotice'])
        : <String, dynamic>{};
    _titleCtrl.text = (b['title'] ?? '').toString();
    _msgCtrl.text = (b['message'] ?? '').toString();
    _imageUrl = (b['imageUrl'] ?? '').toString();
    _isActive = (b['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';
    _initialized = true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!_initialized && admin.cmsConfig.isNotEmpty) _sync(admin);
    final isDesktop = MediaQuery.of(context).size.width >= 1050;

    final editorCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
                'Broadcast Visibility Status (Show Banner in Customer App)',
                style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w700)),
            value: _isActive,
            activeThumbColor: AppConstants.accentGreen,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const Divider(height: 28),
          NexPayImageUploader(
            label: 'Optional Broadcast Graphic / Flyer (Upload From Gallery)',
            initialValue: _imageUrl,
            previewHeight: 150,
            onChanged: (v) => setState(() => _imageUrl = v),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: AppConstants.textPrimary),
              decoration:
              const InputDecoration(labelText: 'Broadcast Headline Title')),
          const SizedBox(height: 14),
          TextField(
              controller: _msgCtrl,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              style: TextStyle(color: AppConstants.textPrimary),
              decoration:
              const InputDecoration(labelText: 'Announcement Body Message')),
        ],
      ),
    );

    final previewCard = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE IN-APP TERMINAL PREVIEW',
                style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6),
              ),
              NexPayStatusBadge(status: _isActive ? 'VISIBLE' : 'HIDDEN'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isActive
                    ? [const Color(0xFF065F46), const Color(0xFF0F172A)]
                    : [const Color(0xFF334155), const Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.45)
                      : const Color(0xFF475569)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: Color(0xFF34D399), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _titleCtrl.text.trim().isEmpty
                            ? 'Official NexPay Notice'
                            : _titleCtrl.text.trim(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _msgCtrl.text.trim().isEmpty
                      ? 'Your broadcast announcement message will appear here in real time.'
                      : _msgCtrl.text.trim(),
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Global Bank Broadcast & Emergency Alert Banner',
        subtitle:
        'Publish real-time announcements, SBP advisories, or promotional alert popups to all customer devices',
        badgeText: _isActive ? 'BROADCAST LIVE' : 'PAUSED',
        badgeColor:
        _isActive ? AppConstants.accentGreen : AppConstants.textMuted,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.campaign_rounded, size: 18),
            label: Text(
                _saving ? 'Broadcasting...' : 'Publish Broadcast Live'),
          ),
        ],
      ),
      body: isDesktop
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: editorCard),
          const SizedBox(width: 18),
          Expanded(flex: 2, child: previewCard),
        ],
      )
          : Column(
        children: [
          editorCard,
          const SizedBox(height: 16),
          previewCard,
        ],
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
    final confirmed = await showNexPayConfirmDialog(
      context: context,
      title: 'Publish Global Broadcast',
      message: _isActive
          ? 'Broadcast this notice live to all customer mobile terminals immediately?'
          : 'Save broadcast in PAUSED (hidden) state?',
      confirmLabel: 'Confirm & Publish',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final ok = await admin.saveCmsConfig({
      'broadcastNotice': {
        'title': _titleCtrl.text.trim(),
        'message': _msgCtrl.text.trim(),
        'imageUrl': _imageUrl,
        'status': _isActive ? 'ACTIVE' : 'INACTIVE',
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok
                ? 'Broadcast updated across all customer terminals!'
                : 'Broadcast save failed.'),
            backgroundColor:
            ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}