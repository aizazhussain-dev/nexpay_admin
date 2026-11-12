import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class MaintenanceUpdateCmsScreen extends StatefulWidget {
  const MaintenanceUpdateCmsScreen({super.key});

  @override
  State<MaintenanceUpdateCmsScreen> createState() =>
      _MaintenanceUpdateCmsScreenState();
}

class _MaintenanceUpdateCmsScreenState
    extends State<MaintenanceUpdateCmsScreen> {
  bool _maintEnabled = false;
  final _maintTitle =
  TextEditingController(text: 'Scheduled Core Banking Upgrade');
  final _maintMsg = TextEditingController(
      text:
      'NexPay systems are undergoing scheduled security maintenance. Services will resume shortly.');
  final _minVer = TextEditingController(text: '1.0.0');
  final _latestVer = TextEditingController(text: '1.2.0');
  final _downloadUrl =
  TextEditingController(text: 'https://smartvest.tech/nexpay-release.apk');
  final _changelog = TextEditingController(
      text: 'Performance improvements and biometric security enhancements.');
  bool _init = false;
  bool _saving = false;

  void _sync(AdminProvider admin) {
    final cfg = admin.cmsConfig;
    final m = (cfg['maintenanceShield'] is Map)
        ? Map<String, dynamic>.from(cfg['maintenanceShield'])
        : <String, dynamic>{};
    final v = (cfg['versionControl'] is Map)
        ? Map<String, dynamic>.from(cfg['versionControl'])
        : <String, dynamic>{};
    _maintEnabled = m['enabled'] == true ||
        (m['status'] ?? '').toString().toUpperCase() == 'ACTIVE';
    if ((m['title'] ?? '').toString().isNotEmpty) {
      _maintTitle.text = m['title'].toString();
    }
    if ((m['message'] ?? '').toString().isNotEmpty) {
      _maintMsg.text = m['message'].toString();
    }
    if ((v['minVersion'] ?? '').toString().isNotEmpty) {
      _minVer.text = v['minVersion'].toString();
    }
    if ((v['latestVersion'] ?? '').toString().isNotEmpty) {
      _latestVer.text = v['latestVersion'].toString();
    }
    if ((v['downloadUrl'] ?? '').toString().isNotEmpty) {
      _downloadUrl.text = v['downloadUrl'].toString();
    }
    if ((v['changelog'] ?? '').toString().isNotEmpty) {
      _changelog.text = v['changelog'].toString();
    }
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
              'Activate Emergency Maintenance Lock Screen',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _maintEnabled
                      ? AppConstants.dangerRed
                      : AppConstants.textPrimary),
            ),
            subtitle: Text(
              'Blocks customer logins and displays the maintenance advisory below.',
              style: TextStyle(color: AppConstants.textMuted, fontSize: 12.5),
            ),
            value: _maintEnabled,
            activeThumbColor: AppConstants.dangerRed,
            onChanged: (v) => setState(() => _maintEnabled = v),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _maintTitle,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: AppConstants.textPrimary),
              decoration:
              const InputDecoration(labelText: 'Maintenance Screen Title')),
          const SizedBox(height: 12),
          TextField(
              controller: _maintMsg,
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              style: TextStyle(color: AppConstants.textPrimary),
              decoration:
              const InputDecoration(labelText: 'Maintenance Notice Message')),
          Divider(height: 32, color: AppConstants.borderColor),
          Text('OTA VERSION GATEWAY & APK DISTRIBUTION',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.accentBlue)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _minVer,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Minimum Required App Version'))),
              const SizedBox(width: 14),
              Expanded(
                  child: TextField(
                      controller: _latestVer,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Latest Published Version'))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _downloadUrl,
              style: TextStyle(color: AppConstants.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Direct APK / Store Update URL')),
          const SizedBox(height: 12),
          TextField(
              controller: _changelog,
              maxLines: 2,
              style: TextStyle(color: AppConstants.textPrimary),
              decoration:
              const InputDecoration(labelText: 'Release Changelog Notes')),
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
                'MOBILE LOCK-SCREEN PREVIEW',
                style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6),
              ),
              NexPayStatusBadge(
                  status: _maintEnabled ? 'LOCKED' : 'OPERATIONAL'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _maintEnabled
                      ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                      : const Color(0xFF10B981).withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_maintEnabled
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981))
                        .withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _maintEnabled
                        ? Icons.construction_rounded
                        : Icons.verified_user_rounded,
                    color: _maintEnabled
                        ? const Color(0xFFF87171)
                        : const Color(0xFF34D399),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _maintTitle.text.trim().isEmpty
                      ? 'Scheduled Maintenance'
                      : _maintTitle.text.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _maintMsg.text.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 12, height: 1.45),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Min App v${_minVer.text.trim()}  •  Latest v${_latestVer.text.trim()}',
                    style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Emergency Maintenance Shield & OTA App Versioning',
        subtitle:
        'Control kill-switch maintenance mode and enforce mandatory customer app updates',
        badgeText: _maintEnabled
            ? 'MAINTENANCE LOCK ACTIVE'
            : 'SYSTEMS OPERATIONAL',
        badgeColor: _maintEnabled
            ? AppConstants.dangerRed
            : AppConstants.accentGreen,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.shield_rounded, size: 17),
            label: Text(_saving ? 'Deploying...' : 'Save & Deploy Controls'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Gateway Lock Status',
            value: _maintEnabled ? 'LOCKED' : 'LIVE ONLINE',
            sublabel: _maintEnabled
                ? 'Customer logins paused'
                : 'All client terminals active',
            icon: Icons.security_rounded,
            color: _maintEnabled
                ? AppConstants.dangerRed
                : AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Minimum App Version',
            value: 'v${_minVer.text.trim()}',
            sublabel: 'Older versions forced to update',
            icon: Icons.system_update_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Latest Release Build',
            value: 'v${_latestVer.text.trim()}',
            sublabel: 'Current production APK build',
            icon: Icons.new_releases_outlined,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'OTA Delivery Channel',
            value: 'Direct HTTPS',
            sublabel: 'smartvest.tech binary distribution',
            icon: Icons.cloud_download_outlined,
            color: AppConstants.accentGreen,
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
      title: _maintEnabled
          ? 'Activate Maintenance Lock?'
          : 'Deploy Version & Shield Controls',
      message: _maintEnabled
          ? 'Enabling the Emergency Maintenance Lock will immediately block customer logins across all mobile apps. Continue?'
          : 'Deploy updated OTA version requirements and maintenance shield config live?',
      confirmLabel: 'Deploy Live',
      confirmColor:
      _maintEnabled ? AppConstants.dangerRed : AppConstants.accentGreen,
      icon: Icons.shield_rounded,
    );
    if (!confirmed || !mounted) return;

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
        SnackBar(
            content: Text(ok
                ? 'Maintenance & version controls deployed!'
                : 'Deployment failed.'),
            backgroundColor:
            ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}