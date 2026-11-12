import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class MaintenanceUpdateCmsScreen extends StatefulWidget {
  const MaintenanceUpdateCmsScreen({super.key});

  @override
  State<MaintenanceUpdateCmsScreen> createState() => _MaintenanceUpdateCmsScreenState();
}

class _MaintenanceUpdateCmsScreenState extends State<MaintenanceUpdateCmsScreen> {
  bool _maintEnabled = false;
  final _maintTitle = TextEditingController(text: 'Scheduled Core Banking Upgrade');
  final _maintMsg = TextEditingController(text: 'NexPay systems are undergoing scheduled security maintenance. Services will resume shortly.');
  final _minVer = TextEditingController(text: '1.0.0');
  final _latestVer = TextEditingController(text: '1.2.0');
  final _downloadUrl = TextEditingController(text: 'https://smartvest.tech/nexpay-release.apk');
  final _changelog = TextEditingController(text: 'Performance improvements and biometric security enhancements.');
  bool _init = false;
  bool _saving = false;

  void _sync(AdminProvider admin) {
    final cfg = admin.cmsConfig;
    final m = (cfg['maintenanceShield'] is Map) ? Map<String, dynamic>.from(cfg['maintenanceShield']) : <String, dynamic>{};
    final v = (cfg['versionControl'] is Map) ? Map<String, dynamic>.from(cfg['versionControl']) : <String, dynamic>{};
    _maintEnabled = m['enabled'] == true || (m['status'] ?? '').toString().toUpperCase() == 'ACTIVE';
    if ((m['title'] ?? '').toString().isNotEmpty) _maintTitle.text = m['title'].toString();
    if ((m['message'] ?? '').toString().isNotEmpty) _maintMsg.text = m['message'].toString();
    if ((v['minVersion'] ?? '').toString().isNotEmpty) _minVer.text = v['minVersion'].toString();
    if ((v['latestVersion'] ?? '').toString().isNotEmpty) _latestVer.text = v['latestVersion'].toString();
    if ((v['downloadUrl'] ?? '').toString().isNotEmpty) _downloadUrl.text = v['downloadUrl'].toString();
    if ((v['changelog'] ?? '').toString().isNotEmpty) _changelog.text = v['changelog'].toString();
    _init = true;
  }

  @override
  void dispose() {
    _maintTitle.dispose();
    _maintMsg.dispose();
    _minVer.dispose();
    _latestVer.dispose();
    _downloadUrl.dispose();
    _changelog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!_init && admin.cmsConfig.isNotEmpty) _sync(admin);

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Emergency Maintenance Shield & OTA App Versioning',
        subtitle: 'Control kill-switch maintenance mode and enforce mandatory customer app updates',
        badgeText: _maintEnabled ? 'MAINTENANCE LOCK ACTIVE' : 'SYSTEMS OPERATIONAL',
        badgeColor: _maintEnabled ? AppConstants.dangerRed : AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.shield_rounded, size: 17),
            label: Text(_saving ? 'Deploying...' : 'Save & Deploy Controls'),
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
              title: const Text('Activate Emergency Maintenance Lock Screen', style: TextStyle(fontWeight: FontWeight.w700, color: AppConstants.dangerRed)),
              subtitle: const Text('Blocks customer logins and displays the maintenance advisory below.'),
              value: _maintEnabled,
              activeThumbColor: AppConstants.dangerRed,
              onChanged: (v) => setState(() => _maintEnabled = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _maintTitle, decoration: const InputDecoration(labelText: 'Maintenance Screen Title')),
            const SizedBox(height: 12),
            TextField(controller: _maintMsg, maxLines: 2, decoration: const InputDecoration(labelText: 'Maintenance Notice Message')),
            const Divider(height: 32),
            const Text('OTA VERSION GATEWAY & APK DISTRIBUTION', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppConstants.accentBlue)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _minVer, decoration: const InputDecoration(labelText: 'Minimum Required App Version'))),
                const SizedBox(width: 14),
                Expanded(child: TextField(controller: _latestVer, decoration: const InputDecoration(labelText: 'Latest Published Version'))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _downloadUrl, decoration: const InputDecoration(labelText: 'Direct APK / Store Update URL')),
            const SizedBox(height: 12),
            TextField(controller: _changelog, maxLines: 2, decoration: const InputDecoration(labelText: 'Release Changelog Notes')),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
    setState(() => _saving = true);
    final ok = await admin.saveCmsConfig({
      'maintenanceShield': {
        'enabled': _maintEnabled,
        'status': _maintEnabled ? 'ACTIVE' : 'INACTIVE',
        'title': _maintTitle.text.trim(),
        'message': _maintMsg.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      'versionControl': {
        'minVersion': _minVer.text.trim(),
        'latestVersion': _latestVer.text.trim(),
        'downloadUrl': _downloadUrl.text.trim(),
        'changelog': _changelog.text.trim(),
      },
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Maintenance & version controls deployed!' : 'Deployment failed.'), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}