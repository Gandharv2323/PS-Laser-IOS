/// PDF Order Docket generator — Phase 4.
/// Produces a professional A4 docket for any Order.
library;

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';

class PdfService {
  PdfService._();

  /// Generate a professional order docket PDF.
  static Future<Uint8List> generateOrderDocket(Order order) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      ),
    );

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final dateOnly = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              _buildHeader(),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 16),

              // ── Order ID + Status ────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ORDER DOCKET',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          )),
                      pw.SizedBox(height: 4),
                      pw.Text('ID: ${order.id}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                            font: pw.Font.courier(),
                          )),
                    ],
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              pw.SizedBox(height: 20),

              // ── Client & Priority ────────────────────────────────────
              _buildInfoTable([
                ['Client', order.clientName],
                ['Priority', order.priority.toUpperCase()],
                ['Created', dateFormat.format(order.createdAt)],
                if (order.dueDate != null)
                  ['Due Date', dateOnly.format(order.dueDate!)],
              ]),
              pw.SizedBox(height: 16),

              // ── Description ──────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DESCRIPTION',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                          letterSpacing: 1.0,
                        )),
                    pw.SizedBox(height: 6),
                    pw.Text(order.description,
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ── Material & Quantity ──────────────────────────────────
              _buildInfoTable([
                ['Material', order.material.isNotEmpty ? order.material : '—'],
                ['Quantity', order.quantity > 0 ? '${order.quantity} ${order.unit}' : '—'],
                [
                  'Est. Duration',
                  order.estimatedDurationMins > 0
                      ? '${order.estimatedDurationMins} mins'
                      : '—'
                ],
              ]),
              pw.SizedBox(height: 16),

              // ── Notes ────────────────────────────────────────────────
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('NOTES',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                            letterSpacing: 1.0,
                          )),
                      pw.SizedBox(height: 6),
                      pw.Text(order.notes!,
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              pw.Spacer(),

              // ── Footer ──────────────────────────────────────────────
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated: ${dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    'PS Laser Industries — Confidential',
                    style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                        fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PS LASER',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                  letterSpacing: 2.0,
                )),
            pw.Text('INDUSTRIES',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  letterSpacing: 4.0,
                )),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Manufacturing Operations',
                style: pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
            pw.Text('Order Management System',
                style: pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  // ── Status badge ───────────────────────────────────────────────────────────

  static pw.Widget _buildStatusBadge(String status) {
    PdfColor bg;
    PdfColor fg;
    switch (status) {
      case 'RECEIVED':
        bg = PdfColors.blue50;
        fg = PdfColors.blue800;
      case 'SCHEDULED':
        bg = PdfColors.cyan50;
        fg = PdfColors.cyan800;
      case 'IN_PROGRESS':
        bg = PdfColors.amber50;
        fg = PdfColors.amber800;
      case 'QUALITY_CHECK':
        bg = PdfColors.purple50;
        fg = PdfColors.purple800;
      case 'COMPLETED':
        bg = PdfColors.green50;
        fg = PdfColors.green800;
      case 'DELIVERED':
        bg = PdfColors.teal50;
        fg = PdfColors.teal800;
      default:
        bg = PdfColors.grey200;
        fg = PdfColors.grey800;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        status.replaceAll('_', ' '),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // ── Info table ─────────────────────────────────────────────────────────────

  static pw.Widget _buildInfoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.grey50,
              child: pw.Text(row[0],
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  )),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(row[1],
                  style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        );
      }).toList(),
    );
  }
}
