import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrderReceiptScreen extends StatelessWidget {
  final dynamic order;

  const OrderReceiptScreen({super.key, required this.order});

  Map<String, dynamic> get orderData {
    return order['order'] ??
        order;
  }

  List get items => order['items'] ?? [];
  Map<String, dynamic> get summary => order['summary'] ?? {};

  String get status {
    final s = order['status'] ??
        orderData['status'] ??
        'pending';

    return s.toString();
  }

  Future<void> downloadPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Receipt #${orderData['id'] ?? 'N/A'}",
                style: const pw.TextStyle(fontSize: 20),
              ),

              pw.SizedBox(height: 10),

              pw.Text("Status: $status"),

              pw.Divider(),

              pw.Text("Items:",
                  style: const pw.TextStyle(fontSize: 16)),

              pw.SizedBox(height: 8),

              ...items.map((item) {
                final name = item['product_name'] ??
                    item['name'] ??
                    "Product";

                return pw.Text(
                  "$name - Qty: ${item['quantity']} - \$${item['subtotal']}",
                );
              }),

              pw.Divider(),

              pw.Text(
                "TOTAL: \$${summary['total'] ?? 0}",
                style: const pw.TextStyle(fontSize: 18),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Receipt #${orderData['id'] ?? ''}"),

        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => downloadPdf(context),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Order ID: ${orderData['id'] ?? ''}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 5),

            Text(
              "Status: ${status.toUpperCase()}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const Divider(),

            const Text(
              "Items",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];

                  final name = item['product_name'] ??
                      item['name'] ??
                      "Product";

                  return ListTile(
                    title: Text(name),
                    subtitle: Text(
                      "Qty: ${item['quantity']} × \$${item['price']}",
                    ),
                    trailing: Text(
                      "\$${item['subtotal']}",
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  row("Subtotal", summary['subtotal']),
                  row("Tax", summary['tax']),
                  row("TOTAL", summary['total'], bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget row(String label, dynamic value, {bool bold = false}) {
    final v = (value ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "\$${v.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}