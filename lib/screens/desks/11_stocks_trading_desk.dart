import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class StocksTradingDeskScreen extends StatefulWidget {
  const StocksTradingDeskScreen({super.key});

  @override
  State<StocksTradingDeskScreen> createState() =>
      _StocksTradingDeskScreenState();
}

class _StocksTradingDeskScreenState extends State<StocksTradingDeskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  String _activeTab = 'EQUITIES CATALOG';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stocks = admin.stocks;
    final trades = admin.stockTrades;
    final fxRate = admin.usdPkrRate;

    double totalTradeVolumeUsd = 0;
    for (final t in trades) {
      if (t is Map) {
        totalTradeVolumeUsd += double.tryParse(
            t['total_usd']?.toString() ??
                t['amount_usd']?.toString() ??
                '0') ??
            0;
      }
    }

    final filteredStocks = stocks.where((raw) {
      if (raw is! Map) return false;
      if (_query.isEmpty) return true;
      final hay =
      '${raw['symbol']} ${raw['ticker']} ${raw['name']} ${raw['sector']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    final filteredTrades = trades.where((raw) {
      if (raw is! Map) return false;
      if (_query.isEmpty) return true;
      final hay =
      '${raw['id']} ${raw['user_mobile']} ${raw['symbol']} ${raw['side']}'
          .toLowerCase();
      return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'US Equities Brokerage & Fractional Trading Desk',
        subtitle:
        'Manage listed NASDAQ/NYSE fractional stocks, live USD/PKR conversion quotes, and executed investor orders',
        badgeText: admin.isMarketOpen ? 'NYSE / NASDAQ OPEN' : 'EQUITIES DESK',
        badgeColor: admin.isMarketOpen
            ? AppConstants.accentGreen
            : AppConstants.accentBlue,
        actions: [
          OutlinedButton.icon(
            onPressed: () => admin.fetchAllData(),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Sync Market'),
          ),
          ElevatedButton.icon(
            onPressed: () => _openStockEditorDrawer(context, admin, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('List New US Stock'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Listed US Equities',
            value: '${stocks.length} Tickers',
            sublabel: 'Active fractional stocks in app',
            icon: Icons.candlestick_chart_rounded,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Executed Equity Orders',
            value: '${trades.length} Trades',
            sublabel: 'Live buy & sell brokerage fills',
            icon: Icons.swap_vert_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Gross Equity Volume',
            value: '\$ ${_money.format(totalTradeVolumeUsd)}',
            sublabel:
            'Rs. ${_money.format(totalTradeVolumeUsd * fxRate)} equivalent',
            icon: Icons.trending_up_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Active FX Quote Rate',
            value: 'Rs. ${fxRate.toStringAsFixed(2)}',
            sublabel: '1.00 USD -> PKR settlement rate',
            icon: Icons.currency_exchange_rounded,
            color: AppConstants.accentGreen,
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: _activeTab == 'EQUITIES CATALOG'
            ? 'Search by ticker symbol (AAPL, TSLA), company name, or sector...'
            : 'Search trades by investor mobile, ticker, or order side...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['EQUITIES CATALOG', 'LIVE CUSTOMER TRADES'],
        selectedFilter: _activeTab,
        onFilterChanged: (t) => setState(() => _activeTab = t),
        resultSummary: _activeTab == 'EQUITIES CATALOG'
            ? 'Showing ${filteredStocks.length} of ${stocks.length} stocks'
            : 'Showing ${filteredTrades.length} of ${trades.length} trades',
      ),
      body: _activeTab == 'EQUITIES CATALOG'
          ? _buildStocksTable(context, admin, filteredStocks, fxRate)
          : _buildTradesTable(filteredTrades, fxRate),
    );
  }

  Widget _buildStocksTable(BuildContext context, AdminProvider admin,
      List<dynamic> list, double fxRate) {
    return NexPayFullWidthTable(
      minTableWidth: 1120,
      emptyState: const NexPayEmptyState(
        icon: Icons.candlestick_chart_rounded,
        title: 'No Listed US Equities Found',
        subtitle:
        'Click "List New US Stock" above to add NASDAQ/NYSE equities to the live database.',
      ),
      columns: const [
        DataColumn(label: Text('TICKER')),
        DataColumn(label: Text('COMPANY NAME')),
        DataColumn(label: Text('SECTOR')),
        DataColumn(label: Text('PRICE (USD)'), numeric: true),
        DataColumn(label: Text('PRICE (PKR)'), numeric: true),
        DataColumn(label: Text('24H CHANGE'), numeric: true),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('CATALOG ACTIONS')),
      ],
      rows: list.map((raw) {
        final s = Map<String, dynamic>.from(raw as Map);
        final id = int.tryParse(s['id']?.toString() ?? '0') ?? 0;
        final symbol = (s['symbol'] ?? s['ticker'] ?? 'STK')
            .toString()
            .toUpperCase();
        final name = (s['name'] ?? 'Corporation').toString();
        final sector = (s['sector'] ?? 'Technology').toString();
        final priceUsd = double.tryParse(
            s['price']?.toString() ?? s['price_usd']?.toString() ?? '0') ??
            0;
        final change = double.tryParse(s['change']?.toString() ??
            s['change_percent']?.toString() ??
            '0') ??
            0;
        final isActive = s['isActive'] != false && s['is_active'] != 0;

        return DataRow(
          cells: [
            DataCell(
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: AppConstants.bgDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  symbol,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ),
            DataCell(
              Text(name,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700)),
            ),
            DataCell(
              Text(sector,
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 12.5)),
            ),
            DataCell(
              Text('\$ ${_money.format(priceUsd)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentGold,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            DataCell(
              Text('Rs. ${_money.format(priceUsd * fxRate)}',
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            DataCell(
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: change >= 0
                      ? AppConstants.accentGreen
                      : AppConstants.dangerRed,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            DataCell(NexPayStatusBadge(status: isActive ? 'ACTIVE' : 'INACTIVE')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openStockEditorDrawer(context, admin, s),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Delist Stock',
                    icon: Icon(Icons.delete_outline_rounded,
                        color: AppConstants.dangerRed, size: 19),
                    onPressed: () async {
                      final confirmed = await showNexPayConfirmDialog(
                        context: context,
                        title: 'Delist Equity $symbol',
                        message:
                        'Remove $name ($symbol) from the active fractional brokerage catalog?',
                        confirmLabel: 'Delist Stock',
                        confirmColor: AppConstants.dangerRed,
                        icon: Icons.delete_outline_rounded,
                      );
                      if (!confirmed || !context.mounted) return;
                      final ok = await admin.deleteStock(id);
                      if (context.mounted) {
                        _toast(
                            context,
                            ok
                                ? '$symbol delisted from catalog.'
                                : 'Delete failed.',
                            ok);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTradesTable(List<dynamic> list, double fxRate) {
    return NexPayFullWidthTable(
      minTableWidth: 1120,
      emptyState: const NexPayEmptyState(
        icon: Icons.swap_vert_rounded,
        title: 'No Equity Trades Recorded Yet',
        subtitle:
        'Live customer buy and sell orders for US stocks will appear here automatically.',
      ),
      columns: const [
        DataColumn(label: Text('ORDER ID')),
        DataColumn(label: Text('INVESTOR MOBILE')),
        DataColumn(label: Text('TICKER')),
        DataColumn(label: Text('SIDE')),
        DataColumn(label: Text('SHARES'), numeric: true),
        DataColumn(label: Text('EXEC PRICE (USD)'), numeric: true),
        DataColumn(label: Text('TOTAL VALUE (PKR)'), numeric: true),
        DataColumn(label: Text('TIMESTAMP')),
      ],
      rows: list.map((raw) {
        final t = Map<String, dynamic>.from(raw as Map);
        final id = (t['id'] ?? '-').toString();
        final mobile = (t['user_mobile'] ?? t['mobile'] ?? '-').toString();
        final symbol =
        (t['symbol'] ?? t['ticker'] ?? '-').toString().toUpperCase();
        final side = (t['side'] ?? t['type'] ?? 'BUY').toString().toUpperCase();
        final shares = double.tryParse(
            t['shares']?.toString() ?? t['quantity']?.toString() ?? '0') ??
            0;
        final execUsd = double.tryParse(t['price_usd']?.toString() ??
            t['exec_price']?.toString() ??
            '0') ??
            0;
        final totalUsd = double.tryParse(t['total_usd']?.toString() ?? '0') ??
            (shares * execUsd);
        final date = (t['created_at'] ?? t['date'] ?? '-').toString();

        return DataRow(
          cells: [
            DataCell(NexPayCopyableId(text: '#EQ-$id', label: 'Order ID')),
            DataCell(
              Text(mobile,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
            DataCell(
              Text(symbol,
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700)),
            ),
            DataCell(NexPayStatusBadge(status: side)),
            DataCell(
              Text(shares.toStringAsFixed(4),
                  style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontFamily: 'Consolas',
                      fontWeight: FontWeight.w600)),
            ),
            DataCell(
              Text('\$ ${_money.format(execUsd)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentGold,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            DataCell(
              Text('Rs. ${_money.format(totalUsd * fxRate)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentGreen,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            DataCell(
              Text(date,
                  style:
                  TextStyle(color: AppConstants.textMuted, fontSize: 12)),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _openStockEditorDrawer(BuildContext context, AdminProvider admin,
      Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final symbolCtrl = TextEditingController(
        text: (existing?['symbol'] ?? existing?['ticker'] ?? '').toString());
    final nameCtrl =
    TextEditingController(text: (existing?['name'] ?? '').toString());
    final sectorCtrl = TextEditingController(
        text: (existing?['sector'] ?? 'Technology').toString());
    final priceCtrl = TextEditingController(
        text: (existing?['price'] ?? existing?['price_usd'] ?? '').toString());
    final changeCtrl = TextEditingController(
        text: (existing?['change'] ?? existing?['change_percent'] ?? '0.0')
            .toString());
    bool isActive = existing == null ||
        (existing['isActive'] != false && existing['is_active'] != 0);

    showNexPayInspectorDrawer(
      context: context,
      title: isEdit ? 'Edit Equity: ${symbolCtrl.text}' : 'List New US Stock',
      subtitle: 'Configure live NASDAQ / NYSE fractional stock quote in database',
      child: StatefulBuilder(
        builder: (ctx, setDrawerState) {
          final parsedUsd = double.tryParse(priceCtrl.text.trim()) ?? 0;
          final pkrPreview = parsedUsd * admin.usdPkrRate;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: symbolCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Ticker Symbol (e.g. AAPL)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: sectorCtrl,
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration:
                      const InputDecoration(labelText: 'Market Sector'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: AppConstants.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Full Company Name (e.g. Apple Inc.)'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      onChanged: (_) => setDrawerState(() {}),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Share Price (USD)', prefixText: '\$ '),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: changeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: '24h Change (%)', suffixText: '%'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live PKR Share Quote (@ Rs. ${admin.usdPkrRate.toStringAsFixed(1)}):',
                      style: TextStyle(
                          color: AppConstants.textMuted, fontSize: 12),
                    ),
                    Text(
                      'Rs. ${_money.format(pkrPreview)}',
                      style: TextStyle(
                          color: AppConstants.accentGreen,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Active for Customer Trading',
                    style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5)),
                value: isActive,
                activeThumbColor: AppConstants.accentGreen,
                onChanged: (v) => setDrawerState(() => isActive = v),
              ),
            ],
          );
        },
      ),
      footerActions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: () async {
            final sym = symbolCtrl.text.trim().toUpperCase();
            final name = nameCtrl.text.trim();
            final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
            if (sym.isEmpty || name.isEmpty || price <= 0) {
              _toast(
                  context,
                  'Enter valid symbol, company name, and USD price.',
                  false);
              return;
            }
            Navigator.pop(context);
            final ok = await admin.saveStock({
              if (isEdit && existing['id'] != null) 'id': existing['id'],
              'symbol': sym,
              'name': name,
              'sector': sectorCtrl.text.trim(),
              'price': price,
              'change': double.tryParse(changeCtrl.text.trim()) ?? 0.0,
              'isActive': isActive ? 1 : 0,
            });
            if (context.mounted) {
              _toast(
                  context,
                  ok
                      ? '$sym saved to live equities catalog!'
                      : 'Failed to save stock.',
                  ok);
            }
          },
          icon: const Icon(Icons.save_rounded, size: 17),
          label: const Text('Save Equity'),
        ),
      ],
    );
  }

  void _toast(BuildContext context, String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor:
          ok ? AppConstants.accentGreen : AppConstants.dangerRed),
    );
  }
}