import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class CurrencyRatesTickerCmsScreen extends StatefulWidget {
  const CurrencyRatesTickerCmsScreen({super.key});

  @override
  State<CurrencyRatesTickerCmsScreen> createState() =>
      _CurrencyRatesTickerCmsScreenState();
}

class _CurrencyRatesTickerCmsScreenState
    extends State<CurrencyRatesTickerCmsScreen> {
  final _goldGram = TextEditingController(text: '24500');
  final _goldSpread = TextEditingController(text: '1.5');
  final _usdBuy = TextEditingController(text: '278.5');
  final _usdSell = TextEditingController(text: '280.5');
  final _sarBuy = TextEditingController(text: '74.0');
  final _sarSell = TextEditingController(text: '74.8');
  final _aedBuy = TextEditingController(text: '75.5');
  final _aedSell = TextEditingController(text: '76.4');
  final _gbpBuy = TextEditingController(text: '354.0');
  final _gbpSell = TextEditingController(text: '358.0');
  final _eurBuy = TextEditingController(text: '301.0');
  final _eurSell = TextEditingController(text: '305.0');
  final NumberFormat _money = NumberFormat('#,##0', 'en_US');
  bool _tickerLive = true;
  bool _init = false;
  bool _saving = false;

  void _sync(AdminProvider admin) {
    final cfg = admin.cmsConfig;
    final g = (cfg['goldPricing'] is Map)
        ? Map<String, dynamic>.from(cfg['goldPricing'])
        : <String, dynamic>{};
    final f = (cfg['forexRates'] is Map)
        ? Map<String, dynamic>.from(cfg['forexRates'])
        : <String, dynamic>{};
    _goldGram.text = (g['perGramRate'] ?? 24500).toString();
    _goldSpread.text = (g['spreadPercent'] ?? 1.5).toString();
    _usdBuy.text = (f['usd_buy'] ?? 278.5).toString();
    _usdSell.text = (f['usd_sell'] ?? 280.5).toString();
    _sarBuy.text = (f['sar_buy'] ?? 74.0).toString();
    _sarSell.text = (f['sar_sell'] ?? 74.8).toString();
    _aedBuy.text = (f['aed_buy'] ?? 75.5).toString();
    _aedSell.text = (f['aed_sell'] ?? 76.4).toString();
    _gbpBuy.text = (f['gbp_buy'] ?? 354.0).toString();
    _gbpSell.text = (f['gbp_sell'] ?? 358.0).toString();
    _eurBuy.text = (f['eur_buy'] ?? 301.0).toString();
    _eurSell.text = (f['eur_sell'] ?? 305.0).toString();
    _tickerLive =
        (cfg['tickerStatus'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';
    _init = true;
  }

  @override
  void dispose() {
    _goldGram.dispose();
    _goldSpread.dispose();
    _usdBuy.dispose();
    _usdSell.dispose();
    _sarBuy.dispose();
    _sarSell.dispose();
    _aedBuy.dispose();
    _aedSell.dispose();
    _gbpBuy.dispose();
    _gbpSell.dispose();
    _eurBuy.dispose();
    _eurSell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!_init && admin.cmsConfig.isNotEmpty) _sync(admin);

    final goldRate = double.tryParse(_goldGram.text.trim()) ?? 24500;
    final spreadPct = double.tryParse(_goldSpread.text.trim()) ?? 1.5;
    final usdB = double.tryParse(_usdBuy.text.trim()) ?? 278.5;
    final usdS = double.tryParse(_usdSell.text.trim()) ?? 280.5;

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: '24K Bullion Spot Pricing & Live FX Ticker Engine',
        subtitle:
        'Set live per-gram 24K gold rates, buy/sell spread, and USD, SAR, AED, GBP, EUR interbank quotes',
        badgeText: _tickerLive ? 'TICKER STREAMING' : 'PAUSED',
        badgeColor: AppConstants.accentGold,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.bolt_rounded, size: 17),
            label: Text(_saving ? 'Broadcasting...' : 'Broadcast Live Rates'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: '24K Gold Spot (1g)',
            value: 'Rs. ${_money.format(goldRate)}',
            sublabel: '1 Tola (11.664g): Rs. ${_money.format(goldRate * 11.664)}',
            icon: Icons.diamond_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Bullion Spread Margin',
            value: '${spreadPct.toStringAsFixed(2)}%',
            sublabel: 'Buy/Sell execution spread',
            icon: Icons.percent_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'USD / PKR Desk Quote',
            value: '${usdB.toStringAsFixed(1)} / ${usdS.toStringAsFixed(1)}',
            sublabel: 'Interbank Buy / Sell PKR',
            icon: Icons.currency_exchange_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Home Ticker Ribbon',
            value: _tickerLive ? 'STREAMING' : 'PAUSED',
            sublabel: '5 global currencies + 24K Gold',
            icon: Icons.stream_rounded,
            color: _tickerLive
                ? AppConstants.accentGreen
                : AppConstants.textMuted,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Ticker Ribbon Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.bgDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.sensors_rounded,
                      color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE TICKER PREVIEW:',
                    style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 14),
                  _tickerChip(
                      '24K GOLD', 'Rs. ${_money.format(goldRate)}/g', const Color(0xFFFBBF24)),
                  _tickerChip('USD', 'Rs. ${_usdSell.text}', const Color(0xFF34D399)),
                  _tickerChip('SAR', 'Rs. ${_sarSell.text}', const Color(0xFF60A5FA)),
                  _tickerChip('AED', 'Rs. ${_aedSell.text}', const Color(0xFF60A5FA)),
                  _tickerChip('GBP', 'Rs. ${_gbpSell.text}', const Color(0xFF34D399)),
                  _tickerChip('EUR', 'Rs. ${_eurSell.text}', const Color(0xFF34D399)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
                      'Live Market Ticker Bar Enabled in Customer Home',
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w700)),
                  value: _tickerLive,
                  activeThumbColor: AppConstants.accentGreen,
                  onChanged: (v) => setState(() => _tickerLive = v),
                ),
                Divider(height: 24, color: AppConstants.borderColor),
                Text('24K PURE GOLD SPOT PRICING',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.accentGold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: _goldGram,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppConstants.textPrimary),
                            decoration: const InputDecoration(
                                labelText: '24K Gold Per Gram Rate (PKR)',
                                prefixText: 'Rs. '))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: TextField(
                            controller: _goldSpread,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppConstants.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Buy/Sell Spread (%)',
                                suffixText: '%'))),
                  ],
                ),
                const SizedBox(height: 24),
                Text('INTERBANK FOREIGN EXCHANGE RATES (PKR)',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.accentBlue)),
                const SizedBox(height: 12),
                _fxRow('US Dollar (USD)', _usdBuy, _usdSell),
                _fxRow('Saudi Riyal (SAR)', _sarBuy, _sarSell),
                _fxRow('UAE Dirham (AED)', _aedBuy, _aedSell),
                _fxRow('British Pound (GBP)', _gbpBuy, _gbpSell),
                _fxRow('Euro (EUR)', _eurBuy, _eurSell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tickerChip(String code, String val, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$code: ',
              style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          Text(val,
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _fxRow(
      String label, TextEditingController buy, TextEditingController sell) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 180,
              child: Text(label,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13))),
          Expanded(
              child: TextField(
                  controller: buy,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppConstants.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Buy Rate (PKR)', prefixText: 'Rs. '))),
          const SizedBox(width: 14),
          Expanded(
              child: TextField(
                  controller: sell,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppConstants.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Sell Rate (PKR)', prefixText: 'Rs. '))),
        ],
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
    final confirmed = await showNexPayConfirmDialog(
      context: context,
      title: 'Broadcast Live Gold & FX Rates',
      message:
      'Publish updated 24K gold spot pricing and foreign exchange rates across all customer terminals?',
      confirmLabel: 'Broadcast Live',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final ok = await admin.saveCmsConfig({
      'goldPricing': {
        'perGramRate': double.tryParse(_goldGram.text.trim()) ?? 24500,
        'spreadPercent': double.tryParse(_goldSpread.text.trim()) ?? 1.5,
      },
      'forexRates': {
        'usd_buy': double.tryParse(_usdBuy.text.trim()) ?? 278.5,
        'usd_sell': double.tryParse(_usdSell.text.trim()) ?? 280.5,
        'sar_buy': double.tryParse(_sarBuy.text.trim()) ?? 74.0,
        'sar_sell': double.tryParse(_sarSell.text.trim()) ?? 74.8,
        'aed_buy': double.tryParse(_aedBuy.text.trim()) ?? 75.5,
        'aed_sell': double.tryParse(_aedSell.text.trim()) ?? 76.4,
        'gbp_buy': double.tryParse(_gbpBuy.text.trim()) ?? 354.0,
        'gbp_sell': double.tryParse(_gbpSell.text.trim()) ?? 358.0,
        'eur_buy': double.tryParse(_eurBuy.text.trim()) ?? 301.0,
        'eur_sell': double.tryParse(_eurSell.text.trim()) ?? 305.0,
      },
      'tickerStatus': _tickerLive ? 'ACTIVE' : 'DISABLED',
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok
                ? 'Live gold & FX ticker rates published!'
                : 'Save failed.'),
            backgroundColor:
            ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}