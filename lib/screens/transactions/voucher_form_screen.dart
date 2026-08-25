import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class _VoucherEntry {
  TextEditingController account = TextEditingController();
  TextEditingController dr = TextEditingController(text: '0');
  TextEditingController cr = TextEditingController(text: '0');
}

/// Create a new accounting voucher (double entry).
class VoucherFormScreen extends StatefulWidget {
  const VoucherFormScreen({super.key});
  @override
  State<VoucherFormScreen> createState() => _VoucherFormScreenState();
}

class _VoucherFormScreenState extends State<VoucherFormScreen> {
  static const voucherTypes = [
    'Journal General',
    'Cash Payment',
    'Cash Receipt',
    'Bank Payment',
    'Bank Receipt',
  ];

  final _form = GlobalKey<FormState>();
  String _type = voucherTypes.first;
  final _voucherNo = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now();
  List<_VoucherEntry> entries = [_VoucherEntry(), _VoucherEntry()];
  List<dynamic> accounts = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final r = await ApiService.instance.get(AppConfig.epReportAccounting, {'type': 'accounts_list'});
    if (r.ok && r.data is List) accounts = r.data as List;
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => _date = d);
  }

  double get totalDr => entries.fold<double>(0, (s, e) => s + (double.tryParse(e.dr.text) ?? 0));
  double get totalCr => entries.fold<double>(0, (s, e) => s + (double.tryParse(e.cr.text) ?? 0));
  bool get balanced => totalDr > 0 && (totalDr - totalCr).abs() < 0.01;

  String _codeFor(String name) {
    for (final a in accounts) {
      if ('${a['account_name']}' == name) return '${a['account_code'] ?? ''}';
    }
    return '';
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!balanced) {
      showSnack(context, 'Debit and Credit totals must be equal', error: true);
      return;
    }
    setState(() => _busy = true);
    final r = await ApiService.instance.saveTransaction({
      'voucher_no': _voucherNo.text,
      'date': '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      'type': _type,
      'description': _description.text,
      'total_dr': totalDr,
      'total_cr': totalCr,
      'items': [
        for (final e in entries)
          {
            'account_code': _codeFor(e.account.text),
            'account_name': e.account.text,
            'amount_dr': e.dr.text,
            'amount_cr': e.cr.text,
          }
      ],
    });
    if (!mounted) return;
    setState(() => _busy = false);
    showSnack(context, r.ok ? 'Voucher saved' : (r.message ?? 'Save failed'), error: !r.ok);
    if (r.ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Voucher')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Text('Dr: ${fmtMoney(totalDr)}', style: TextStyle(fontWeight: FontWeight.bold,
                  color: balanced ? Colors.green.shade700 : AppTheme.danger)),
              Text('Cr: ${fmtMoney(totalCr)}', style: TextStyle(fontWeight: FontWeight.bold,
                  color: balanced ? Colors.green.shade700 : AppTheme.danger)),
            ]),
            const SizedBox(height: 8),
            _busy
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                : FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Voucher')),
          ]),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(12), children: [
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Voucher Type', prefixIcon: Icon(Icons.receipt)),
            items: [for (final t in voucherTypes) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _voucherNo, decoration: const InputDecoration(labelText: 'Voucher No'))),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(fmtDate(_date.toIso8601String())),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description / Narration')),
          SectionHeader('Entries'),
          ..._buildEntries(),
          OutlinedButton.icon(
            onPressed: () => setState(() => entries.add(_VoucherEntry())),
            icon: const Icon(Icons.add),
            label: const Text('Add Entry Line'),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildEntries() {
    final out = <Widget>[];
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      out.add(Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Expanded(child: Autocomplete<String>(
                initialValue: TextEditingValue(text: e.account.text),
                optionsBuilder: (v) => accounts
                    .map((a) => '${a['account_name'] ?? ''}')
                    .where((n) => n.isNotEmpty && n.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (sel) => e.account.text = sel,
                fieldViewBuilder: (c, ctl, focus, submit) => TextFormField(
                  controller: ctl,
                  focusNode: focus,
                  decoration: InputDecoration(labelText: 'Account ${i + 1}'),
                  onChanged: (_) => e.account.text = ctl.text,
                ),
              )),
              IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.danger), onPressed: () {
                setState(() {
                  if (entries.length > 2) entries.removeAt(i);
                });
              }),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(
                controller: e.dr,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Debit (Dr)'),
                onChanged: (_) => setState(() {}),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                controller: e.cr,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Credit (Cr)'),
                onChanged: (_) => setState(() {}),
              )),
            ]),
          ]),
        ),
      ));
    }
    return out;
  }
}
