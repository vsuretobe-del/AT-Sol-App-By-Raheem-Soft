import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Items master — list, search, add.
class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<dynamic> all = [];
  List<dynamic> shown = [];
  bool loading = true;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      all = await ApiService.instance.listAt(AppConfig.epItems);
      _apply();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  void _apply() {
    Iterable<dynamic> it = all;
    final q = search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      it = it.where((row) =>
          row is Map<String, dynamic> && row.values.any((v) => '$v'.toLowerCase().contains(q)));
    }
    setState(() => shown = it.toList());
  }

  Future<void> _openAdd() async {
    final name = TextEditingController();
    final company = TextEditingController();
    final desc = TextEditingController();
    final rate = TextEditingController();
    final packQty = TextEditingController();
    final unit = TextEditingController();
    final group = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            const Text('Add Item', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Item Name *')),
            const SizedBox(height: 10),
            TextFormField(controller: company, decoration: const InputDecoration(labelText: 'Company / Brand')),
            const SizedBox(height: 10),
            TextFormField(controller: desc, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(
                  controller: rate, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                  controller: packQty, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pack Qty'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'Unit'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: group, decoration: const InputDecoration(labelText: 'Item Group'))),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Item'),
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  showSnack(ctx, 'Item name is required', error: true);
                  return;
                }
                final r = await ApiService.instance.post(AppConfig.epItems, {
                  'item_name': name.text.trim(),
                  'item_company': company.text.trim(),
                  'description': desc.text.trim(),
                  'rate': rate.text.trim(),
                  'pack_qty': packQty.text.trim(),
                  'unit': unit.text.trim(),
                  'item_group': group.text.trim(),
                });
                if (ctx.mounted) {
                  showSnack(ctx, r.ok ? 'Item saved' : (r.message ?? 'Save failed'), error: !r.ok);
                  if (r.ok) Navigator.pop(ctx, true);
                }
              },
            ),
          ]),
        ),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        onPressed: _openAdd,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            onChanged: (_) => _apply(),
            decoration: const InputDecoration(hintText: 'Search items…', prefixIcon: Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: loading
              ? const LoadingView()
              : shown.isEmpty
                  ? const EmptyView(message: 'No items found', icon: Icons.inventory_2)
                  : RefreshIndicator(
                      color: AppTheme.brand,
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: shown.length,
                        itemBuilder: (c, i) {
                          final p = (shown[i] as Map).cast<String, dynamic>();
                          final stockHint = '${p['pack_qty'] ?? ''}'.isNotEmpty ? 'Pack ${p['pack_qty']} ${p['unit'] ?? ''}' : '';
                          return Card(
                            child: ListTile(
                              title: Text('${p['item_name'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text([
                                if ('${p['item_company'] ?? ''}'.isNotEmpty) '${p['item_company']}',
                                if ('${p['item_group'] ?? ''}'.isNotEmpty) '${p['item_group']}',
                                stockHint,
                              ].where((s) => s.isNotEmpty).join('  •  ')),
                              trailing: Text('Rs ${fmtMoney(p['rate'])}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
