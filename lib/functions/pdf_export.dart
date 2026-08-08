import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateTransactionsPDF(List<TransactionWithCategory> transactions, String title, AllWallets allWallets) async {
  final pdf = pw.Document();

  // Sort transactions by date descending
  transactions.sort((a, b) => b.transaction.dateCreated.compareTo(a.transaction.dateCreated));

  // Calculate totals
  double totalIncome = 0;
  double totalExpense = 0;
  for (var item in transactions) {
    if (item.transaction.amount > 0) {
      totalIncome += item.transaction.amount;
    } else {
      totalExpense += item.transaction.amount;
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                ),
                pw.Text(
                  "Xpenzi Report",
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.grey600),
                ),
              ],
            )
          ),
          pw.SizedBox(height: 20),
          
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryBox("Total Income", totalIncome, PdfColors.green700, allWallets),
                _buildSummaryBox("Total Expenses", totalExpense.abs(), PdfColors.red700, allWallets),
                _buildSummaryBox("Net", totalIncome + totalExpense, PdfColors.blue700, allWallets),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Category', 'Title', 'Note', 'Amount'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
            data: transactions.map((item) {
              return [
                "${item.transaction.dateCreated.year}-${item.transaction.dateCreated.month.toString().padLeft(2, '0')}-${item.transaction.dateCreated.day.toString().padLeft(2, '0')}",
                item.category.name,
                item.transaction.name,
                item.transaction.note,
                convertToMoney(allWallets, item.transaction.amount),
              ];
            }).toList(),
          ),
        ];
      },
    ),
  );

  await Printing.sharePdf(bytes: await pdf.save(), filename: 'Xpenzi_Report.pdf');
}

pw.Widget _buildSummaryBox(String title, double amount, PdfColor color, AllWallets allWallets) {
  return pw.Column(
    children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
      pw.SizedBox(height: 4),
      pw.Text(
        convertToMoney(allWallets, amount),
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
      ),
    ],
  );
}
