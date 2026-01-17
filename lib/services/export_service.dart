import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tabs/models/models.dart';
import 'package:universal_html/html.dart' as html;

class ExportService {
  /// Export expenses to CSV
  Future<void> exportToCsv({
    required ExpenseGroup group,
    required List<Expense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final rows = <List<dynamic>>[];

    // Header
    rows.add([
      'Date',
      'Title',
      'Category',
      'Paid By',
      'Amount',
      'Currency',
      'Converted Amount (${group.currency})',
      'Notes',
    ]);

    // Data
    for (final expense in expenses) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.title,
        expense.category ?? 'Uncategorized',
        group.members[expense.paidBy]?.displayName ?? 'Unknown',
        expense.amount.toStringAsFixed(2),
        expense.currency,
        expense.convertedAmount.toStringAsFixed(2),
        expense.notes ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    final filename = 'expenses_${group.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(startDate)}-${DateFormat('yyyyMMdd').format(endDate)}.csv';

    if (kIsWeb) {
      // Web Download
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile Share
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvString);
      await Share.shareXFiles([XFile(file.path)], text: 'Expenses for ${group.name}');
    }
  }

  /// Export expenses to PDF
  Future<void> exportToPdf({
    required ExpenseGroup group,
    required List<Expense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    // Sort expenses by date
    expenses.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals
    final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.convertedAmount);
    final categoryTotals = <String, double>{};
    for (final e in expenses) {
      final cat = e.category ?? 'Uncategorized';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + e.convertedAmount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(group, startDate, endDate),
          pw.SizedBox(height: 20),
          _buildSummary(group, totalSpent, categoryTotals),
          pw.SizedBox(height: 20),
          _buildExpenseTable(group, expenses),
        ],
      ),
    );

    final bytes = await pdf.save();
    final filename = 'report_${group.name.replaceAll(' ', '_')}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  pw.Widget _buildHeader(ExpenseGroup group, DateTime start, DateTime end) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          group.name,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Expense Report',
          style: const pw.TextStyle(fontSize: 18),
        ),
        pw.Text(
          '${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}',
          style: const pw.TextStyle(color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildSummary(ExpenseGroup group, double total, Map<String, double> categoryTotals) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Spent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                '${group.currency} ${total.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          ...categoryTotals.entries.map((e) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(e.key),
                pw.Text(e.value.toStringAsFixed(2)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  pw.Widget _buildExpenseTable(ExpenseGroup group, List<Expense> expenses) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Title', 'Category', 'Paid By', 'Amount'],
      data: expenses.map((e) => [
        DateFormat('MMM d').format(e.date),
        e.title,
        e.category ?? '-',
        group.members[e.paidBy]?.displayName ?? '?',
        '${e.currency} ${e.amount.toStringAsFixed(2)}',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue600),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }
}
