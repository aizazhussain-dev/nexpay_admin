import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class BinanceGatewayCmsScreen extends StatefulWidget {
  const BinanceGatewayCmsScreen({super.key});

  @override
  State<BinanceGatewayCmsScreen> createState() => _BinanceGatewayCmsScreenState();
}

class _BinanceGatewayCmsScreenState extends State<BinanceGatewayCmsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _payIdController;
  late TextEditingController _trc20Controller;
  late TextEditingController _depRateController;
  late TextEditingController _wthRateController;

  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _payIdController = TextEditingController();
    _trc20Controller = TextEditingController();
    _depRateController = TextEditingController();
    _wthRateController = TextEditingController();
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
    final bSettings = (cfg['binanceSettings'] is Map)
        ? Map<String, dynamic>.from(cfg['binanceSettings'])
        : <String, dynamic>{};

    _payIdController.text = (bSettings['officialPayId'] ?? '281920381').toString();
    _trc20Controller.text = (bSettings['officialTrc20Address'] ?? 'TYD192aKms91kL891mNzq92Xz10A1').toString();
    _depRateController.text = (bSettings['depRate'] ?? 277.0).toString();
    _wthRateController.text = (bSettings['wthRate'] ?? 295.0).toString();
  }

  @override
  void dispose() {
    _payIdController.dispose();
    _trc20Controller.dispose();
    _depRateController.dispose();
    _wthRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    final depRate = double.tryParse(_depRateController.text) ?? 277.0;
    final wthRate = double.tryParse(_wthRateController.text) ?? 295.0;
    final spreadMargin = (wthRate - depRate).clamp(0.0, double.infinity);

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
                          "Binance Gateway & USDT Peg CMS",
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
                            color: Color(0xFFF3BA2F).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Color(0xFFF3BA2F).withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            "BINANCE PAY & TRC-20",
                            style: TextStyle(color: Color(0xFFF3BA2F), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Configure receiving Binance Pay ID, USDT TRC20 depository address, and buy/sell exchange rates",
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

          // Telemetry Badges
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("DEPOSIT RATE (PKR)", "₨ ${depRate.toStringAsFixed(2)}", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("WITHDRAWAL RATE (PKR)", "₨ ${wthRate.toStringAsFixed(2)}", Color(0xFFF3BA2F), isDesktop),
              _buildMetricCard("HOUSE SPREAD MARGIN", "₨ ${spreadMargin.toStringAsFixed(2)} / USDT", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("SETTLEMENT PROTOCOL", "TRC-20 / Binance Pay", Color(0xFF64748B), isDesktop),
            ],
          ),
          const SizedBox(height: 24),

          // Main Form Section
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 860 : double.infinity),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppConstants.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Depository Credentials
                      const Text(
                        "OFFICIAL CRYPTO RECEIVING DESTINATIONS",
                        style: TextStyle(color: Color(0xFFF3BA2F), fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 14),

                      // Binance Pay ID
                      TextFormField(
                        controller: _payIdController,
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: "OFFICIAL BINANCE PAY ID",
                          labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                          hintText: "e.g. 281920381",
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: AppConstants.surfaceCard,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppConstants.textMuted),
                            tooltip: "Copy Binance Pay ID",
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _payIdController.text.trim()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("✓ Copied Binance Pay ID to clipboard.")),
                              );
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Binance Pay ID is required" : null,
                      ),
                      const SizedBox(height: 14),

                      // USDT TRC-20 Address
                      TextFormField(
                        controller: _trc20Controller,
                        style: const TextStyle(color: Color(0xFF0F172A), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: "OFFICIAL USDT TRC-20 WALLET ADDRESS",
                          labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                          hintText: "e.g. TYD192aKms91kL891mNzq92Xz10A1",
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: AppConstants.surfaceCard,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppConstants.textMuted),
                            tooltip: "Copy TRC-20 Address",
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _trc20Controller.text.trim()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("✓ Copied TRC-20 Address to clipboard.")),
                              );
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "USDT TRC20 address is required";
                          if (!v.trim().startsWith("T") || v.trim().length < 26) {
                            return "Enter a valid TRC-20 address starting with 'T'";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Exchange Rates
                      const Text(
                        "SETTLEMENT PEG EXCHANGE RATES (PKR / USDT)",
                        style: TextStyle(color: AppConstants.accentGreen, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          // Deposit Rate
                          Expanded(
                            child: TextFormField(
                              controller: _depRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: "DEPOSIT RATE (BUYING FROM USER)",
                                labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                                hintText: "277.00",
                                filled: true,
                                fillColor: AppConstants.surfaceCard,
                                prefixText: "₨ ",
                                prefixStyle: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                return (n == null || n <= 0) ? "Enter valid deposit rate" : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Withdrawal Rate
                          Expanded(
                            child: TextFormField(
                              controller: _wthRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: "WITHDRAWAL RATE (SELLING TO USER)",
                                labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                                hintText: "295.00",
                                filled: true,
                                fillColor: AppConstants.surfaceCard,
                                prefixText: "₨ ",
                                prefixStyle: const TextStyle(color: Color(0xFFF3BA2F), fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                return (n == null || n <= 0) ? "Enter valid withdrawal rate" : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Spread & Compliance Notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFF3BA2F), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "P2P Gateway Execution Architecture",
                                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "When customers fund their NexPay wallet with USDT, they are instructed to transfer to the official TRC20 address or Pay ID configured above at ₨ ${depRate.toStringAsFixed(2)}/USDT. When cashing out to USDT, liquidity is settled at ₨ ${wthRate.toStringAsFixed(2)}/USDT. Net platform margin: ₨ ${spreadMargin.toStringAsFixed(2)} per USDT traded.",
                                    style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.accentGreen,
                            foregroundColor: Color(0xFF021A13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isSaving ? null : () => _saveBinanceSettings(admin),
                          icon: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF021A13), strokeWidth: 2))
                              : const Icon(Icons.save_rounded, size: 20),
                          label: Text(
                            _isSaving ? "Synchronizing Live Database..." : "Save & Enforce Binance Settings",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Future<void> _saveBinanceSettings(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedBinance = {
      'officialPayId': _payIdController.text.trim(),
      'officialTrc20Address': _trc20Controller.text.trim(),
      'depRate': double.tryParse(_depRateController.text.trim()) ?? 277.0,
      'wthRate': double.tryParse(_wthRateController.text.trim()) ?? 295.0,
    };

    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'save_config'},
        data: {
          'binanceSettings': updatedBinance,
        },
      );

      if (res.data['status'] == 'success') {
        await admin.fetchAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConstants.accentGreen,
              content: Text(
                res.data['message'] ?? "✓ Binance gateway parameters updated live!",
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
              content: Text(res.data['message'] ?? "Failed to update Binance configuration."),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppConstants.dangerRed,
            content: Text("Network error while deploying Binance settings."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
