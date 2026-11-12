import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class CurrencyRatesTickerCmsScreen extends StatefulWidget {
  const CurrencyRatesTickerCmsScreen({super.key});

  @override
  State<CurrencyRatesTickerCmsScreen> createState() => _CurrencyRatesTickerCmsScreenState();
}

class _CurrencyRatesTickerCmsScreenState extends State<CurrencyRatesTickerCmsScreen> {
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
  bool _tickerLive = true;
  bool _init = false;
  bool _saving = false;

  void _sync(AdminProvider admin) {
    final cfg = admin.cmsConfig;
    final g = (cfg['goldPricing'] is Map) ? Map<String, dynamic>.from(cfg['goldPricing']) : <String, dynamic>{};
    final f = (cfg['forexRates'] is Map) ? Map<String, dynamic>.from(cfg['forexRates']) : <String, dynamic>{};
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
    _tickerLive = (cfg['tickerStatus'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';
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

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: '24K Bullion Spot Pricing & Live FX Ticker Engine',
        subtitle: 'Set live per-gram 24K gold rates, buy/sell spread, and USD, SAR, AED, GBP, EUR interbank quotes',
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
              title: const Text('Live Market Ticker Bar Enabled in Customer Home', style: TextStyle(fontWeight: FontWeight.w700)),
              value: _tickerLive,
              activeThumbColor: AppConstants.accentGreen,
              onChanged: (v) => setState(() => _tickerLive = v),
            ),
            const Divider(height: 24),
            const Text('24K PURE GOLD SPOT PRICING', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppConstants.accentGold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _goldGram, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '24K Gold Per Gram Rate (PKR)', prefixText: 'Rs. '))),
                const SizedBox(width: 14),
                Expanded(child: TextField(controller: _goldSpread, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buy/Sell Spread (%)', suffixText: '%'))),
              ],
            ),
            const SizedBox(height: 24),
            const Text('INTERBANK FOREIGN EXCHANGE RATES (PKR)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppConstants.accentBlue)),
            const SizedBox(height: 12),
            _fxRow('US Dollar (USD)', _usdBuy, _usdSell),
            _fxRow('Saudi Riyal (SAR)', _sarBuy, _sarSell),
            _fxRow('UAE Dirham (AED)', _aedBuy, _aedSell),
            _fxRow('British Pound (GBP)', _gbpBuy, _gbpSell),
            _fxRow('Euro (EUR)', _eurBuy, _eurSell),
          ],
        ),
      ),
    );
  }

  Widget _fxRow(String label, TextEditingController buy, TextEditingController sell) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 180, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          Expanded(child: TextField(controller: buy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buy Rate (PKR)', prefixText: 'Rs. '))),
          const SizedBox(width: 14),
          Expanded(child: TextField(controller: sell, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sell Rate (PKR)', prefixText: 'Rs. '))),
        ],
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
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
        SnackBar(content: Text(ok ? 'Live gold & FX ticker rates published!' : 'Save failed.'), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}