import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Create a Purchase (or Purchase Order when [isOrder] is true).
class PurchaseFormScreen extends StatefulWidget {
  final bool isOrder;
  const PurchaseFormScreen({super.key, this.isOrder = false});
  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurItemRow {
  TextEditingController item = TextEditingController();
  TextEditingController qty = TextEditingController(text: '0');
  TextEditingController rate = TextEditingController(text: '0');
  TextEditingController value = TextEditingController(text: '0');
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _invoice = TextEditingController();
  final _supplier = TextEditingController();
  final _transporter = TextEditingController();
  final _net = TextEditingController(text: '0');
  DateTime _date = DateTime.now();

  List<dynamic> suppliers = [];
  List<dynamic> transporters = [];
  List<dynamic> itemsMaster = [];
  List<_PurItemRow> _rows = [_PurItemRow()];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  Future<void> _loadMasters() async {
    suppliers = await ApiService.instance.listAt(AppConfig.epSuppliers);
    transporters = await ApiService.instance.listAt(AppConfig.epTransporters);
    itemsMaster = await ApiService.instance.listAt(AppConfig.epItems);
    if (widget.isOrder) {
      _code.text = ApiService.nextCodeFrom(await ApiService.instance.purchaseOrders());
    } else {
      _code.text = ApiService.nextCodeFrom(await ApiService.instance.purchases());
    }
    if (mounted) setState(() {});
  }

  void _recalc(_PurItemRow r) {
    final q = double.tryParse(r.qty.text) ?? 0;
    final p = double.tryParse(r.rate.text) ?? 0;
    setState(() => r.value.text = (q * p).toStringAsFixed(2));
    double net = 0;
    for (final row in _rows) net += double.tryParse(row.value.text) ?? 0;
    _net.text = net.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final body = <String, dynamic>{
      'code': _code.text,
      'date': '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      'invoice_no': _invoice.text,
      'supplier_name': _supplier.text,
      'transporter': _transporter.text,
      'total_qty': _rows.fold<double>(0, (s, r) => s + (double.tryParse(r.qty.text) ?? 0)),
      'total_value': _rows.fold<double>(0, (s, r) => s + (double.tryParse(r.value.text) ?? 0)),
      'net_amount': _net.text,
      'items': _rows
          .map((r) => {'item_name': r.item.text, 'qty': r.qty.text, 'rate': r.rate.text, 'value': r.value.text})
          .toList(),
    };
    final r = widget.isOrder
        ? await ApiService.instance.savePurchaseOrder(body)
        : await ApiService.instance.savePurchase(body);
    if (!mounted) return;
    setState(() => _busy = false);
    showSnack(context, r.ok ? 'Saved successfully' : (r.message ?? 'Save failed'), error: !r.ok);
    if (r.ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isOrder ? 'New Purchase Order' : 'New Purchase')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _busy
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
              : FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(widget.isOrder ? 'Save Order' : 'Save Purchase')),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(12), children: [
          TextFormField(controller: _code, decoration: const InputDecoration(labelText: 'Code')),
          const SizedBox(height: 10),
          TextFormField(controller: _invoice, decoration: const InputDecoration(labelText: 'Invoice No')),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today, size: 18)),
              child: Text(fmtDate(_date.toIso8601String())),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: suppliers.any((su) => '${su['name']}' == _supplier.text) && _supplier.text.isNotEmpty
                ? _supplier.text
                : null,
            decoration: const InputDecoration(labelText: 'Supplier', prefixIcon: Icon(Icons.local_shipping)),
            isExpanded: true,
            items: [
              for (final su in suppliers)
                DropdownMenuItem(value: '${su['name']}', child: Text('${su['name']}', overflow: TextOverflow.ellipsis))
            ],
            onChanged: (v) => setState(() => _supplier.text = v ?? ''),
            validator: (v) => (v == null || v.isEmpty) ? 'Select supplier' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _transporter.text.isNotEmpty && transporters.any((t) => '${t['name']}' == _transporter.text)
                ? _transporter.text
                : (_transporter.text.isEmpty ? '' : null),
            decoration: const InputDecoration(labelText: 'Transporter', prefixIcon: Icon(Icons.local_taxi)),
            isExpanded: true,
            items: [const DropdownMenuItem(value: '', child: Text('-'))] +
                [for (final t in transporters) DropdownMenuItem(value: '${t['name']}', child: Text('${t['name']}'))],
            onChanged: (v) => setState(() => _transporter.text = v ?? ''),
          ),
          SectionHeader('Items'),
          ..._buildItemRows(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _rows.add(_PurItemRow())),
            icon: const Icon(Icons.add),
            label: const Text('Add Item Row'),
          ),
          const SizedBox(height: 14),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Rs ${fmtMoney(_net.text)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange.shade700)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildItemRows() {
    final out = <Widget>[];
    for (int i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      out.add(Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Expanded(child: Autocomplete<String>(
                initialValue: TextEditingValue(text: r.item.text),
                optionsBuilder: (v) => itemsMaster
                    .map((m) => '${m['item_name'] ?? m['description'] ?? ''}')
                    .where((n) => n.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (sel) => r.item.text = sel,
                fieldViewBuilder: (c, ctl, focus, submit) => TextFormField(
                  controller: ctl,
                  focusNode: focus,
                  decoration: InputDecoration(labelText: 'Item ${i + 1}'),
                  onChanged: (_) => r.item.text = ctl.text,
                ),
              )),
              IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.danger), onPressed: () {
                setState(() {
                  if (_rows.length > 1) _rows.removeAt(i);
                });
              }),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(
                controller: r.qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty'),
                onChanged: (_) => _recalc(r),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                controller: r.rate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rate'),
                onChanged: (_) => _recalc(r),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                controller: r.value,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Value'),
              )),
            ]),
          ]),
        ),
      ));
    }
    return out;
  }
}
