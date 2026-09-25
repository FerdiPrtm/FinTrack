import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';
import 'theme.dart';

int _sum(List<Transaction> tx, String type) =>
    tx.where((t) => t.type == type).fold(0, (s, t) => s + t.amount);

List<Transaction> filterTransactions(
  List<Transaction> tx, {
  DateTime? from,
  DateTime? to,
}) =>
    tx.where((t) {
      final d = DateTime.parse(t.date);
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      return true;
    }).toList();

String _csv(String s) =>
    (s.contains(',') || s.contains('"') || s.contains('\n')) ? '"${s.replaceAll('"', '""')}"' : s;

String csvReport({
  required String walletName,
  required List<Transaction> transactions,
  required List<Category> categories,
  String periodLabel = 'semua transaksi',
}) {
  final catById = {for (final c in categories) c.id: c.name};
  final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
  final income = _sum(transactions, 'income');
  final expense = _sum(transactions, 'expense');
  final buf = StringBuffer('\uFEFF');
  buf.writeln('Laporan Keuangan $walletName ($periodLabel)');
  buf.writeln('Total Masuk,$income');
  buf.writeln('Total Keluar,$expense');
  buf.writeln('Saldo,${income - expense}');
  buf.writeln('Tanggal,Jenis,Kategori,Nominal,Catatan');
  for (final t in sorted) {
    buf.writeln([
      t.date,
      t.type == 'income' ? 'Masuk' : 'Keluar',
      _csv(catById[t.categoryId] ?? '-'),
      t.amount,
      _csv(t.note),
    ].join(','));
  }
  return buf.toString();
}

Future<Uint8List> pdfReport({
  required String walletName,
  required List<Transaction> transactions,
  required List<Category> categories,
  String periodLabel = 'semua transaksi',
}) {
  final catById = {for (final c in categories) c.id: c.name};
  final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
  final income = _sum(transactions, 'income');
  final expense = _sum(transactions, 'expense');
  final balance = income - expense;

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Laporan Keuangan', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Dompet: $walletName', style: const pw.TextStyle(fontSize: 12)),
          pw.Text('Periode: $periodLabel', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 12),
          pw.Text('Total Masuk: +Rp ${formatThousands(income)}', style: pw.TextStyle(fontSize: 11, color: PdfColors.green700)),
          pw.Text('Total Keluar: -Rp ${formatThousands(expense)}', style: pw.TextStyle(fontSize: 11, color: PdfColors.red700)),
          pw.Text(
            'Saldo: ${balance >= 0 ? '+' : '-'}Rp ${formatThousands(balance)}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: balance >= 0 ? PdfColors.green700 : PdfColors.red700,
            ),
          ),
          pw.SizedBox(height: 16),
          if (sorted.isEmpty)
            pw.Text('Belum ada transaksi.', style: pw.TextStyle(fontSize: 11))
          else
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2.2),
                4: const pw.FlexColumnWidth(3.6),
              },
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  children: [
                    for (final h in const ['Tanggal', 'Jenis', 'Kategori', 'Nominal', 'Catatan'])
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                  ],
                ),
                for (final t in sorted)
                  pw.TableRow(
                    children: [
                      _cell(t.date),
                      _cell(t.type == 'income' ? 'Masuk' : 'Keluar'),
                      _cell(catById[t.categoryId] ?? '-'),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            '${t.type == 'income' ? '+' : '-'}Rp ${formatThousands(t.amount)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: t.type == 'income' ? PdfColors.green700 : PdfColors.red700,
                            ),
                          ),
                        ),
                      ),
                      _cell(t.note),
                    ],
                  ),
              ],
            ),
        ],
      ),
    ),
  );
  return doc.save();
}

pw.Widget _cell(String s) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(s, style: const pw.TextStyle(fontSize: 9)),
    );