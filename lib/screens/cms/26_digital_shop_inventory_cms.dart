import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';

class DigitalShopInventoryCmsScreen extends StatefulWidget {
  const DigitalShopInventoryCmsScreen({super.key});

  @override
  State<DigitalShopInventoryCmsScreen> createState() => _DigitalShopInventoryCmsScreenState();
}

class _DigitalShopInventoryCmsScreenState extends State<DigitalShopInventoryCmsScreen> {
  final ApiClient _api = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  List _productsList = [];
  String _searchQuery = "";
  String _categoryFilter = "ALL"; // ALL, STREAMING, AI_TOOLS, MUSIC, GAMING
  String _statusFilter = "ALL"; // ALL, ACTIVE, DISABLED, OUT_OF_STOCK
  bool _isSaving = false;
  bool _isInitialized = false;

  // Default Digital Shop inventory fallback
  final List _defaultProducts = [
  {
  'id': 'netflix_4k_1m',
  'name': 'Netflix UHD 4K (1 Screen Private)',
  'category': 'STREAMING',
  'validity': '1 Month',
  'price': 450.0,
  'icon': '🎬',
  'description': 'Private Ultra-HD Profile with PIN Lock & Full Warranty.',
  'keys': [
  'netflix_user1@nexpay.vip:Pass#99201',
  'netflix_user2@nexpay.vip:Pass#88123',
  'netflix_user3@nexpay.vip:Pass#77341',
  ],
  'status': 'ACTIVE',
  },
  {
  'id': 'chatgpt_plus_1m',
  'name': 'ChatGPT Plus (GPT-4o Access)',
  'category': 'AI_TOOLS',
  'validity': '1 Month',
  'price': 1850.0,
  'icon': '🤖',
  'description': 'Shared Team Workspace slot with full GPT-4o & DALL-E 3 quotas.',
  'keys': [
  'ai_dev1@nexpay.cloud:TokenKey#1928301',
  'ai_dev2@nexpay.cloud:TokenKey#8192031',
  ],
  'status': 'ACTIVE',
  },
  {
  'id': 'spotify_prem_3m',
  'name': 'Spotify Premium (Ad-Free Audio)',
  'category': 'MUSIC',
  'validity': '3 Months',
  'price': 600.0,
  'icon': '🎵',
  'description': 'Family plan private invite link or fresh pre-activated login.',
  'keys': [
  'https://spotify.com/family/join/invite?token=nxp_99210291',
  'https://spotify.com/family/join/invite?token=nxp_88192019',
  ],
  'status': 'ACTIVE',
  },
  {
  'id': 'prime_video_1m',
  'name': 'Amazon Prime Video Private',
  'category': 'STREAMING',
  'validity': '1 Month',
  'price': 300.0,
  'icon': '📦',
  'description': 'Private profile on official Prime video master account.',
  'keys': [
  'prime_acc1@nexpay.vip:Key#881203',
  ],
  'status': 'ACTIVE',
  },
  {
  'id': 'youtube_prem_1m',
  'name': 'YouTube Premium + YT Music',
  'category': 'STREAMING',
  'validity': '1 Month',
  'price': 250.0,
  'icon': '▶️',
  'description': 'Personal email invite upgrade link without password sharing.',
  'keys': [],
  'status': 'ACTIVE',
  },
  {
  'id': 'steam_wallet_5usd',
  'name': 'Steam Wallet Gift Card (\$5 USD)',
  'category': 'GAMING',
  'validity': 'Lifetime',
  'price': 1450.0,
  'icon': '🎮',
  'description': 'Global Steam redeemable digital key code.',
  'keys': [
  'STEAM-9921-X9A2-K109',
  'STEAM-1102-M88A-Z992',
  ],
  'status': 'ACTIVE',
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadProductsFromProvider();
      _isInitialized = true;
    }
  }

