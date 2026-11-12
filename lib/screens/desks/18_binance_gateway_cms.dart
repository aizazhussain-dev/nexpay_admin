import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_image_picker.dart';
import '../../widgets/nexpay_ui_kit.dart';

class BinanceGatewayCmsScreen extends StatefulWidget {
  const BinanceGatewayCmsScreen({super.key});

  @override
  State<BinanceGatewayCmsScreen> createState() => _BinanceGatewayCmsScreenState();
}

class _BinanceGatewayCmsScreenState extends State<BinanceGatewayCmsScreen> {
  final _payIdCtrl = TextEditingController();
  final _trc20Ctrl = TextEditingController();
  final _depRateCtrl = TextEditingController();
  final _wthRateCtrl = TextEditingController();
  String _qrUrl = '';
  bool _initialized = false;
  bool _saving = false;

  void _syncFromConfig(AdminProvider admin) {
    final cfg = admin.cmsConfig;
    final b = (cfg['binanceSettings'] is Map) ? Map<String, dynamic>.from(cfg['binanceSettings']) : <String, dynamic>{};
    _payIdCtrl.text = (b['officialPayId'] ?? '').toString();
    _trc20Ctrl.text = (b['officialTrc20Address'] ?? '').toString();
    _depRateCtrl.text = (b['depRate'] ?? admin.usdPkrRate).toString();
    _wthRateCtrl.text = (b['wthRate'] ?? (admin.usdPkrRate - 2)).toString();
    _qrUrl = (b['qrUrl'] ?? '').toString();
    _initialized = true;
  }

  @override
  void dispose() {
    _payIdCtrl.dispose();
    _trc20Ctrl.dispose();
    _depRateCtrl.dispose();
    _wthRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!_initialized && admin.cmsConfig.isNotEmpty) {
      _syncFromConfig(admin);
    }

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Binance Pay & USDT TRC20 Treasury Gateway',
        subtitle: 'Configure official merchant Binance Pay ID, TRC20 custody wallet, QR code from gallery, and P2P FX rates',
        badgeText: 'CRYPTO GATEWAY',
        badgeColor: AppConstants.accentGold,
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              await admin.fetchAllData();
              if (mounted) setState(() => _syncFromConfig(admin));
            },
            icon: const Icon(Icons.sync_rounded, size: 17),
            label: const Text('Reload Config'),
          ),
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.save_rounded, size: 17),
            label: Text(_saving ? 'Publishing...' : 'Save & Publish Gateway'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'USDT Buy / Deposit Rate',
            value: 'Rs. ${_depRateCtrl.text.isEmpty ? admin.usdPkrRate.toStringAsFixed(1) : _depRateCtrl.text}',
            sublabel: 'Customer PKR -> USDT conversion',
            icon: Icons.arrow_downward_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'USDT Sell / Payout Rate',
            value: 'Rs. ${_wthRateCtrl.text.isEmpty ? (admin.usdPkrRate - 2).toStringAsFixed(1) : _wthRateCtrl.text}',
            sublabel: 'Customer USDT -> PKR cashout',
            icon: Icons.arrow_upward_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Binance Merchant ID',
            value: _payIdCtrl.text.isEmpty ? 'Not Set' : _payIdCtrl.text,
            sublabel: 'Zero-fee internal Binance Pay ID',
            icon: Icons.currency_bitcoin_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Wallet QR Code',
            value: _qrUrl.isEmpty ? 'No QR' : 'QR Active',
            sublabel: 'Displayed in customer deposit screen',
            icon: Icons.qr_code_2_rounded,
            color: AppConstants.accentGreen,
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
            const Text('MERCHANT RECEIVING CREDENTIALS & QR CODE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
            const SizedBox(height: 16),
            NexPayImageUploader(
              label: 'Binance Pay / TRC20 Deposit QR Image (Upload From Gallery)',
              initialValue: _qrUrl,
              previewHeight: 160,
              onChanged: (v) => setState(() => _qrUrl = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _payIdCtrl, decoration: const InputDecoration(labelText: 'Official Binance Pay ID'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _trc20Ctrl, decoration: const InputDecoration(labelText: 'Official USDT (TRC20) Deposit Address'))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _depRateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'USDT Deposit Rate (PKR per 1 USDT)', prefixText: 'Rs. '),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _wthRateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'USDT Withdrawal Rate (PKR per 1 USDT)', prefixText: 'Rs. '),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
    setState(() => _saving = true);
    final ok = await admin.saveCmsConfig({
      'binanceSettings': {
        'officialPayId': _payIdCtrl.text.trim(),
        'officialTrc20Address': _trc20Ctrl.text.trim(),
        'depRate': double.tryParse(_depRateCtrl.text.trim()) ?? admin.usdPkrRate,
        'wthRate': double.tryParse(_wthRateCtrl.text.trim()) ?? (admin.usdPkrRate - 2),
        'qrUrl': _qrUrl,
      },
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Binance gateway settings published live!' : 'Failed to save settings.'), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}