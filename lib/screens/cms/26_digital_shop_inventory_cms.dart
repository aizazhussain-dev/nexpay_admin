import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_image_picker.dart';
import '../../widgets/nexpay_ui_kit.dart';

class DigitalShopInventoryCmsScreen extends StatefulWidget {
  const DigitalShopInventoryCmsScreen({super.key});

  @override
  State<DigitalShopInventoryCmsScreen> createState() => _DigitalShopInventoryCmsScreenState();
}

class _DigitalShopInventoryCmsScreenState extends State<DigitalShopInventoryCmsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _list(AdminProvider admin) {
    final raw = admin.cmsConfig['digitalShopProducts'];
    return raw is List ? raw.whereType().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final items = _list(admin);
    final filtered = items.where((p) {
      final st = (p['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_filter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_filter == 'DISABLED' && st == 'ACTIVE') return false;
      if (_query.isEmpty) return true;
      return '${p['name']} ${p['category']}'.toLowerCase().contains(_query);
    }).toList();

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Digital Shop Inventory & Instant PIN Vault',
        subtitle: 'Manage Netflix, ChatGPT, Spotify, and Gaming gift cards with gallery product images and PIN stock',
        badgeText: '${items.length} PRODUCTS',
        badgeColor: AppConstants.accentGold,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openDrawer(context, admin, items, null),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
            label: const Text('Add Digital Product'),
          ),
        ],
      ),
      filterBar: NexPayFilterBar(
        searchController: _searchCtrl,
        searchHint: 'Search digital product or category...',
        onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        filters: const ['ALL', 'ACTIVE', 'DISABLED'],
        selectedFilter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        resultSummary: 'Showing ${filtered.length} of ${items.length} products',
      ),
      body: NexPayFullWidthTable(
        minTableWidth: 1120,
        emptyState: const InstitutionalEmptyState(
          icon: Icons.vpn_key_rounded,
          title: 'No Digital Shop Products Configured',
          subtitle: 'Click "Add Digital Product" above to add subscriptions, gaming cards, and instant PIN codes.',
        ),
        columns: const [
          DataColumn(label: Text('IMAGE / ICON')),
          DataColumn(label: Text('PRODUCT NAME')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('VALIDITY')),
          DataColumn(label: Text('PRICE (PKR)'), numeric: true),
          DataColumn(label: Text('PIN STOCK')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CONTROLS')),
        ],
        rows: filtered.map((p) {
          final iconVal = (p['icon'] ?? '??').toString();
          final isImg = iconVal.startsWith('data:image') || iconVal.startsWith('http');
          final keys = (p['keys'] is List) ? (p['keys'] as List) : [];
          return DataRow(
            cells: [
              DataCell(
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppConstants.surfaceCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppConstants.borderColor)),
                  child: isImg ? ClipRRect(borderRadius: BorderRadius.circular(7), child: NexPaySmartImage(source: iconVal, fit: BoxFit.cover)) : Text(iconVal, style: const TextStyle(fontSize: 18)),
                ),
              ),
              DataCell(Text((p['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text((p['category'] ?? 'Subscriptions').toString())),
              DataCell(Text((p['validity'] ?? '1 Month').toString())),
              DataCell(Text('Rs. ${p['price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGreen))),
              DataCell(Text('${keys.length} Keys', style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGold))),
              DataCell(NexPayStatusBadge(status: (p['status'] ?? 'ACTIVE').toString())),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(onPressed: () => _openDrawer(context, admin, items, p), child: const Text('Edit & Keys')),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.dangerRed, size: 19),
                      onPressed: () async {
                        final updated = items.where((x) => x['id'] != p['id']).toList();
                        await admin.saveCmsConfig({'digitalShopProducts': updated});
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openDrawer(BuildContext context, AdminProvider admin, List items, Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: (existing?['name'] ?? '').toString());
    final catCtrl = TextEditingController(text: (existing?['category'] ?? 'Subscriptions').toString());
    final validCtrl = TextEditingController(text: (existing?['validity'] ?? '1 Month').toString());
    final priceCtrl = TextEditingController(text: (existing?['price'] ?? '').toString());
    final descCtrl = TextEditingController(text: (existing?['description'] ?? '').toString());
    final existingKeys = (existing?['keys'] is List) ? (existing!['keys'] as List).join('\n') : '';
    final keysCtrl = TextEditingController(text: existingKeys);
    String iconVal = (existing?['icon'] ?? '??').toString();
    bool active = existing == null || (existing['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

    showNexPayInspectorDrawer(
      context: context,
      width: 560,
      title: isEdit ? 'Edit Product: ${nameCtrl.text}' : 'Add Digital Shop Product',
      subtitle: 'Upload product artwork from gallery and manage instant voucher PIN keys',
      child: StatefulBuilder(
        builder: (ctx, setS) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NexPayImageUploader(
              label: 'Product Card Artwork (Upload From Gallery - Optional)',
              initialValue: (iconVal.startsWith('data:image') || iconVal.startsWith('http')) ? iconVal : '',
              previewHeight: 120,
              onChanged: (v) => iconVal = v.isEmpty ? '??' : v,
            ),
            const SizedBox(height: 14),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name (e.g. Netflix 4K UHD, PUBG 660 UC)')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: validCtrl, decoration: const InputDecoration(labelText: 'Validity'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (PKR)', prefixText: 'Rs. '))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Short Product Description')),
            const SizedBox(height: 12),
            TextField(
              controller: keysCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Instant Voucher PINs / Codes (One Key Per Line)'),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Product Visible in Digital Shop', style: TextStyle(fontWeight: FontWeight.w600)),
              value: active,
              activeThumbColor: AppConstants.accentGreen,
              onChanged: (v) => setS(() => active = v),
            ),
          ],
        ),
      ),
      footerActions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            Navigator.pop(context);
            final keyList = keysCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            final obj = {
              'id': isEdit ? existing['id'] : 'prod_${DateTime.now().millisecondsSinceEpoch}',
              'name': nameCtrl.text.trim(),
              'category': catCtrl.text.trim(),
              'validity': validCtrl.text.trim(),
              'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
              'description': descCtrl.text.trim(),
              'icon': iconVal,
              'keys': keyList,
              'status': active ? 'ACTIVE' : 'DISABLED',
            };
            final updated = List.from(items);
            if (isEdit) {
              final idx = updated.indexWhere((x) => x['id'] == existing['id']);
              if (idx != -1) updated[idx] = obj;
            } else {
              updated.add(obj);
            }
            await admin.saveCmsConfig({'digitalShopProducts': updated});
          },
          child: const Text('Save Product'),
        ),
      ],
    );
  }
}