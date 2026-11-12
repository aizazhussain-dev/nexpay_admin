import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class StocksTradingDeskScreen extends StatefulWidget {
  const StocksTradingDeskScreen({super.key});

  @override
  State<StocksTradingDeskScreen> createState() => _StocksTradingDeskScreenState();
}

class _StocksTradingDeskScreenState extends State<StocksTradingDeskScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  int _activeSubDesk = 0; // 0: Catalog, 1: Trades Ledger, 2: Holdings, 3: Analytics
  bool _isLoading = true;
  bool _isMarketOpen = false;
  double _usdPkrRate = 280.0;

  List<dynamic> _stocksList = [];
  List<dynamic> _tradesList = [];

  String _searchQuery = "";
  String _tradeTypeFilter = "ALL"; // ALL, BUY, SELL

  @override
  void initState() {
    super.initState();
    _fetchStocksData();
  }

  Future<void> _fetchStocksData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Stocks Catalog & Live Market Status
      final stockRes = await _api.dio.get(
        '',
        queryParameters: {'action': 'get_stocks', '_t': DateTime.now().millisecondsSinceEpoch},
      );
      if (stockRes.data['status'] == 'success') {
        _stocksList = stockRes.data['stocks'] ?? [];
        _isMarketOpen = stockRes.data['isMarketOpen'] == true;
        _usdPkrRate = double.tryParse(stockRes.data['usdPkrRate']?.toString() ?? '280') ?? 280.0;
      }

      // 2. Fetch Customer Trades Ledger (Enriched with live spot & P&L)
      final tradeRes = await _api.dio.get(
        '',
        queryParameters: {'action': 'get_all_stock_trades', '_t': DateTime.now().millisecondsSinceEpoch},
      );
      if (tradeRes.data['status'] == 'success') {
        _tradesList = tradeRes.data['trades'] ?? [];
      }
    } catch (e) {
      debugPrint("Stocks API Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

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
                        Text(
                          "Wall Street US Stocks & Equities Console",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: (_isMarketOpen ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: (_isMarketOpen ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _isMarketOpen ? "● MARKET OPEN" : "○ MARKET CLOSED",
                            style: TextStyle(color: _isMarketOpen ? AppConstants.accentGreen : AppConstants.dangerRed, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "NASDAQ & NYSE live equities engine • USD/PKR Peg: ₨ ${_usdPkrRate.toStringAsFixed(2)}",
                      style: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: const Color(0xFF021A13),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _fetchStocksData,
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("Sync Wall Street", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Institutional Metric Badges
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildMetricCard("CATALOG STOCKS", "${_stocksList.length} Active Equities", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("TOTAL EXECUTED TRADES", "${_tradesList.length} Orders", AppConstants.accentGold, isDesktop),
              _buildMetricCard("USD / PKR BENCHMARK", "₨ ${_usdPkrRate.toStringAsFixed(2)}", Colors.white, isDesktop),
              _buildMetricCard("FEED TELEMETRY", _isMarketOpen ? "Active Spot Streaming" : "After-Hours Feed", _isMarketOpen ? AppConstants.accentGreen : AppConstants.textMuted, isDesktop),
            ],
          ),
          const SizedBox(height: 20),

          // Sub-Desk Segmented Navigation Tabs
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildSubDeskTab(0, "📊 Equities Catalog (${_stocksList.length})"),
              _buildSubDeskTab(1, "📜 Customer Trades & P&L Ledger (${_tradesList.length})"),
              _buildSubDeskTab(2, "💼 Customer Holdings Exposure"),
              _buildSubDeskTab(3, "📈 Platform Margin Earnings"),
            ],
          ),
          const SizedBox(height: 18),

          // Dynamic Sub-Desk Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
                : _buildActiveSubDeskView(isDesktop, admin),
          ),
        ],
      ),
    );
  }

  Widget _buildSubDeskTab(int index, String title) {
    final isSelected = _activeSubDesk == index;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppConstants.accentGreen : AppConstants.surface,
        foregroundColor: isSelected ? const Color(0xFF021A13) : AppConstants.textMuted,
        elevation: 0,
        side: BorderSide(color: isSelected ? AppConstants.accentGreen : Colors.white10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => setState(() => _activeSubDesk = index),
      child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700)),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, bool isDesktop) {
    return Container(
      width: isDesktop ? 220 : 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
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

  // Sub-Desk Routing Switcher
  Widget _buildActiveSubDeskView(bool isDesktop, AdminProvider admin) {
    switch (_activeSubDesk) {
      case 0:
        return _buildCatalogSubDesk(isDesktop);
      case 1:
        return _buildTradesLedgerSubDesk(isDesktop);
      case 2:
        return _buildHoldingsExposureSubDesk(isDesktop, admin);
      case 3:
        return _buildPlatformMarginSubDesk(isDesktop);
      default:
        return _buildCatalogSubDesk(isDesktop);
    }
  }

  // ==========================================
  // SUB-DESK 1: EQUITIES CATALOG
  // ==========================================
  Widget _buildCatalogSubDesk(bool isDesktop) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Active Wall Street Stocks in App Catalog",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.surfaceCard,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _openAddEditStockModal(context, null),
              icon: const Icon(Icons.add_rounded, size: 16, color: AppConstants.accentGreen),
              label: const Text("Add New Stock", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
                    dataRowColor: WidgetStateProperty.all(Colors.transparent),
                    horizontalMargin: 20,
                    columnSpacing: 26,
                    columns: const [
                      DataColumn(label: Text("LOGO", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("TICKER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("COMPANY LEGAL NAME", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("SPOT PRICE (USD)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("ESTIMATED SPOT (PKR)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("BROKER SPREAD", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                    ],
                    rows: _stocksList.map((s) {
                      final priceUsd = double.tryParse(s['base_price_usd']?.toString() ?? '0') ?? 0.0;
                      final pricePkr = priceUsd * _usdPkrRate;
                      final status = (s['status'] ?? 'ACTIVE').toString().toUpperCase();
                      final logoUrl = (s['logo_url'] ?? '').toString();

                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              width: 32,
                              height: 32,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: logoUrl.isNotEmpty
                                  ? Image.network(logoUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.trending_up, color: Colors.black54, size: 18))
                                  : const Icon(Icons.trending_up, color: Colors.black54, size: 18),
                            ),
                          ),
                          DataCell(Text(s['symbol'] ?? '-', style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s['name'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                Text(s['category'] ?? 'Technology', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          DataCell(Text("\$ ${priceUsd.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w900, fontSize: 14))),
                          DataCell(Text("₨ ${_currencyFormat.format(pricePkr)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFA855F7).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text("+${s['spread_percent'] ?? 1.0}% Spread", style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (status == 'ACTIVE' ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status, style: TextStyle(color: status == 'ACTIVE' ? AppConstants.accentGreen : AppConstants.dangerRed, fontSize: 10.5, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentBlue),
                                  tooltip: "Edit Stock Parameters",
                                  onPressed: () => _openAddEditStockModal(context, s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
                                  tooltip: "Delete Stock",
                                  onPressed: () => _confirmDeleteStock(context, s),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SUB-DESK 2: TRADES LEDGER & LIVE P&L
  // ==========================================
  Widget _buildTradesLedgerSubDesk(bool isDesktop) {
    final filtered = _tradesList.where((t) {
      final type = (t['trade_type'] ?? 'BUY').toString().toUpperCase();
      if (_tradeTypeFilter == "BUY" && !type.contains("BUY")) return false;
      if (_tradeTypeFilter == "SELL" && !type.contains("SELL")) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final mob = (t['user_mobile'] ?? '').toString().toLowerCase();
        final name = (t['user_name'] ?? '').toString().toLowerCase();
        final sym = (t['symbol'] ?? '').toString().toLowerCase();
        final tid = (t['trade_tid'] ?? '').toString().toLowerCase();
        return mob.contains(q) || name.contains(q) || sym.contains(q) || tid.contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search Trades: Mobile, Customer, Symbol, TID...",
                  hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppConstants.textMuted),
                  filled: true,
                  fillColor: AppConstants.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
            ),
            const SizedBox(width: 12),
            _buildTradeFilterChip("ALL", "All Orders"),
            const SizedBox(width: 6),
            _buildTradeFilterChip("BUY", "BUY Only"),
            const SizedBox(width: 6),
            _buildTradeFilterChip("SELL", "SELL Only"),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
                    dataRowColor: WidgetStateProperty.all(Colors.transparent),
                    horizontalMargin: 20,
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text("TIMESTAMP", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("CUSTOMER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("ORDER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("TICKER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("SHARES", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("EXEC PRICE", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("SPOT & P&L", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("TOTAL PKR", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                      DataColumn(label: Text("TRADE TID", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                    ],
                    rows: filtered.map((t) {
                      final rawType = (t['trade_type'] ?? 'BUY').toString().toUpperCase();
                      final isBuy = rawType.contains('BUY');
                      final isLimit = rawType.contains('LIMIT');

                      final execPriceUsd = double.tryParse(t['price_usd']?.toString() ?? '0') ?? 0.0;
                      final curSpotUsd = double.tryParse(t['current_spot_usd']?.toString() ?? '$execPriceUsd') ?? execPriceUsd;

                      // Live Customer P&L Calculation
                      final diff = isBuy ? (curSpotUsd - execPriceUsd) : (execPriceUsd - curSpotUsd);
                      final pnlPct = execPriceUsd > 0 ? (diff / execPriceUsd) * 100 : 0.0;
                      final isProfit = pnlPct >= 0;

                      final totalPkr = double.tryParse(t['total_pkr']?.toString() ?? '0') ?? 0.0;
                      final shares = double.tryParse(t['shares']?.toString() ?? '0') ?? 0.0;

                      return DataRow(
                        cells: [
                          DataCell(Text(t['created_at']?.toString() ?? '-', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t['user_name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                Text(t['user_mobile'] ?? '-', style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isBuy ? AppConstants.accentGreen : AppConstants.dangerRed).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(isBuy ? "BUY" : "SELL", style: TextStyle(color: isBuy ? AppConstants.accentGreen : AppConstants.dangerRed, fontWeight: FontWeight.w900, fontSize: 11)),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(isLimit ? "LIMIT" : "MARKET", style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t['symbol'] ?? '-', style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13.5)),
                                Text(t['company_name'] ?? '', style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
                              ],
                            ),
                          ),
                          DataCell(Text("${shares.toStringAsFixed(4)} Sh", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
                          DataCell(Text("\$ ${execPriceUsd.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold))),
                          DataCell(
                            Row(
                              children: [
                                Text(
                                  "${isProfit ? '▲ +' : '▼ '}${pnlPct.toStringAsFixed(2)}%",
                                  style: TextStyle(color: isProfit ? AppConstants.accentGreen : AppConstants.dangerRed, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                                const SizedBox(width: 6),
                                Text("(\$ ${curSpotUsd.toStringAsFixed(2)})", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              "${isBuy ? '-' : '+'} ₨ ${_currencyFormat.format(totalPkr)}",
                              style: TextStyle(color: isBuy ? AppConstants.dangerRed : AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 13.5),
                            ),
                          ),
                          DataCell(Text(t['trade_tid'] ?? '-', style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTradeFilterChip(String key, String label) {
    final isSelected = _tradeTypeFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.accentGreen,
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF021A13) : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 11.5,
      ),
      side: BorderSide(color: isSelected ? AppConstants.accentGreen : Colors.white10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => setState(() => _tradeTypeFilter = key),
    );
  }

  // ==========================================
  // SUB-DESK 3: CUSTOMER HOLDINGS EXPOSURE
  // ==========================================
  Widget _buildHoldingsExposureSubDesk(bool isDesktop, AdminProvider admin) {
    final List holdings = [];

    admin.users.forEach((mob, userData) {
    final name = (userData['name'] ?? 'Customer').toString();
    final txs = userData['transactions'];
    final Map<String, double> userStockShares = {};

    if (txs is List) {
    for (var t in txs) {
    if (t is Map) {
    final title = (t['title'] ?? '').toString();
    final dest = (t['dest'] ?? '').toString();

    if (title.contains('US Stock') || dest.contains('Shares')) {
    final match = RegExp(r'([0-9.]+)\s*Shares\s*([A-Z0-9]+)', caseSensitive: false).firstMatch(dest);
    if (match != null) {
    final sh = double.tryParse(match.group(1)!) ?? 0.0;
    final sym = match.group(2)!.toUpperCase();
    final amt = double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
    final isBuy = amt < 0 || title.contains('Purchase') || title.contains('BUY');

    userStockShares[sym] = (userStockShares[sym] ?? 0.0) + (isBuy ? sh : -sh);
    }
    }
    }
    }
    }

    userStockShares.forEach((sym, sh) {
    if (sh > 0.0001) {
    final matchedStock = _stocksList.firstWhere((s) => s['symbol'] == sym, orElse: () => null);
    final spotUsd = matchedStock != null ? double.tryParse(matchedStock['base_price_usd']?.toString() ?? '100') ?? 100.0 : 100.0;
    final valUsd = sh * spotUsd;
    final valPkr = valUsd * _usdPkrRate;

    holdings.add({
    'mobile': mob,
    'name': name,
    'symbol': sym,
    'shares': sh,
    'valUsd': valUsd,
    'valPkr': valPkr,
    });
    }
    });
    });

    return Container(
    decoration: BoxDecoration(
    color: AppConstants.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.white10),
    ),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
    headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
    dataRowColor: WidgetStateProperty.all(Colors.transparent),
    horizontalMargin: 20,
    columnSpacing: 28,
    columns: const [
    DataColumn(label: Text("INVESTOR", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
    DataColumn(label: Text("TICKER", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
    DataColumn(label: Text("SHARES OWNED", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
    DataColumn(label: Text("VALUATION (USD)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
    DataColumn(label: Text("VALUATION (PKR)", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
    ],
    rows: holdings.map((h) {
    return DataRow(
    cells: [
    DataCell(
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Text(h['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
    Text(h['mobile'], style: const TextStyle(color: AppConstants.accentBlue, fontSize: 11.5, fontFamily: 'monospace')),
    ],
    ),
    ),
    DataCell(Text(h['symbol'], style: const TextStyle(color: AppConstants.accentGreen, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 14))),
    DataCell(Text("${(h['shares'] as double).toStringAsFixed(4)} Sh", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
    DataCell(Text("\$ ${(h['valUsd'] as double).toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold))),
    DataCell(Text("₨ ${_currencyFormat.format(h['valPkr'])}", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 13.5))),
    ],
    );
    }).toList(),
    ),
    ),
    ),
    ),
    );
  }

  // ==========================================
  // SUB-DESK 4: PLATFORM MARGIN EARNINGS
  // ==========================================
  Widget _buildPlatformMarginSubDesk(bool isDesktop) {
    double totalVolPkr = 0;
    double totalShares = 0;

    for (var t in _tradesList) {
      totalVolPkr += double.tryParse(t['total_pkr']?.toString() ?? '0') ?? 0.0;
      totalShares += double.tryParse(t['shares']?.toString() ?? '0') ?? 0.0;
    }

    final houseMargin = totalVolPkr * 0.01; // 1% Broker Spread House Commission

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 820),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Institutional Trading Volume & House Margin Analytics",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              "Reconciliation of Wall Street retail turnover and platform spread gains",
              style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildMetricCard("TOTAL TURNOVER", "₨ ${_currencyFormat.format(totalVolPkr)}", AppConstants.accentGreen, true)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("TRANSACTED SHARES", "${totalShares.toStringAsFixed(4)} Sh", AppConstants.accentBlue, true)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("BROKER SPREAD GAIN", "₨ ${_currencyFormat.format(houseMargin)}", const Color(0xFFFBBF24), true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add / Edit Stock Modal
  void _openAddEditStockModal(BuildContext context, dynamic existing) {
    final isEdit = existing != null;
    final symbolController = TextEditingController(text: isEdit ? existing['symbol'] : '');
    final nameController = TextEditingController(text: isEdit ? existing['name'] : '');
    final categoryController = TextEditingController(text: isEdit ? existing['category'] : 'Technology');
    final priceController = TextEditingController(text: isEdit ? existing['base_price_usd'].toString() : '');
    final spreadController = TextEditingController(text: isEdit ? existing['spread_percent'].toString() : '1.0');
    final logoController = TextEditingController(text: isEdit ? existing['logo_url'] : '');
    String status = isEdit ? existing['status'] : 'ACTIVE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
          title: Text(isEdit ? "Edit Stock: ${existing['symbol']}" : "Add Wall Street Stock", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: symbolController,
                    readOnly: isEdit,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "TICKER SYMBOL (e.g. AAPL, NVDA, TSLA)",
                      labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppConstants.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "COMPANY LEGAL NAME",
                      labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppConstants.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "PRICE (USD)",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: spreadController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "SPREAD %",
                            labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                            filled: true,
                            fillColor: AppConstants.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: logoController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: "LOGO IMAGE URL (PNG / SVG)",
                      labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppConstants.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGreen, foregroundColor: const Color(0xFF021A13)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final payload = {
                    'id': isEdit ? existing['id'] : 0,
                    'symbol': symbolController.text.trim().toUpperCase(),
                    'name': nameController.text.trim(),
                    'category': categoryController.text.trim(),
                    'status': status,
                    'base_price_usd': double.tryParse(priceController.text) ?? 100.0,
                    'spread_percent': double.tryParse(spreadController.text) ?? 1.0,
                    'logo_url': logoController.text.trim(),
                  };

                  final res = await _api.dio.post(
                    '',
                    queryParameters: {'action': 'admin_save_stock'},
                    data: payload,
                  );

                  if (res.data['status'] == 'success') {
                    _fetchStocksData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppConstants.accentGreen, content: Text("✓ Stock ${payload['symbol']} saved live!", style: const TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold))),
                      );
                    }
                  }
                } catch (_) {}
              },
              child: const Text("Save to Live Catalog", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStock(BuildContext context, dynamic stock) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surface,
        title: Text("Delete ${stock['symbol']}?", style: const TextStyle(color: Colors.white)),
        content: Text("Kya aap waqai ${stock['symbol']} ko catalog se delete karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await _api.dio.post(
                '',
                queryParameters: {'action': 'admin_delete_stock'},
                data: {'id': stock['id']},
              );
              _fetchStocksData();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}