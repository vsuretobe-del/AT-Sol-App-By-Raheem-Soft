import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

enum PartyKind { customer, supplier, dealer }

extension PartyKindX on PartyKind {
  String get endpoint => switch (this) {
        PartyKind.customer => AppConfig.epCustomers,
        PartyKind.supplier => AppConfig.epSuppliers,
        PartyKind.dealer => AppConfig.epDealers,
      };
  String get title => switch (this) {
        PartyKind.customer => 'Customers',
        PartyKind.supplier => 'Suppliers',
        PartyKind.dealer => 'Dealers',
      };
}

/// Customers / Suppliers / Dealers — list, search and add.
class PartyScreen extends StatefulWidget {
  final PartyKind kind;
  const PartyScreen({super.key, required this.kind});
  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
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
      all = await ApiService.instance.listAt(widget.kind.endpoint);
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
    final code = TextEditingController();
    final abbr = TextEditingController();
    final contact = TextEditingController();
    final phone = TextEditingController();
    final mobile = TextEditingController();
    final address = TextEditingController();
    final credit = TextEditingController();
    bool busy = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text('Add ${widget.kind.title.replaceAll('s', '')}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name *'), readOnly: busy),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(controller: code, decoration: const InputDecoration(labelText: 'Code'), readOnly: busy)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: abbr, decoration: const InputDecoration(labelText: 'Abbr'), readOnly: busy)),
              ]),
              const SizedBox(height: 10),
              TextFormField(controller: contact, decoration: const InputDecoration(labelText: 'Contact Person'), readOnly: busy),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Phone'), readOnly: busy)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: mobile, decoration: const InputDecoration(labelText: 'Mobile'), readOnly: busy)),
              ]),
              const SizedBox(height: 10),
              TextFormField(controller: address, decoration: const InputDecoration(labelText: 'Address'), readOnly: busy),
              const SizedBox(height: 10),
              TextFormField(controller: credit, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Credit Limit'), readOnly: busy),
              const SizedBox(height: 16),
              busy
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                  : FilledButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                      onPressed: () async {
                        if (name.text.trim().isEmpty) {
                          showSnack(ctx, 'Name is required', error: true);
                          return;
                        }
                        setSheet(() => busy = true);
                        final r = await ApiService.instance.post(widget.kind.endpoint, {
                          'name': name.text.trim(),
                          'code': code.text.trim(),
                          'abbr': abbr.text.trim(),
                          'contact_person': contact.text.trim(),
                          'office_phone': phone.text.trim(),
                          'mobile_no': mobile.text.trim(),
                          'office_address1': address.text.trim(),
                          'credit_limit': credit.text.trim(),
                        });
                        setSheet(() => busy = false);
                        if (ctx.mounted) {
                          showSnack(ctx, r.ok ? '${widget.kind.title.replaceAll('s', '')} saved' : (r.message ?? 'Save failed'),
                              error: !r.ok);
                          if (r.ok) Navigator.pop(ctx, true);
                        }
                      },
                    ),
            ]),
          ),
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final entityName = widget.kind.title.replaceAll('s', '');
    if (!await confirmDelete(context, entityName.toLowerCase())) return;
    final r = await ApiService.instance.delBody(widget.kind.endpoint, {'id': p['id']});
    if (mounted) {
      showSnack(context, r.ok ? 'Deleted successfully' : (r.message ?? 'Delete failed'), error: !r.ok);
      if (r.ok) _load();
    }
  }

  Future<void> _openDetail(Map<String, dynamic> p) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(18),
        children: [
          Text('${p['name'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          kvRow('Code', '${p['code'] ?? '-'}'),
          kvRow('Contact', '${p['contact_person'] ?? '-'}'),
          kvRow('Phone', '${p['office_phone'] ?? '-'}'),
          kvRow('Mobile', '${p['mobile_no'] ?? '-'}'),
          kvRow('Address', '${p['office_address1'] ?? '-'}'),
          kvRow('Credit Limit', fmtMoney(p['credit_limit'])),
          if (widget.kind == PartyKind.customer) ...[
            kvRow('Area', '${p['area'] ?? '-'}'),
            kvRow('Zone', '${p['zone'] ?? '-'}'),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.kind.title)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt),
        label: Text('Add ${widget.kind.title.replaceAll('s', '')}'),
        onPressed: _openAdd,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            onChanged: (_) => _apply(),
            decoration: InputDecoration(hintText: 'Search name / code / phone…', prefixIcon: const Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: loading
              ? const LoadingView()
              : shown.isEmpty
                  ? const EmptyView(message: 'No records found')
                  : RefreshIndicator(
                      color: AppTheme.brand,
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: shown.length,
                        itemBuilder: (c, i) {
                          final p = (shown[i] as Map).cast<String, dynamic>();
                          return Card(
                            child: ListTile(
                              onTap: () => _openDetail(p),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.brand.withOpacity(0.1),
                                child: Text(
                                  ('${p['name'] ?? '?'}').isEmpty ? '?' : '${p['name']}'.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text('${p['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text([
                                if ('${p['code'] ?? ''}'.isNotEmpty) 'Code ${p['code']}',
                                if ('${p['mobile_no'] ?? ''}'.isNotEmpty) '${p['mobile_no']}',
                              ].join('  •  ')),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _delete(p),
                              ),
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