  void _loadProductsFromProvider() {
    final admin = context.read<AdminProvider>();
    final cfg = admin.cmsConfig;

    if (cfg['digitalShopProducts'] is List && (cfg['digitalShopProducts'] as List).isNotEmpty) {
      final list = (cfg['digitalShopProducts'] as List)
          .whereType()
          .map((p) {
        final m = Map<String, dynamic>.from(p);
        if (m['keys'] is! List) m['keys'] = [];
        m['keys'] = List<String>.from(m['keys']);
        return m;
      })
          .toList();
      setState(() => _productsList = list);
    } else {
      setState(() {
        _productsList = _defaultProducts.map((p) => Map<String, dynamic>.from(p)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Filter Logic
    final filteredList = _productsList.where((p) {
      final cat = (p['category'] ?? 'STREAMING').toString().toUpperCase();
      final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
      final keys = (p['keys'] is List) ? (p['keys'] as List) : [];
      final isOutOfStock = keys.isEmpty;

      if (_categoryFilter != "ALL" && cat != _categoryFilter) return false;
      if (_statusFilter == "ACTIVE" && (status != "ACTIVE" || isOutOfStock)) return false;
      if (_statusFilter == "DISABLED" && status != "DISABLED") return false;
      if (_statusFilter == "OUT_OF_STOCK" && !isOutOfStock) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (p['name'] ?? '').toString().toLowerCase();
        final id = (p['id'] ?? '').toString().toLowerCase();
        final desc = (p['description'] ?? '').toString().toLowerCase();
        return name.contains(q) || id.contains(q) || desc.contains(q) || cat.contains(q);
      }
      return true;
    }).toList();

    // Operational Counters
    int totalKeysInVault = 0;
    int outOfStockCount = 0;
    int activeProductsCount = 0;

    for (var p in _productsList) {
      final keys = (p['keys'] is List) ? (p['keys'] as List) : [];
      final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();

      totalKeysInVault += keys.length;
      if (keys.isEmpty) outOfStockCount++;
      if (status == 'ACTIVE') activeProductsCount++;
    }

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
                          "Digital Shop Inventory & Keys Dispatcher CMS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "$totalKeysInVault KEYS IN VAULT",
                            style: const TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage Netflix 4K, AI Accounts, Music streaming and game keys with automated purchase delivery",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGreen,
                      foregroundColor: const Color(0xFF021A13),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openAddEditProductDialog(context, null, admin),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text("Add New Product", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _loadProductsFromProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✓ Reloaded digital inventory from memory.")),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 18, color: AppConstants.accentGreen),
                    label: const Text("Sync Memory", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
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
              _buildMetricCard("READY KEYS IN STOCK", "$totalKeysInVault Keys", AppConstants.accentGreen, isDesktop),
              _buildMetricCard("OUT OF STOCK ITEMS", "$outOfStockCount Products", outOfStockCount > 0 ? AppConstants.dangerRed : AppConstants.accentGreen, isDesktop),
              _buildMetricCard("ACTIVE CATALOG ITEMS", "$activeProductsCount Products", AppConstants.accentBlue, isDesktop),
              _buildMetricCard("TOTAL CATALOG ASSETS", "${_productsList.length} Items Listed", const Color(0xFFA855F7), isDesktop),
            ],
          ),
          const SizedBox(height: 20),

          // Filters & Search
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 300 : double.infinity,
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search Product, Service, Key...",
                    hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.textMuted, size: 20),
                    filled: true,
                    fillColor: AppConstants.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
              _buildCategoryChip("ALL", "All Products"),
              _buildCategoryChip("STREAMING", "🎬 Video Streaming"),
              _buildCategoryChip("AI_TOOLS", "🤖 AI & Workspaces"),
              _buildCategoryChip("MUSIC", "🎵 Music & Audio"),
              _buildCategoryChip("GAMING", "🎮 Gaming & Wallets"),
              const SizedBox(width: 8),
              _buildStatusFilterChip("ALL", "All"),
              _buildStatusFilterChip("ACTIVE", "Active / In-Stock"),
              _buildStatusFilterChip("OUT_OF_STOCK", "⚠️ Out of Stock"),
              _buildStatusFilterChip("DISABLED", "Disabled"),
            ],
          ),
          const SizedBox(height: 18),

          // Content Desk
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 54, color: AppConstants.textMuted),
                  SizedBox(height: 12),
                  Text(
                    "No digital inventory products found",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
                : isDesktop
                ? _buildDesktopTable(filteredList, admin)
                : _buildMobileCards(filteredList, admin),
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
        border: Border.all(color: Colors.white10),
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

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _categoryFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.accentGreen,
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF021A13) : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppConstants.accentGreen : Colors.white10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() => _categoryFilter = key),
    );
  }

  Widget _buildStatusFilterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.white24,
      backgroundColor: AppConstants.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppConstants.textMuted,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 11,
      ),
      side: BorderSide(color: isSelected ? Colors.white38 : Colors.white10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  Widget _buildDesktopTable(List list, AdminProvider admin) {
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
  columnSpacing: 26,
  columns: const [
  DataColumn(label: Text("ICON", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PRODUCT TITLE & DETAILS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("CATEGORY", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("PRICE & DURATION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("UNSOLD KEYS IN VAULT", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("STATUS", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  DataColumn(label: Text("EXECUTIVE ACTION", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
  ],
  rows: list.map((p) {
  final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final cat = (p['category'] ?? 'STREAMING').toString().toUpperCase();
  final icon = (p['icon'] ?? '🎬').toString();
  final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
  final validity = (p['validity'] ?? '1 Month').toString();
  final keys = (p['keys'] is List) ? List<String>.from(p['keys']) : <String>[];
  final isOutOfStock = keys.isEmpty;

  return DataRow(
  cells: [
  DataCell(
  Container(
  width: 36,
  height: 36,
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: Colors.white10),
  ),
  child: Center(
  child: Text(icon, style: const TextStyle(fontSize: 18)),
  ),
  ),
  ),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(p['name'] ?? 'Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
  Container(
  constraints: const BoxConstraints(maxWidth: 240),
  child: Text(
  p['description'] ?? '-',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  ),
  ),
  ],
  ),
  ),
  DataCell(_buildCategoryBadge(cat)),
  DataCell(
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Text(
  "₨ ${_currencyFormat.format(price)}",
  style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 13.5),
  ),
  Text("Pass: $validity", style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
  ],
  ),
  ),
  DataCell(
  Row(
  children: [
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: (isOutOfStock ? AppConstants.dangerRed : const Color(0xFFA855F7)).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(
  color: (isOutOfStock ? AppConstants.dangerRed : const Color(0xFFA855F7)).withValues(alpha: 0.3),
  ),
  ),
  child: Text(
  isOutOfStock ? "0 (OUT OF STOCK)" : "${keys.length} Ready Keys",
  style: TextStyle(
  color: isOutOfStock ? AppConstants.dangerRed : const Color(0xFFA855F7),
  fontWeight: FontWeight.w900,
  fontSize: 11,
  ),
  ),
  ),
  const SizedBox(width: 8),
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.surfaceCard,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: () => _openManageKeysModal(context, p, admin),
  icon: const Icon(Icons.vpn_key_rounded, size: 13, color: Color(0xFFFBBF24)),
  label: const Text("Vault", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
  ),
  ],
  ),
  ),
  DataCell(_buildStatusBadge(isActive, isOutOfStock)),
  DataCell(
  Row(
  children: [
  IconButton(
  icon: Icon(
  isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
  color: isActive ? AppConstants.accentGreen : AppConstants.textMuted,
  size: 26,
  ),
  tooltip: isActive ? "Disable Product" : "Enable Product",
  onPressed: () => _toggleProductStatus(p, admin),
  ),
  IconButton(
  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppConstants.accentBlue),
  tooltip: "Edit Product Details",
  onPressed: () => _openAddEditProductDialog(context, p, admin),
  ),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.dangerRed),
  tooltip: "Delete Product",
  onPressed: () => _confirmDeleteProduct(context, p, admin),
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
  );
  }

  Widget _buildMobileCards(List list, AdminProvider admin) {
  return ListView.builder(
  itemCount: list.length,
  itemBuilder: (context, idx) {
  final p = list[idx];
  final status = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final isActive = status == 'ACTIVE';
  final cat = (p['category'] ?? 'STREAMING').toString().toUpperCase();
  final icon = (p['icon'] ?? '🎬').toString();
  final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
  final validity = (p['validity'] ?? '1 Month').toString();
  final keys = (p['keys'] is List) ? List<String>.from(p['keys']) : <String>[];
  final isOutOfStock = keys.isEmpty;

  return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(
  color: isOutOfStock
  ? AppConstants.dangerRed.withValues(alpha: 0.3)
      : (isActive ? AppConstants.accentGreen.withValues(alpha: 0.3) : Colors.white10),
  ),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Row(
  children: [
  Text(icon, style: const TextStyle(fontSize: 20)),
  const SizedBox(width: 8),
  Text(p['name'] ?? 'Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5)),
  ],
  ),
  _buildStatusBadge(isActive, isOutOfStock),
  ],
  ),
  const SizedBox(height: 8),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  _buildCategoryBadge(cat),
  Text("₨ ${_currencyFormat.format(price)} ($validity)", style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 14)),
  ],
  ),
  const SizedBox(height: 6),
  Text(p['description'] ?? '-', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
  const Divider(color: Colors.white10, height: 20),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFA855F7).withValues(alpha: 0.15),
  foregroundColor: const Color(0xFFA855F7),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: () => _openManageKeysModal(context, p, admin),
  icon: const Icon(Icons.vpn_key_rounded, size: 14),
  label: Text("${keys.length} Ready Keys", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
  ),
  Row(
  children: [
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.accentBlue),
  onPressed: () => _openAddEditProductDialog(context, p, admin),
  icon: const Icon(Icons.edit_note_rounded, size: 16),
  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: AppConstants.dangerRed),
  onPressed: () => _confirmDeleteProduct(context, p, admin),
  icon: const Icon(Icons.delete_outline_rounded, size: 16),
  label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ),
  ],
  ),
  ],
  ),
  ],
  ),
  );
  },
  );
  }

  Widget _buildCategoryBadge(String cat) {
  Color color = AppConstants.accentGreen;
  if (cat == 'STREAMING') color = const Color(0xFFEF4444);
  if (cat == 'AI_TOOLS') color = const Color(0xFF38BDF8);
  if (cat == 'MUSIC') color = const Color(0xFF22C55E);
  if (cat == 'GAMING') color = const Color(0xFFFBBF24);

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
  decoration: BoxDecoration(
  color: color.withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text(cat, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
  );
  }

  Widget _buildStatusBadge(bool isActive, bool isOutOfStock) {
  Color bg;
  Color text;
  String label;

  if (isOutOfStock) {
  bg = AppConstants.dangerRed.withValues(alpha: 0.15);
  text = AppConstants.dangerRed;
  label = "OUT OF STOCK";
  } else if (isActive) {
  bg = AppConstants.accentGreen.withValues(alpha: 0.15);
  text = AppConstants.accentGreen;
  label = "IN STOCK";
  } else {
  bg = Colors.white10;
  text = AppConstants.textMuted;
  label = "DISABLED";
  }

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
  child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w900)),
  );
  }

  // =========================================================================
  // MANAGE STOCK KEYS MODAL (ADD BATCH KEYS & INSPECT INVENTORY)
  // =========================================================================
  void _openManageKeysModal(BuildContext context, Map<String, dynamic> product, AdminProvider admin) {
  final List<String> currentKeys = (product['keys'] is List)
  ? List<String>.from(product['keys'])
      : <String>[];

  final batchKeysController = TextEditingController();

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setModalState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
  title: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Expanded(
  child: Row(
  children: [
  const Icon(Icons.vpn_key_rounded, color: Color(0xFFFBBF24)),
  const SizedBox(width: 8),
  Expanded(
  child: Text(
  "Vault: ${product['name']}",
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
  overflow: TextOverflow.ellipsis,
  ),
  ),
  ],
  ),
  ),
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: const Color(0xFFA855F7).withValues(alpha: 0.15),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
  "${currentKeys.length} Unsold Keys",
  style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 11),
  ),
  ),
  ],
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 580, maxHeight: 520),
  child: SingleChildScrollView(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text(
  "ADD BATCH KEYS (PASTE ONE KEY / CREDENTIAL PER LINE)",
  style: TextStyle(color: AppConstants.accentGreen, fontSize: 10.5, fontWeight: FontWeight.w900),
  ),
  const SizedBox(height: 6),
  TextField(
  controller: batchKeysController,
  maxLines: 4,
  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
  decoration: InputDecoration(
  hintText: "user1@domain.com:Password123\nuser2@domain.com:Password456\nSTEAM-XXXX-YYYY-ZZZZ",
  hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  const SizedBox(height: 10),
  SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
  backgroundColor: AppConstants.accentGreen,
  foregroundColor: const Color(0xFF021A13),
  padding: const EdgeInsets.symmetric(vertical: 10),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: () {
  final rawText = batchKeysController.text.trim();
  if (rawText.isEmpty) return;

  final lines = rawText
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  setModalState(() {
  currentKeys.addAll(lines);
  batchKeysController.clear();
  });
  },
  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
  label: const Text("Load Keys into Vault", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
  ),
  ),
  const Divider(color: Colors.white10, height: 24),
  const Text(
  "CURRENT UNSOLD KEYS IN VAULT (AUTO-DISPATCHED ON PURCHASE)",
  style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800),
  ),
  const SizedBox(height: 8),
  currentKeys.isEmpty
  ? Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: AppConstants.dangerRed.withValues(alpha: 0.1),
  borderRadius: BorderRadius.circular(12),
  ),
  child: const Center(
  child: Text(
  "⚠️ Vault is completely empty! Product is marked OUT OF STOCK on customer app.",
  style: TextStyle(color: AppConstants.dangerRed, fontSize: 11.5, fontWeight: FontWeight.bold),
  textAlign: TextAlign.center,
  ),
  ),
  )
      : ListView.separated(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: currentKeys.length,
  separatorBuilder: (_, __) => const SizedBox(height: 6),
  itemBuilder: (c, i) {
  final k = currentKeys[i];
  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: Colors.white10),
  ),
  child: Row(
  children: [
  Text("#${i + 1}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
  const SizedBox(width: 8),
  Expanded(
  child: Text(
  k,
  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11.5),
  ),
  ),
  IconButton(
  icon: const Icon(Icons.copy_rounded, size: 14, color: AppConstants.textMuted),
  tooltip: "Copy Key",
  onPressed: () {
  Clipboard.setData(ClipboardData(text: k));
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("✓ Key copied to clipboard!"), duration: Duration(seconds: 1)),
  );
  },
  ),
  IconButton(
  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppConstants.dangerRed),
  tooltip: "Delete Key",
  onPressed: () => setModalState(() => currentKeys.removeAt(i)),
  ),
  ],
  ),
  );
  },
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

  final updatedList = List.from(_productsList);
  final idx = updatedList.indexWhere((x) => x['id'] == product['id']);
  if (idx != -1) {
  updatedList[idx]['keys'] = currentKeys;
  await _saveProductsList(updatedList, admin);
  }
  },
  child: const Text("Save Vault Keys", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  ),
  );
  }

  // Add / Edit Product Modal Dialog
  void _openAddEditProductDialog(BuildContext context, Map<String, dynamic>? existing, AdminProvider admin) {
  final isEdit = existing != null;
  final idController = TextEditingController(text: isEdit ? existing['id'] : '');
  final nameController = TextEditingController(text: isEdit ? existing['name'] : '');
  final priceController = TextEditingController(text: isEdit ? existing['price'].toString() : '450');
  final validityController = TextEditingController(text: isEdit ? existing['validity'] : '1 Month');
  final iconController = TextEditingController(text: isEdit ? existing['icon'] : '🎬');
  final descController = TextEditingController(text: isEdit ? existing['description'] : '');

  String category = isEdit ? (existing['category'] ?? 'STREAMING') : 'STREAMING';
  String status = isEdit ? (existing['status'] ?? 'ACTIVE') : 'ACTIVE';

  showDialog(
  context: context,
  builder: (ctx) => StatefulBuilder(
  builder: (ctx, setDialogState) => AlertDialog(
  backgroundColor: AppConstants.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.white12)),
  title: Text(
  isEdit ? "Edit Product: ${existing['name']}" : "Add Digital Shop Product",
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
  ),
  content: Container(
  constraints: const BoxConstraints(maxWidth: 520),
  child: SingleChildScrollView(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  // Icon Field
  SizedBox(
  width: 70,
  child: TextField(
  controller: iconController,
  textAlign: TextAlign.center,
  style: const TextStyle(fontSize: 20),
  decoration: InputDecoration(
  labelText: "ICON",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 10),
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Product Name
  Expanded(
  child: TextField(
  controller: nameController,
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "PRODUCT NAME / TITLE",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "e.g. Netflix UHD 4K (1 Screen)",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  // Category Dropdown
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: category,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "STREAMING", child: Text("🎬 Video Streaming")),
  DropdownMenuItem(value: "AI_TOOLS", child: Text("🤖 AI & Workspaces")),
  DropdownMenuItem(value: "MUSIC", child: Text("🎵 Music & Audio")),
  DropdownMenuItem(value: "GAMING", child: Text("🎮 Gaming & Wallets")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => category = val);
  },
  ),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Duration / Validity
  Expanded(
  child: TextField(
  controller: validityController,
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
  labelText: "DURATION / VALIDITY",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "1 Month / 3 Months",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  Row(
  children: [
  // Price
  Expanded(
  child: TextField(
  controller: priceController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  decoration: InputDecoration(
  labelText: "PRICE (PKR)",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "450",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  prefixText: "₨ ",
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  ),
  ),
  const SizedBox(width: 8),
  // Status
  Expanded(
  child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
  color: AppConstants.surfaceCard,
  borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
  value: status,
  isExpanded: true,
  dropdownColor: AppConstants.surfaceCard,
  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
  items: const [
  DropdownMenuItem(value: "ACTIVE", child: Text("🟢 Active")),
  DropdownMenuItem(value: "DISABLED", child: Text("🔴 Disabled")),
  ],
  onChanged: (val) {
  if (val != null) setDialogState(() => status = val);
  },
  ),
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  // Description
  TextField(
  controller: descController,
  maxLines: 2,
  style: const TextStyle(color: Colors.white, fontSize: 12),
  decoration: InputDecoration(
  labelText: "PRODUCT DESCRIPTION & WARRANTY INFO",
  labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
  hintText: "Private Ultra-HD profile with PIN lock & 30-day replacement warranty.",
  filled: true,
  fillColor: AppConstants.surfaceCard,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
  final name = nameController.text.trim();
  final price = double.tryParse(priceController.text.trim()) ?? 0.0;
  if (name.isEmpty || price <= 0) return;

  Navigator.pop(ctx);

  final prodObj = {
  'id': isEdit ? existing['id'] : 'prod_${DateTime.now().millisecondsSinceEpoch}',
  'name': name,
  'category': category,
  'validity': validityController.text.trim(),
  'price': price,
  'icon': iconController.text.trim().isEmpty ? '🎬' : iconController.text.trim(),
  'description': descController.text.trim(),
  'keys': isEdit ? existing['keys'] : <String>[],
  'status': status,
  };

  final updatedList = List.from(_productsList);
  if (isEdit) {
  final idx = updatedList.indexWhere((x) => x['id'] == existing['id']);
  if (idx != -1) updatedList[idx] = prodObj;
  } else {
  updatedList.add(prodObj);
  }

  await _saveProductsList(updatedList, admin);
  },
  child: const Text("Save Product Live", style: TextStyle(fontWeight: FontWeight.w900)),
  ),
  ],
  ),
  ),
  );
  }

  // Toggle Product Status
  Future<void> _toggleProductStatus(Map<String, dynamic> p, AdminProvider admin) async {
  final currentStatus = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
  final newStatus = currentStatus == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';

  final updatedList = List.from(_productsList);
  final idx = updatedList.indexWhere((x) => x['id'] == p['id']);
  if (idx != -1) {
  updatedList[idx]['status'] = newStatus;
  await _saveProductsList(updatedList, admin);
  }
  }

  // Confirm Delete Product
  void _confirmDeleteProduct(BuildContext context, Map<String, dynamic> p, AdminProvider admin) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  backgroundColor: AppConstants.surface,
  title: const Text("Delete Product?", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.w900)),
  content: Text("Kya aap waqai \"${p['name']}\" aur iske tamam vault keys ko inventory se delete karna chahte hain?", style: const TextStyle(color: AppConstants.textMuted)),
  actions: [
  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
  ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed, foregroundColor: Colors.white),
  onPressed: () async {
  Navigator.pop(ctx);
  final updatedList = List.from(_productsList);
  updatedList.removeWhere((x) => x['id'] == p['id']);
  await _saveProductsList(updatedList, admin);
  },
  child: const Text("Delete"),
  ),
  ],
  ),
  );
  }

  Future<void> _saveProductsList(List updatedList, AdminProvider admin) async {
  setState(() => _isSaving = true);
  try {
  final res = await _api.dio.post(
  '',
  queryParameters: {'action': 'save_config'},
  data: {'digitalShopProducts': updatedList},
  );

  if (res.data['status'] == 'success') {
  setState(() => _productsList = updatedList);
  await admin.fetchAllData();
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  backgroundColor: AppConstants.accentGreen,
  content: Text("✓ Digital Shop inventory synchronized live!", style: TextStyle(color: Color(0xFF021A13), fontWeight: FontWeight.bold)),
  ),
  );
  }
  }
  } catch (_) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(backgroundColor: AppConstants.dangerRed, content: Text("Failed to update shop inventory.")),
  );
  }
  } finally {
  if (mounted) setState(() => _isSaving = false);
  }
  }
}