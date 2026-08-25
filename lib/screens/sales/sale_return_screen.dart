import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/ui.dart';
import 'sale_form_screen.dart';

class SaleReturnScreen extends StatelessWidget {
  const SaleReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchListScaffold(
      title: 'Sales Returns',
      loader: ApiService.instance.saleReturns,
      itemBuilder: (context, r) {
        final items = (r['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        return Card(
          child: ListTile(
            onTap: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => Padding(
                padding: const EdgeInsets.all(18),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Return ${r['code'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  kvRow('Date', fmtDate(r['date']?.toString())),
                  kvRow('Party', '${r['party_name'] ?? '-'}'),
                  kvRow('Total Qty', fmtMoney(r['total_qty'])),
                  kvRow('Net Amount', 'Rs ${fmtMoney(r['net_amount'])}'),
                  if (items.isNotEmpty) ...[
                    const Divider(height: 20),
                    ...items.map((it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text('${it['item_code'] ?? it['description'] ?? ''}')),
                            Text('Qty ${fmtMoney(it['qty'])}'),
                          ]),
                        )),
                  ],
                ]),
              ),
            ),
            title: Text('${r['invoice_no'] ?? r['code'] ?? ''} • ${r['party_name'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${fmtDate(r['date']?.toString())} • Qty ${fmtMoney(r['total_qty'])}'),
            trailing: Text('Rs ${fmtMoney(r['net_amount'])}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
          ),
        );
      },
      fab: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Return'),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SaleFormScreen(isReturn: true)));
        },
      ),
    );
  }
}
