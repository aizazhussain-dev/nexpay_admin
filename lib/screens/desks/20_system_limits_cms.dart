import '../../widgets/institutional_scroll.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class SystemLimitsCmsScreen extends StatefulWidget {
  const SystemLimitsCmsScreen({super.key});

  @override
  State<SystemLimitsCmsScreen> createState() => _SystemLimitsCmsScreenState();
}

class _SystemLimitsCmsScreenState extends State<SystemLimitsCmsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  // Tier 1 Controllers
  late TextEditingController _t1DailyController;
  late TextEditingController _t1MonthlyController;
  late TextEditingController _t1YearlyController;

  // Tier 2 Controllers
  late TextEditingController _t2DailyController;
  late TextEditingController _t2MonthlyController;
  late TextEditingController _t2YearlyController;

  // Surcharges Controllers
  late TextEditingController _courierFeeController;
  late TextEditingController _bankFeeController;

  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _t1DailyController = TextEditingController();
    _t1MonthlyController = TextEditingController();
    _t1YearlyController = TextEditingController();

    _t2DailyController = TextEditingController();
    _t2MonthlyController = TextEditingController();
    _t2YearlyController = TextEditingController();

    _courierFeeController = TextEditingController();
    _bankFeeController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadLimitsConfig();
      _isInitialized = true;
    }
  }

  void _loadLimitsConfig() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;
    final lim = (cfg['limits'] is Map)
        ? Map<String, dynamic>.from(cfg['limits'])
        : <String, dynamic>{};

    _t1DailyController.text = (lim['tier1_daily'] ?? 20000).toString();
    _t1MonthlyController.text = (lim['tier1_monthly'] ?? 50000).toString();
    _t1YearlyController.text = (lim['tier1_yearly'] ?? 600000).toString();

    _t2DailyController.text = (lim['tier2_daily'] ?? 200000).toString();
    _t2MonthlyController.text = (lim['tier2_monthly'] ?? 1000000).toString();
    _t2YearlyController.text = (lim['tier2_yearly'] ?? 12000000).toString();

    _courierFeeController.text = (cfg['courierFee'] ?? 750).toString();
    _bankFeeController.text = (cfg['bankTransferFee'] ?? 0).toString();
  }

  void _restoreSbpDefaults() {
    setState(() {
      _t1DailyController.text = "20000";
      _t1MonthlyController.text = "50000";
      _t1YearlyController.text = "600000";

      _t2DailyController.text = "200000";
      _t2MonthlyController.text = "1000000";
      _t2YearlyController.text = "12000000";

      _courierFeeController.text = "750";
      _bankFeeController.text = "0";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✓ Restored State Bank standard regulatory defaults in fields."),
      ),
    );
  }

  @override
  void dispose() {
    _t1DailyController.dispose();
    _t1MonthlyController.dispose();
    _t1YearlyController.dispose();

    _t2DailyController.dispose();
    _t2MonthlyController.dispose();
    _t2YearlyController.dispose();

    _courierFeeController.dispose();
    _bankFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    final t1Monthly = double.tryParse(_t1MonthlyController.text) ?? 50000.0;
    final t2Monthly = double.tryParse(_t2MonthlyController.text) ?? 1000000.0;

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
                          "System Limits & Regulatory Quotas Manager",
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
                            color: AppConstants.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.accentGreen.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            "SBP COMPLIANT",
                            style: TextStyle(color: AppConstants.accentGreen, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Live spending velocity locks, biometric VIP allowances, and courier/interbank service fees",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.accentGold,
                      side: BorderSide(color: AppConstants.accentGold.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _restoreSbpDefaults,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text("Restore SBP Standards", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadLimitsConfig();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded limits from server memory.")),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text("Sync Memory", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Metric Cards
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("TIER-1 MONTHLY CAP", "₨ ${_currencyFormat.format(t1Monthly)}", Colors.amber, isDesktop),
              _buildMetricCard("TIER-2 VIP MONTHLY CAP", "₨ ${_currencyFormat.format(t2Monthly)}", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("GOLD COURIER FEE", "₨ ${_courierFeeController.text}", AppConstants.accentGold, isDesktop),
              _buildMetricCard("1LINK TRANSFER SURCHARGE", _bankFeeController.text == "0" ? "FREE (₨ 0)" : "₨ ${_bankFeeController.text}", AppConstants.accentBlue, isDesktop),
            ],
          ),
          const SizedBox(height: 24),

          // Main Limits Editor Form
          Expanded(
            child: InstitutionalVScroll(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Tier 1 and Tier 2 Side-by-Side or Stacked
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTier1Card()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTier2Card()),
                        ],
                      )
                    else ...[
                      _buildTier1Card(),
                      const SizedBox(height: 16),
                      _buildTier2Card(),
                    ],

                    const SizedBox(height: 16),

                    // Platform Charges & Surcharges Card
                    _buildChargesCard(),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSaving ? null : () => _saveLimits(admin),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF021A13), strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          _isSaving ? "Enforcing System Limits..." : "Save & Enforce System Limits Across All Terminals",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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

  // Tier 1 Card
  Widget _buildTier1Card() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "TIER-1 (BASIC ACCOUNTS)",
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
              const Text("Unverified / Basic", style: TextStyle(color: AppConstants.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Cap
          _buildNumericField(
            controller: _t1DailyController,
            label: "DAILY SPENDING CAP (PKR)",
            hint: "20000",
            min: 1000,
          ),
          const SizedBox(height: 14),

          // Monthly Cap
          _buildNumericField(
            controller: _t1MonthlyController,
            label: "MONTHLY SPENDING CAP (PKR)",
            hint: "50000",
            min: 5000,
          ),
          const SizedBox(height: 14),

          // Yearly Cap
          _buildNumericField(
            controller: _t1YearlyController,
            label: "YEARLY MAXIMUM QUOTA (PKR)",
            hint: "600000",
            min: 50000,
          ),
        ],
      ),
    );
  }

  // Tier 2 Card
  Widget _buildTier2Card() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "TIER-2 (BIOMETRIC / VIP)",
                  style: TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
              const Text("CNIC Biometric Verified", style: TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Cap
          _buildNumericField(
            controller: _t2DailyController,
            label: "DAILY SPENDING CAP (PKR)",
            hint: "200000",
            min: 10000,
          ),
          const SizedBox(height: 14),

          // Monthly Cap
          _buildNumericField(
            controller: _t2MonthlyController,
            label: "MONTHLY SPENDING CAP (PKR)",
            hint: "1000000",
            min: 50000,
          ),
          const SizedBox(height: 14),

          // Yearly Cap
          _buildNumericField(
            controller: _t2YearlyController,
            label: "YEARLY MAXIMUM QUOTA (PKR)",
            hint: "12000000",
            min: 500000,
          ),
        ],
      ),
    );
  }

  // Surcharges & Platform Fees Card
  Widget _buildChargesCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "💰 SURCHARGES & SERVICE HANDLING FEES",
            style: TextStyle(color: AppConstants.accentGold, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumericField(
                  controller: _courierFeeController,
                  label: "PHYSICAL GOLD COURIER FEE (PKR)",
                  hint: "750",
                  min: 0,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildNumericField(
                  controller: _bankFeeController,
                  label: "INTERBANK / 1LINK FEE (0 FOR FREE)",
                  hint: "0",
                  min: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double min,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: AppConstants.surfaceCard,
        prefixText: "₨ ",
        prefixStyle: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onChanged: (_) => setState(() {}),
      validator: (v) {
        final val = double.tryParse(v ?? '');
        if (val == null || val < min) {
          return "Value must be at least ₨ $min";
        }
        return null;
      },
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
          Text(value, style: TextStyle(color: color, fontSize: 16.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _saveLimits(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedLimits = {
      'tier1_daily': double.tryParse(_t1DailyController.text.trim()) ?? 20000.0,
      'tier1_monthly': double.tryParse(_t1MonthlyController.text.trim()) ?? 50000.0,
      'tier1_yearly': double.tryParse(_t1YearlyController.text.trim()) ?? 600000.0,
      'tier2_daily': double.tryParse(_t2DailyController.text.trim()) ?? 200000.0,
      'tier2_monthly': double.tryParse(_t2MonthlyController.text.trim()) ?? 1000000.0,
      'tier2_yearly': double.tryParse(_t2YearlyController.text.trim()) ?? 12000000.0,
    };

    final courierFee = double.tryParse(_courierFeeController.text.trim()) ?? 750.0;
    final bankFee = double.tryParse(_bankFeeController.text.trim()) ?? 0.0;

    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'save_config'},
        data: {
          'limits': updatedLimits,
          'courierFee': courierFee,
          'bankTransferFee': bankFee,
        },
      );

      if (res.data['status'] == 'success') {
        await admin.fetchAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConstants.accentGreen,
              content: Text(
                res.data['message'] ?? "✓ System limits & quotas successfully enforced!",
                style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConstants.dangerRed,
              content: Text(res.data['message'] ?? "Failed to update limits."),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppConstants.dangerRed,
            content: Text("Network error while deploying limits."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
