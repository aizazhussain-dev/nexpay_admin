import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class ReferralsAffiliateCmsScreen extends StatefulWidget {
  const ReferralsAffiliateCmsScreen({super.key});

  @override
  State<ReferralsAffiliateCmsScreen> createState() => _ReferralsAffiliateCmsScreenState();
}

class _ReferralsAffiliateCmsScreenState extends State<ReferralsAffiliateCmsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  late TextEditingController _inviterRewardController;
  late TextEditingController _inviteeBonusController;
  late TextEditingController _minSpendController;
  late TextEditingController _campaignTitleController;
  late TextEditingController _campaignSubtitleController;

  String _programStatus = "ACTIVE"; // ACTIVE or DISABLED
  bool _autoCreditOnSpend = true;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _inviterRewardController = TextEditingController();
    _inviteeBonusController = TextEditingController();
    _minSpendController = TextEditingController();
    _campaignTitleController = TextEditingController();
    _campaignSubtitleController = TextEditingController();
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
    final ref = (cfg['referralProgram'] is Map)
        ? Map<String, dynamic>.from(cfg['referralProgram'])
        : <String, dynamic>{};

    _inviterRewardController.text = (ref['inviterReward'] ?? 250).toString();
    _inviteeBonusController.text = (ref['inviteeBonus'] ?? 100).toString();
    _minSpendController.text = (ref['minQualifyingSpend'] ?? 1000).toString();

    _campaignTitleController.text =
        (ref['campaignTitle'] ?? 'Invite Friends, Earn Real Cash!').toString();
    _campaignSubtitleController.text = (ref['campaignSubtitle'] ??
        'Share your referral link. When your friend signs up and spends ₨ 1,000, you both get instant cash in your wallet!')
        .toString();

    _programStatus = (ref['status'] ?? 'ACTIVE').toString().toUpperCase();
    if (_programStatus != "ACTIVE" && _programStatus != "DISABLED") {
      _programStatus = "ACTIVE";
    }

    _autoCreditOnSpend = (ref['autoCreditOnSpend'] ?? true) == true;
  }

  @override
  void dispose() {
    _inviterRewardController.dispose();
    _inviteeBonusController.dispose();
    _minSpendController.dispose();
    _campaignTitleController.dispose();
    _campaignSubtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isActive = _programStatus == "ACTIVE";

    final inviterReward = double.tryParse(_inviterRewardController.text) ?? 250.0;
    final inviteeBonus = double.tryParse(_inviteeBonusController.text) ?? 100.0;
    final minSpend = double.tryParse(_minSpendController.text) ?? 1000.0;

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
                          "Referral Rewards & Affiliate Program CMS",
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
                            color: (isActive ? AppConstants.accentGreen : AppConstants.dangerRed)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isActive ? AppConstants.accentGreen : AppConstants.dangerRed)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isActive ? "● REFERRAL PROGRAM LIVE" : "○ PROGRAM PAUSED",
                            style: TextStyle(
                              color: isActive ? AppConstants.accentGreen : AppConstants.dangerRed,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Configure dual referral rewards, fraud protection spending thresholds, and viral marketing copy",
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
                    const SnackBar(content: Text("✓ Reloaded referral parameters from memory.")),
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
                "INVITER CASH REWARD",
                "₨ ${_currencyFormat.format(inviterReward)}",
                AppConstants.accentGreen,
                isDesktop,
              ),
              _buildMetricCard(
                "NEW USER WELCOME",
                "₨ ${_currencyFormat.format(inviteeBonus)}",
                AppConstants.accentGold,
                isDesktop,
              ),
              _buildMetricCard(
                "MIN QUALIFYING SPEND",
                "₨ ${_currencyFormat.format(minSpend)}",
                AppConstants.accentBlue,
                isDesktop,
              ),
              _buildMetricCard(
                "SETTLEMENT TYPE",
                _autoCreditOnSpend ? "Instant Wallet Credit" : "Manual Review",
                Color(0xFFA855F7),
                isDesktop,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Editor & Preview Section
          Expanded(
            child: SingleChildScrollView(
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
        // Left Column: Configuration Form
        Expanded(
          flex: 6,
          child: _buildFormCard(admin, isActive),
        ),
        const SizedBox(width: 20),
        // Right Column: Live In-App Preview
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
        borderRadius: BorderRadius.circular(22),
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
                  "REWARD TIERS & FRAUD PREVENTION QUOTAS",
                  style: TextStyle(
                    color: AppConstants.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                // Toggle Button
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
                        onTap: () => setState(() => _programStatus = "ACTIVE"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? AppConstants.accentGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "ACTIVE (ON)",
                            style: TextStyle(
                              color: isActive ? Color(0xFF021A13) : AppConstants.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _programStatus = "DISABLED"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: !isActive ? AppConstants.dangerRed : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "PAUSED (OFF)",
                            style: TextStyle(
                              color: !isActive ? Color(0xFF0F172A) : AppConstants.textMuted,
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

            // Inviter & Invitee Rewards
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _inviterRewardController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "INVITER REWARD (PKR)",
                      labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                      hintText: "250",
                      prefixText: "₨ ",
                      prefixStyle: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: AppConstants.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n < 0) ? "Enter valid reward amount" : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _inviteeBonusController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "NEW USER WELCOME BONUS (PKR)",
                      labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                      hintText: "100",
                      prefixText: "₨ ",
                      prefixStyle: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: AppConstants.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n < 0) ? "Enter valid bonus amount" : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Minimum Qualifying Spend
            TextFormField(
              controller: _minSpendController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              decoration: InputDecoration(
                labelText: "MINIMUM QUALIFYING FIRST TRANSACTION / SPEND (PKR)",
                labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                hintText: "1000",
                prefixText: "₨ ",
                prefixStyle: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppConstants.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return (n == null || n < 0) ? "Enter valid qualifying spend" : null;
              },
            ),
            const SizedBox(height: 14),

            // Auto-Credit Switch Tile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppConstants.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Instant Wallet Auto-Credit on Target Spend",
                        style: TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Qualifying condition poori hote hi system khud dono wallets me cash credit karega.",
                        style: TextStyle(color: AppConstants.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  Switch(
                    value: _autoCreditOnSpend,
                    activeColor: AppConstants.accentGreen,
                    onChanged: (v) => setState(() => _autoCreditOnSpend = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Marketing Text Section
            const Text(
              "IN-APP CAMPAIGN TEXT & VIRAL COPY",
              style: TextStyle(
                color: Color(0xFFA855F7),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _campaignTitleController,
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13.5),
              decoration: InputDecoration(
                labelText: "BANNER TITLE",
                labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                hintText: "Invite Friends, Earn Real Cash!",
                filled: true,
                fillColor: AppConstants.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Campaign title required" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _campaignSubtitleController,
              maxLines: 3,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, height: 1.4),
              decoration: InputDecoration(
                labelText: "PROMO EXPLANATION & TERMS (FOR USERS)",
                labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                hintText: "Share your referral link with friends and family...",
                filled: true,
                fillColor: AppConstants.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Save / Deploy Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: Color(0xFF021A13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : () => _saveReferralProgram(admin),
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF021A13), strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _isSaving ? "Deploying Referral Program..." : "Save & Enforce Referral Program Live",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Live Mobile Preview Card
  Widget _buildLivePreviewCard(bool isActive) {
    final title = _campaignTitleController.text.trim();
    final subtitle = _campaignSubtitleController.text.trim();
    final inviterReward = double.tryParse(_inviterRewardController.text) ?? 250.0;
    final inviteeBonus = double.tryParse(_inviteeBonusController.text) ?? 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "USER IN-APP PREVIEW",
                style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (isActive ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? "VISIBLE" : "PAUSED",
                  style: TextStyle(
                    color: isActive ? AppConstants.accentGreen : AppConstants.dangerRed,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Simulated In-App Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [Color(0xFF064E3B), Color(0xFF022C22)]
                    : [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive ? AppConstants.accentGreen.withValues(alpha: 0.4) : Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.accentGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: AppConstants.accentGreen, size: 20),
                    ),
                    Text(
                      "Earn ₨ ${_currencyFormat.format(inviterReward)}",
                      style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title.isNotEmpty ? title : "Invite Friends & Family",
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle.isNotEmpty
                      ? subtitle
                      : "Share your referral code. Friend gets ₨ $inviteeBonus and you receive ₨ $inviterReward.",
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, height: 1.4),
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text("CODE: NEXPAY786", style: TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accentGreen,
                        foregroundColor: Color(0xFF021A13),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {},
                      child: const Text("Share Link", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isActive
                ? "✓ Program active: users can share links and claim wallet referral credits."
                : "○ Program paused: invite banners and reward distributions are temporarily locked.",
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
          Text(value, style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Future<void> _saveReferralProgram(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'inviterReward': double.tryParse(_inviterRewardController.text.trim()) ?? 250.0,
      'inviteeBonus': double.tryParse(_inviteeBonusController.text.trim()) ?? 100.0,
      'minQualifyingSpend': double.tryParse(_minSpendController.text.trim()) ?? 1000.0,
      'campaignTitle': _campaignTitleController.text.trim(),
      'campaignSubtitle': _campaignSubtitleController.text.trim(),
      'status': _programStatus,
      'autoCreditOnSpend': _autoCreditOnSpend,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'save_config'},
        data: {
          'referralProgram': payload,
        },
      );

      if (res.data['status'] == 'success') {
        await admin.fetchAllData();
        _loadConfigFromProvider();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConstants.accentGreen,
              content: Text(
                _programStatus == "ACTIVE"
                    ? "✓ Referral program updated and live across all apps!"
                    : "✓ Referral program paused.",
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
          const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while deploying referral settings.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
