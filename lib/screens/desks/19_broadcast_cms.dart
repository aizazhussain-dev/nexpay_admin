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

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Global Bank Broadcast & Emergency Alert Banner',
        subtitle: 'Publish real-time announcements, SBP advisories, or promotional alert popups to all customer devices',
        badgeText: _isActive ? 'BROADCAST LIVE' : 'PAUSED',
        badgeColor: _isActive ? AppConstants.accentGreen : AppConstants.textMuted,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.campaign_rounded, size: 18),
            label: Text(_saving ? 'Broadcasting...' : 'Publish Broadcast Live'),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Broadcast Visibility Status (Show Banner in Customer App)', style: TextStyle(fontWeight: FontWeight.w700)),
              value: _isActive,
              activeThumbColor: AppConstants.accentGreen,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const Divider(height: 28),
            NexPayImageUploader(
              label: 'Optional Broadcast Graphic / Flyer (Upload From Gallery)',
              initialValue: _imageUrl,
              previewHeight: 150,
              onChanged: (v) => _imageUrl = v,
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Broadcast Headline Title')),
            const SizedBox(height: 14),
            TextField(controller: _msgCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Announcement Body Message')),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
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
        SnackBar(content: Text(ok ? 'Broadcast updated across all customer terminals!' : 'Broadcast save failed.'), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}