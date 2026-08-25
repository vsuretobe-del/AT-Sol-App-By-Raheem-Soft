import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/ui.dart';
import 'purchase_form_screen.dart';

enum DocType { purchase, order, purReturn }

extension DocTypeX on DocType {
  String get title => switch (this) {
        DocType.purchase => 'Purchases',
        DocType.order => 'Purchase Orders',
        DocType.purReturn => 'Purchase Returns',
      };
  Future<List<dynamic>> Function() get loader => switch (this) {
        DocType.purchase => ApiService.instance.purchases,
        DocType.order => ApiService.instance.purchaseOrders,
        DocType.purReturn => ApiService.instance.purchaseReturns,
      };
}

/// Unified list screen for Purchases / POs / Purchase Returns.
class DocListScreen extends StatelessWidget {
  final DocType doc;
  const DocListScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    return SearchListScaffold(
      title: doc.title,
      loader: doc.loader,
      itemBuilder: (context, d) {
        return Card(
          child: ListTile(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _DocDetail(doc: (d as Map).cast<String, dynamic>()),
            ),
            title: Text('${d['invoice_no'] ?? ''} • ${d['supplier_name'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Code ${d['code'] ?? '-'} • ${fmtDate(d['date']?.toString())}'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                children: [
              Text('Rs ${fmtMoney(d['net_amount'] ?? d['total_value'])}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade700)),
              if (doc != DocType.purReturn)
                Icon(doc == DocType.order ? Icons.pending_actions : Icons.check_circle_outline,
                    size: 18, color: Colors.grey.shade400),
            ]),
          ),
        );
      },
      fab: doc == DocType.purReturn
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(doc == DocType.purchase ? 'New Purchase' : 'New Order'),
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PurchaseFormScreen(isOrder: doc == DocType.order)));
              },
            ),
    );
  }
}

class _DocDetail extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DocDetail({required this.doc});
  @override
  Widget build(BuildContext context) {
    final items = (doc['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (c, controller) => ListView(controller: controller, padding: const EdgeInsets.all(18), children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Text('Invoice ${doc['invoice_no'] ?? ''}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        kvRow('Supplier', '${doc['supplier_name'] ?? '-'}'),
        kvRow('Date', fmtDate(doc['date']?.toString())),
        kvRow('Total Qty', fmtMoney(doc['total_qty'])),
        kvRow('Total Value', 'Rs ${fmtMoney(doc['total_value'])}'),
        kvRow('Net Amount', 'Rs ${fmtMoney(doc['net_amount'] ?? doc['total_value'])}'),
        const Divider(height: 26),
        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
        ...items.map((it) => Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(padding: const EdgeInsets.all(10), child: kvRow(
                  '${it['item_name'] ?? ''}',
                  'Qty ${fmtMoney(it['qty'])} × ${fmtMoney(it['rate'])} = ${fmtMoney(it['value'])}')),
            )),
      ]),
    );
  }
}
