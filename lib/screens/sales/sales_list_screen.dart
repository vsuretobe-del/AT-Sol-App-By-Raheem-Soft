import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/ui.dart';
import 'sale_form_screen.dart';

/// Sales invoices list (Sales View).
class SalesListScreen extends StatelessWidget {
  const SalesListScreen({super.key});

  Future<void> _openDetail(BuildContext context, Map<String, dynamic> sale) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SaleDetailSheet(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SearchListScaffold(
      title: 'Sales Invoices',
      loader: ApiService.instance.sales,
      itemBuilder: (context, s) {
        final net = double.tryParse('${s['net_amount'] ?? 0}'.replaceAll(',', '')) ?? 0;
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () => _openDetail(context, s),
            title: Text('${s['invoice_no'] ?? ''} • ${s['supplier_name'] ?? s['party_name'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Code ${s['code'] ?? '-'} • ${fmtDate(s['date'])}'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                children: [
              Text('Rs ${fmtMoney(net)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () async {
                  if (!await confirmDelete(context, 'invoice')) return;
                  final r = await ApiService.instance.deleteSale(int.parse('${s['id']}'));
                  if (context.mounted) showSnack(context, r.message ?? (r.ok ? 'Deleted' : 'Delete failed'), error: !r.ok);
                },
              ),
            ]),
          ),
        );
      },
      fab: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleFormScreen()));
        },
      ),
    );
  }
}

class _SaleDetailSheet extends StatelessWidget {
  final Map<String, dynamic> sale;
  const _SaleDetailSheet({required this.sale});
  @override
  Widget build(BuildContext context) {
    final items = (sale['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (c, controller) => Container(
        padding: const EdgeInsets.all(18),
        child: ListView(controller: controller, children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Text('Invoice ${sale['invoice_no'] ?? ''}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          kvRow('Code', '${sale['code'] ?? '-'}'),
          kvRow('Date', fmtDate(sale['date']?.toString())),
          kvRow('Customer', '${sale['supplier_name'] ?? sale['party_name'] ?? '-'}'),
          kvRow('Total Qty', fmtMoney(sale['total_qty'])),
          kvRow('Total Value', 'Rs ${fmtMoney(sale['total_value'])}'),
          kvRow('Net Amount', 'Rs ${fmtMoney(sale['net_amount'])}'),
          const Divider(height: 26),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
          ...items.map((it) => Card(
                margin: const EdgeInsets.only(top: 8),
                child: Padding(padding: const EdgeInsets.all(10), child: kvRow(
                    '${it['item_code'] ?? it['item_name'] ?? ''}',
                    'Qty ${fmtMoney(it['qty'])} × ${fmtMoney(it['purchase_price'] ?? it['rate'])} = ${fmtMoney(it['value'])}')),
              )),
        ]),
      ),
    );
  }
}
