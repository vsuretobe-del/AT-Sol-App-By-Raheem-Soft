import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Field definition for the generic definition editor.
class DefField {
  final String key;
  final String label;
  final bool isNumber;
  const DefField(this.key, this.label, {this.isNumber = false});
}

/// Configuration for a simple definition module (areas, zones, godowns, …).
class DefConfig {
  final String endpoint;
  final String title;
  final List<DefField> fields;
  /// Which field holds the display name in lists.
  final String nameKey;
  const DefConfig({
    required this.endpoint,
    required this.title,
    required this.fields,
    this.nameKey = 'name',
  });

  static const DefConfig areas = DefConfig(endpoint: AppConfig.epAreas, title: 'Areas', fields: [
    DefField('code', 'Code'),
    DefField('name', 'Name'),
  ]);
  static const DefConfig zones = DefConfig(endpoint: AppConfig.epZones, title: 'Zones', fields: [
    DefField('code', 'Code'),
    DefField('name', 'Name'),
  ]);
  static const DefConfig itemGroups = DefConfig(endpoint: AppConfig.epItemGroups, title: 'Item Groups', fields: [
    DefField('code', 'Code'),
    DefField('name', 'Name'),
  ]);
  static const DefConfig measurements = DefConfig(endpoint: AppConfig.epMeasurements, title: 'Measurements', fields: [
    DefField('code', 'Code'),
    DefField('measure', 'Measurement Name'),
    DefField('unit', 'Unit'),
    DefField('upcs', 'UPCS'),
  ], nameKey: 'measure');
  static const DefConfig godowns = DefConfig(endpoint: AppConfig.epGodowns, title: 'Godowns', fields: [
    DefField('code', 'Code'),
    DefField('name', 'Godown Name'),
    DefField('phone', 'Phone'),
    DefField('address1', 'Address Line 1'),
    DefField('address2', 'Address Line 2'),
  ]);
  static const DefConfig transporters = DefConfig(endpoint: AppConfig.epTransporters, title: 'Transporters', fields: [
    DefField('code', 'Code'),
    DefField('name', 'Transporter Name'),
  ]);
  static const DefConfig saleTypes = DefConfig(endpoint: AppConfig.epSaleTypes, title: 'Sale Types', fields: [
    DefField('code', 'Code'),
    DefField('name', 'Sale Type'),
  ]);
  static const DefConfig bankAccounts = DefConfig(endpoint: AppConfig.epBankAccounts, title: 'Bank Accounts', fields: [
    DefField('code', 'Account Code / No'),
    DefField('name', 'Bank Name'),
  ]);
  static const DefConfig cashAccounts = DefConfig(endpoint: AppConfig.epCashAccounts, title: 'Cash Accounts', fields: [
    DefField('code', 'Account Code'),
    DefField('name', 'Cash Account Name'),
  ]);
}

/// Generic list + add/edit/delete screen for definition modules.
class SimpleDefScreen extends StatefulWidget {
  final DefConfig cfg;
  const SimpleDefScreen({super.key, required this.cfg});
  @override
  State<SimpleDefScreen> createState() => _SimpleDefScreenState();
}

class _SimpleDefScreenState extends State<SimpleDefScreen> {
  List<dynamic> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      items = await ApiService.instance.listAt(widget.cfg.endpoint);
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _openEditor([Map<String, dynamic>? existing]) async {
    final controllers = <String, TextEditingController>{
      for (final f in widget.cfg.fields)
        f.key: TextEditingController(text: '${existing?[f.key] ?? ''}'),
    };
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(existing == null ? 'Add ${widget.cfg.title}' : 'Edit ${widget.cfg.title}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            for (final f in widget.cfg.fields) ...[
              TextFormField(
                controller: controllers[f.key],
                decoration: InputDecoration(labelText: f.label, isDense: true),
                keyboardType: f.isNumber ? TextInputType.number : TextInputType.text,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            FilledButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
              onPressed: () async {
                final body = <String, dynamic>{
                  for (final f in widget.cfg.fields) f.key: controllers[f.key]!.text,
                };
                if (existing != null) body['id'] = existing['id'];
                final r = await ApiService.instance.post(widget.cfg.endpoint, body);
                if (ctx.mounted) {
                  showSnack(ctx, r.ok ? 'Saved' : (r.message ?? 'Save failed'), error: !r.ok);
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

  Future<void> _delete(Map<String, dynamic> item) async {
    if (!await confirmDelete(context, widget.cfg.title.toLowerCase().replaceAll('s', ''))) return;
    final r = await ApiService.instance.delBody(widget.cfg.endpoint, {'id': item['id']});
    if (mounted) {
      showSnack(context, r.ok ? 'Deleted' : (r.message ?? 'Delete failed'), error: !r.ok);
      if (r.ok) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    return Scaffold(
      appBar: AppBar(title: Text(cfg.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AppTheme.brand,
        onRefresh: _load,
        child: loading
            ? ListView(children: const [SizedBox(height: 120), LoadingView()])
            : error != null
                ? ListView(children: [ErrorRetry(message: error!, onRetry: _load)])
                : items.isEmpty
                    ? ListView(children: const [SizedBox(height: 120), EmptyView(message: 'No records yet')])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (c, i) {
                          final it = (items[i] as Map).cast<String, dynamic>();
                          return Card(
                            child: ListTile(
                              onTap: () => _openEditor(it),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.brand.withOpacity(0.1),
                                child: Text('${it['code'] ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.brand, fontWeight: FontWeight.bold)),
                              ),
                              title: Text('${it[cfg.nameKey] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: cfg.fields.length > 2
                                  ? Text(cfg.fields.skip(2).map((f) => '${it[f.key] ?? ''}').where((s) => s.isNotEmpty).join(' • '))
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _delete(it),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
