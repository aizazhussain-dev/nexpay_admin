import '../../widgets/institutional_scroll.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class CurrencyRatesTickerCmsScreen extends StatefulWidget {
  const CurrencyRatesTickerCmsScreen({super.key});

  @override
  State<CurrencyRatesTickerCmsScreen> createState() => _CurrencyRatesTickerCmsScreenState();
}

class _CurrencyRatesTickerCmsScreenState extends State<CurrencyRatesTickerCmsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  // Gold Spot Controllers
  late TextEditingController _goldGramController;
  late TextEditingController _goldSpreadController;

  // Forex Controllers (Buying & Selling)
  late TextEditingController _usdBuyController;
  late TextEditingController _usdSellController;
  late TextEditingController _sarBuyController;
  late TextEditingController _sarSellController;
  late TextEditingController _aedBuyController;
  late TextEditingController _aedSellController;
  late TextEditingController _gbpBuyController;
  late TextEditingController _gbpSellController;
  late TextEditingController _eurBuyController;
  late TextEditingController _eurSellController;

  String _tickerStatus = "ACTIVE"; // ACTIVE or DISABLED
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _goldGramController = TextEditingController();
    _goldSpreadController = TextEditingController();

    _usdBuyController = TextEditingController();
    _usdSellController = TextEditingController();
    _sarBuyController = TextEditingController();
    _sarSellController = TextEditingController();
    _aedBuyController = TextEditingController();
    _aedSellController = TextEditingController();
    _gbpBuyController = TextEditingController();
    _gbpSellController = TextEditingController();
    _eurBuyController = TextEditingController();
    _eurSellController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadRatesConfig();
      _isInitialized = true;
    }
  }

  void _loadRatesConfig() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    // Load Gold Spot Config
    final gold = (cfg['goldPricing'] is Map)
        ? Map<String, dynamic>.from(cfg['goldPricing'])
        : <String, dynamic>{};

    _goldGramController.text = (gold['perGramRate'] ?? 24500.0).toString();
    _goldSpreadController.text = (gold['spreadPercent'] ?? 1.5).toString();

    // Load Forex Config
    final forex = (cfg['forexRates'] is Map)
        ? Map<String, dynamic>.from(cfg['forexRates'])
        : <String, dynamic>{};

    _usdBuyController.text = (forex['usd_buy'] ?? 278.50).toString();
    _usdSellController.text = (forex['usd_sell'] ?? 280.50).toString();

    _sarBuyController.text = (forex['sar_buy'] ?? 74.20).toString();
    _sarSellController.text = (forex['sar_sell'] ?? 75.10).toString();

    _aedBuyController.text = (forex['aed_buy'] ?? 75.80).toString();
    _aedSellController.text = (forex['aed_sell'] ?? 76.60).toString();

    _gbpBuyController.text = (forex['gbp_buy'] ?? 354.00).toString();
    _gbpSellController.text = (forex['gbp_sell'] ?? 357.50).toString();

    _eurBuyController.text = (forex['eur_buy'] ?? 302.50).toString();
    _eurSellController.text = (forex['eur_sell'] ?? 305.80).toString();

    _tickerStatus = (cfg['tickerStatus'] ?? 'ACTIVE').toString().toUpperCase();
    if (_tickerStatus != "ACTIVE" && _tickerStatus != "DISABLED") {
      _tickerStatus = "ACTIVE";
    }
  }

  @override
  void dispose() {
    _goldGramController.dispose();
    _goldSpreadController.dispose();

    _usdBuyController.dispose();
    _usdSellController.dispose();
    _sarBuyController.dispose();
    _sarSellController.dispose();
    _aedBuyController.dispose();
    _aedSellController.dispose();
    _gbpBuyController.dispose();
    _gbpSellController.dispose();
    _eurBuyController.dispose();
    _eurSellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTickerLive = _tickerStatus == "ACTIVE";

    // Computed Gold Valuations
    final gramRate = double.tryParse(_goldGramController.text) ?? 24500.0;
    final tenGramsRate = gramRate * 10;
    final tolaRate = gramRate * 11.6638; // 1 Tola = 11.6638 grams

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
                          "Currency Exchange & Gold Spot Ticker CMS",
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
                            color: (isTickerLive ? AppConstants.accentGreen : AppConstants.dangerRed)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isTickerLive ? AppConstants.accentGreen : AppConstants.dangerRed)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isTickerLive ? "● TICKER STREAMING" : "○ TICKER PAUSED",
                            style: TextStyle(
                              color: isTickerLive ? AppConstants.accentGreen : AppConstants.dangerRed,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Configure 24K Pure Gold bullion gram/tola spot pricing and global Forex benchmarks for user terminal tickers",
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
                  _loadRatesConfig();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✓ Reloaded rates from server memory.")),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Reload Config", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
                "GOLD 24K (PER TOLA)",
                "₨ ${_currencyFormat.format(tolaRate)}",
                AppConstants.accentGold,
                isDesktop,
              ),
              _buildMetricCard(
                "USD / PKR SELLING",
                "₨ ${_usdSellController.text}",
                AppConstants.accentGreen,
                isDesktop,
              ),
              _buildMetricCard(
                "SAR / PKR BENCHMARK",
                "₨ ${_sarSellController.text}",
                AppConstants.accentBlue,
                isDesktop,
              ),
              _buildMetricCard(
                "BROKERAGE MARGIN",
                "+${_goldSpreadController.text}% Spread",
                Color(0xFFA855F7),
                isDesktop,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Live Ticker Bar Simulation Banner
          _buildLiveTickerPreviewBanner(gramRate, tolaRate, isTickerLive),

          const SizedBox(height: 24),

          // Main Editor Sections
          Expanded(
            child: InstitutionalVScroll(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Section 1: 24K Gold Spot Pricing Engine
                    _buildGoldPricingCard(gramRate, tenGramsRate, tolaRate),

                    const SizedBox(height: 20),

                    // Section 2: Global Forex Rates Grid
                    _buildForexGridCard(),

                    const SizedBox(height: 24),

                    // Save / Deploy Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSaving ? null : () => _saveRatesAndTicker(admin),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF021A13), strokeWidth: 2))
                            : const Icon(Icons.bolt_rounded, size: 20),
                        label: Text(
                          _isSaving ? "Deploying Ticker & Rates..." : "Save & Synchronize Rates Live Across All Terminals",
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

  // Live Scrolling Ticker Banner Simulation
  Widget _buildLiveTickerPreviewBanner(double gramRate, double tolaRate, bool isTickerLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTickerLive ? AppConstants.accentGreen.withValues(alpha: 0.3) : Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isTickerLive ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isTickerLive ? "LIVE TICKER" : "PAUSED",
              style: TextStyle(
                color: isTickerLive ? AppConstants.accentGreen : AppConstants.dangerRed,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InstitutionalHScroll(
              child: Row(
                children: [
                  _tickerItem("🥇 24K Gold (Gram)", "₨ ${_currencyFormat.format(gramRate)}"),
                  _tickerDivider(),
                  _tickerItem("👑 24K Gold (Tola)", "₨ ${_currencyFormat.format(tolaRate)}"),
                  _tickerDivider(),
                  _tickerItem("💵 USD", "₨ ${_usdSellController.text}"),
                  _tickerDivider(),
                  _tickerItem("🇸🇦 SAR", "₨ ${_sarSellController.text}"),
                  _tickerDivider(),
                  _tickerItem("🇦🇪 AED", "₨ ${_aedSellController.text}"),
                  _tickerDivider(),
                  _tickerItem("🇬🇧 GBP", "₨ ${_gbpSellController.text}"),
                  _tickerDivider(),
                  _tickerItem("🇪🇺 EUR", "₨ ${_eurSellController.text}"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tickerItem(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _tickerDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Text("•", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
    );
  }

  // Section 1: Gold Pricing Card
  Widget _buildGoldPricingCard(double gramRate, double tenGramsRate, double tolaRate) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.workspace_premium_rounded, color: AppConstants.accentGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "24K PHYSICAL GOLD SPOT PRICING ENGINE",
                    style: TextStyle(
                      color: AppConstants.accentGold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              // Ticker Mode Toggle
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
                      onTap: () => setState(() => _tickerStatus = "ACTIVE"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _tickerStatus == "ACTIVE" ? AppConstants.accentGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Ticker ON",
                          style: TextStyle(
                            color: _tickerStatus == "ACTIVE" ? Color(0xFF021A13) : AppConstants.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _tickerStatus = "DISABLED"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _tickerStatus == "DISABLED" ? AppConstants.dangerRed : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Ticker OFF",
                          style: TextStyle(
                            color: _tickerStatus == "DISABLED" ? Color(0xFF0F172A) : AppConstants.textMuted,
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gram Rate Input
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: _goldGramController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "24K PURE GOLD SPOT (PER GRAM PKR)",
                    labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                    hintText: "24500.00",
                    prefixText: "₨ ",
                    prefixStyle: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppConstants.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? "Enter valid per-gram gold rate" : null;
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Spread Margin Input
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _goldSpreadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "BROKER SPREAD / MARGIN (%)",
                    labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                    hintText: "1.5",
                    suffixText: "%",
                    suffixStyle: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppConstants.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n < 0) ? "Enter valid spread %" : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Derived Calculations Display Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDerivedTile("10 GRAMS 24K", "₨ ${_currencyFormat.format(tenGramsRate)}"),
                Container(width: 1, height: 36, color: Color(0xFFE2E8F0)),
                _buildDerivedTile("1 TOLA 24K (11.664g)", "₨ ${_currencyFormat.format(tolaRate)}"),
                Container(width: 1, height: 36, color: Color(0xFFE2E8F0)),
                _buildDerivedTile("BUY SPREAD (COMMISSION)", "₨ ${_currencyFormat.format(gramRate * (double.tryParse(_goldSpreadController.text) ?? 1.5) / 100)} / g"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDerivedTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  // Section 2: Global Forex Grid Card
  Widget _buildForexGridCard() {
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
          Row(
            children: const [
              Icon(Icons.currency_exchange_rounded, color: AppConstants.accentGreen, size: 22),
              SizedBox(width: 8),
              Text(
                "GLOBAL FOREX EXCHANGE BENCHMARKS (PKR)",
                style: TextStyle(
                  color: AppConstants.accentGreen,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // USD
          _buildForexRow(
            flag: "💵",
            code: "USD",
            name: "US Dollar",
            buyController: _usdBuyController,
            sellController: _usdSellController,
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 20),

          // SAR
          _buildForexRow(
            flag: "🇸🇦",
            code: "SAR",
            name: "Saudi Riyal",
            buyController: _sarBuyController,
            sellController: _sarSellController,
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 20),

          // AED
          _buildForexRow(
            flag: "🇦🇪",
            code: "AED",
            name: "UAE Dirham",
            buyController: _aedBuyController,
            sellController: _aedSellController,
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 20),

          // GBP
          _buildForexRow(
            flag: "🇬🇧",
            code: "GBP",
            name: "British Pound",
            buyController: _gbpBuyController,
            sellController: _gbpSellController,
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 20),

          // EUR
          _buildForexRow(
            flag: "🇪🇺",
            code: "EUR",
            name: "Euro",
            buyController: _eurBuyController,
            sellController: _eurSellController,
          ),
        ],
      ),
    );
  }

  Widget _buildForexRow({
    required String flag,
    required String code,
    required String name,
    required TextEditingController buyController,
    required TextEditingController sellController,
  }) {
    return Row(
      children: [
        // Currency Title
        SizedBox(
          width: 140,
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(name, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Buying Rate Field
        Expanded(
          child: TextFormField(
            controller: buyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: "BUYING RATE (PKR)",
              labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5),
              filled: true,
              fillColor: AppConstants.surfaceCard,
              prefixText: "₨ ",
              prefixStyle: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) => (double.tryParse(v ?? '') == null) ? "Invalid" : null,
          ),
        ),
        const SizedBox(width: 12),

        // Selling Rate Field
        Expanded(
          child: TextFormField(
            controller: sellController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: "SELLING RATE (PKR)",
              labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5),
              filled: true,
              fillColor: AppConstants.surfaceCard,
              prefixText: "₨ ",
              prefixStyle: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) => (double.tryParse(v ?? '') == null) ? "Invalid" : null,
          ),
        ),
      ],
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

  Future<void> _saveRatesAndTicker(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final goldPricing = {
      'perGramRate': double.tryParse(_goldGramController.text.trim()) ?? 24500.0,
      'spreadPercent': double.tryParse(_goldSpreadController.text.trim()) ?? 1.5,
    };

    final forexRates = {
      'usd_buy': double.tryParse(_usdBuyController.text.trim()) ?? 278.50,
      'usd_sell': double.tryParse(_usdSellController.text.trim()) ?? 280.50,
      'sar_buy': double.tryParse(_sarBuyController.text.trim()) ?? 74.20,
      'sar_sell': double.tryParse(_sarSellController.text.trim()) ?? 75.10,
      'aed_buy': double.tryParse(_aedBuyController.text.trim()) ?? 75.80,
      'aed_sell': double.tryParse(_aedSellController.text.trim()) ?? 76.60,
      'gbp_buy': double.tryParse(_gbpBuyController.text.trim()) ?? 354.00,
      'gbp_sell': double.tryParse(_gbpSellController.text.trim()) ?? 357.50,
      'eur_buy': double.tryParse(_eurBuyController.text.trim()) ?? 302.50,
      'eur_sell': double.tryParse(_eurSellController.text.trim()) ?? 305.80,
    };

    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'save_config'},
        data: {
          'goldPricing': goldPricing,
          'forexRates': forexRates,
          'tickerStatus': _tickerStatus,
        },
      );

      if (res.data['status'] == 'success') {
        await admin.fetchAllData();
        _loadRatesConfig();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppConstants.accentGreen,
              content: Text(
                "✓ Currency exchange rates & gold ticker synchronized live!",
                style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold),
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
          const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Network error while deploying rates.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
