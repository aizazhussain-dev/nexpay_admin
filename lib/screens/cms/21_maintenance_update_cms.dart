import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class MaintenanceUpdateCmsScreen extends StatefulWidget {
  const MaintenanceUpdateCmsScreen({super.key});

  @override
  State<MaintenanceUpdateCmsScreen> createState() => _MaintenanceUpdateCmsScreenState();
}

class _MaintenanceUpdateCmsScreenState extends State<MaintenanceUpdateCmsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  // Maintenance Controllers
  late TextEditingController _maintTitleController;
  late TextEditingController _maintMsgController;

  // Version Control Controllers
  late TextEditingController _minVersionController;
  late TextEditingController _latestVersionController;
  late TextEditingController _downloadUrlController;
  late TextEditingController _changelogController;

  String _maintStatus = "DISABLED"; // ACTIVE (ON) or DISABLED (OFF)
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _maintTitleController = TextEditingController();
    _maintMsgController = TextEditingController();

    _minVersionController = TextEditingController();
    _latestVersionController = TextEditingController();
    _downloadUrlController = TextEditingController();
    _changelogController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadConfigFromProvider();
      _isInitialized = true;
    }
  }

  void _loadConfigFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    // Maintenance Shield Data
    final maint = (cfg['maintenanceShield'] is Map)
        ? Map<String, dynamic>.from(cfg['maintenanceShield'])
        : <String, dynamic>{};

    _maintStatus = (maint['status'] ?? 'DISABLED').toString().toUpperCase();
    if (_maintStatus != "ACTIVE" && _maintStatus != "DISABLED") {
      _maintStatus = "DISABLED";
    }

    _maintTitleController.text = (maint['title'] ?? 'System Upgrade in Progress').toString();
    _maintMsgController.text = (maint['message'] ??
        'NexPay core financial servers are undergoing routine maintenance. Regular operations will resume shortly.')
        .toString();

    // Version Control Data
    final ver = (cfg['versionControl'] is Map)
        ? Map<String, dynamic>.from(cfg['versionControl'])
        : <String, dynamic>{};

    _minVersionController.text = (ver['minVersion'] ?? '1.0.0').toString();
    _latestVersionController.text = (ver['latestVersion'] ?? '1.0.1').toString();
    _downloadUrlController.text =
        (ver['downloadUrl'] ?? 'https://smartvest.tech/nexpay-release.apk').toString();
    _changelogController.text = (ver['changelog'] ??
        'Security upgrades, speed improvements and bug fixes.')
        .toString();
  }

  @override
  void dispose() {
    _maintTitleController.dispose();
    _maintMsgController.dispose();

    _minVersionController.dispose();
    _latestVersionController.dispose();
    _downloadUrlController.dispose();
    _changelogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isShieldActive = _maintStatus == "ACTIVE";

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
                          "App Maintenance Shield & Force Update CMS",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isShieldActive ? AppConstants.dangerRed : AppConstants.accentGreen).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isShieldActive ? AppConstants.dangerRed : AppConstants.accentGreen).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isShieldActive ? "● SHIELD ACTIVE (APP LOCKED)" : "● LIVE & OPERATIONAL",
                            style: TextStyle(
                              color: isShieldActive ? AppConstants.dangerRed : AppConstants.accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Emergency core server lockdown switch and mandatory APK version upgrade enforcer",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: Color(0xFF021A13),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _loadConfigFromProvider();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✓ Reloaded settings from server memory.")),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Reload Config", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metric Badges
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard(
                "MAINTENANCE SHIELD",
                isShieldActive ? "ACTIVE (LOCKED)" : "OPERATIONAL (OFF)",
                isShieldActive ? AppConstants.dangerRed : AppConstants.accentGreen,
                isDesktop,
              ),
              _buildMetricCard("MIN SUPPORTED VERSION", "v${_minVersionController.text}", AppConstants.accentGold, isDesktop),
              _buildMetricCard("LATEST RELEASE VERSION", "v${_latestVersionController.text}", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("UPDATE PROTOCOL", "Mandatory Direct APK", Color(0xFF64748B), isDesktop),
            ],
          ),
          const SizedBox(height: 24),

          // Main Editor Sections
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 1. EMERGENCY MAINTENANCE SHIELD CARD
                    _buildMaintenanceSection(isShieldActive),

                    const SizedBox(height: 20),

                    // 2. VERSION CONTROL & FORCE APK UPDATE CARD
                    _buildVersionControlSection(),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isShieldActive ? AppConstants.dangerRed : AppConstants.accentGreen,
                          foregroundColor: isShieldActive ? Color(0xFF0F172A) : Color(0xFF021A13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSaving ? null : () => _saveMaintenanceAndVersion(admin),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2))
                            : const Icon(Icons.shield_rounded, size: 20),
                        label: Text(
                          _isSaving
                              ? "Deploying Configuration..."
                              : "Save & Deploy Maintenance / Version Settings Live",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section 1: Maintenance Shield
  Widget _buildMaintenanceSection(bool isShieldActive) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isShieldActive
            ? AppConstants.dangerRed.withValues(alpha: 0.05)
            : AppConstants.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isShieldActive
              ? AppConstants.dangerRed.withValues(alpha: 0.35)
              : Color(0xFFE2E8F0),
          width: isShieldActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: isShieldActive ? AppConstants.dangerRed : AppConstants.accentGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "SYSTEM MAINTENANCE MODE SWITCH",
                        style: TextStyle(
                          color: isShieldActive ? AppConstants.dangerRed : Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Active karne par tamaam customers ki app lock ho kar maintenance screen show karegi.",
                    style: TextStyle(color: AppConstants.textMuted, fontSize: 11),
                  ),
                ],
              ),

              // Quick Toggle Buttons
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
                      onTap: () => setState(() => _maintStatus = "DISABLED"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: !isShieldActive ? AppConstants.accentGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "🟢 OFF (Live App)",
                          style: TextStyle(
                            color: !isShieldActive ? Color(0xFF021A13) : AppConstants.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _maintStatus = "ACTIVE"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isShieldActive ? AppConstants.dangerRed : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "🔴 ON (Lock App)",
                          style: TextStyle(
                            color: isShieldActive ? Color(0xFF0F172A) : AppConstants.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
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

          // Maintenance Dialog Title
          TextFormField(
            controller: _maintTitleController,
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: "MAINTENANCE DIALOG TITLE",
              labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
              hintText: "e.g. Scheduled Core Banking Maintenance",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: AppConstants.surfaceCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) {
              if (isShieldActive && (v == null || v.trim().isEmpty)) {
                return "Title is required when maintenance shield is Active";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Maintenance Message Body
          TextFormField(
            controller: _maintMsgController,
            maxLines: 3,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, height: 1.4),
            decoration: InputDecoration(
              labelText: "MESSAGE DISPLAYED TO USERS",
              labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
              hintText: "Server infrastructure upgrade is in progress. Regular operations will resume shortly.",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: AppConstants.surfaceCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) {
              if (isShieldActive && (v == null || v.trim().isEmpty)) {
                return "Message is required when maintenance shield is Active";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Section 2: Version Control
  Widget _buildVersionControlSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.system_update_rounded, color: AppConstants.accentBlue, size: 20),
              SizedBox(width: 8),
              Text(
                "APP VERSION CONTROL & DIRECT APK LINK",
                style: TextStyle(
                  color: AppConstants.accentBlue,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Min Version Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _minVersionController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "MINIMUM SUPPORTED VERSION (FORCE TRIGGER)",
                        labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5),
                        hintText: "1.0.0",
                        filled: true,
                        fillColor: AppConstants.surfaceCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Min version required" : null,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Agar user ki app is se kam hui toh app band ho kar update mangegi.",
                      style: TextStyle(color: AppConstants.accentGold, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Latest Version Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _latestVersionController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "LATEST RELEASE VERSION",
                        labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5),
                        hintText: "1.0.1",
                        filled: true,
                        fillColor: AppConstants.surfaceCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Latest version required" : null,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Current production APK build tag.",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Download URL
          TextFormField(
            controller: _downloadUrlController,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: "DIRECT APK DOWNLOAD / STORE URL",
              labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
              hintText: "https://smartvest.tech/nexpay-release.apk",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: AppConstants.surfaceCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Download URL is required";
              if (!v.trim().startsWith("http")) return "Enter a valid URL starting with http:// or https://";
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Changelog
          TextFormField(
            controller: _changelogController,
            maxLines: 2,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5),
            decoration: InputDecoration(
              labelText: "UPDATE CHANGELOG / RELEASE NOTES (FOR USERS)",
              labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
              hintText: "Security upgrades, speed improvements and bug fixes.",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: AppConstants.surfaceCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Future<void> _saveMaintenanceAndVersion(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'maintenanceShield': {
        'status': _maintStatus,
        'enabled': (_maintStatus == 'ACTIVE'),
        'title': _maintTitleController.text.trim(),
        'message': _maintMsgController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      'versionControl': {
        'minVersion': _minVersionController.text.trim(),
        'latestVersion': _latestVersionController.text.trim(),
        'downloadUrl': _downloadUrlController.text.trim(),
        'changelog': _changelogController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    };

    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'save_maintenance_and_version'},
        data: payload,
      );

      if (res.data['status'] == 'success') {
        await admin.fetchAllData();
        _loadConfigFromProvider();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: _maintStatus == 'ACTIVE' ? AppConstants.dangerRed : AppConstants.accentGreen,
              content: Text(
                res.data['message'] ?? "✓ Maintenance & Version settings deployed live!",
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppConstants.dangerRed, content: Text(res.data['message'] ?? "Deployment failed.")),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while deploying settings.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
