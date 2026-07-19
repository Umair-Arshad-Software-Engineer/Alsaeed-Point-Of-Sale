// lib/services/print_service.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../models/branch_model.dart';

class PrintService {
  // ── Configurable business info ──────────────────────────────────────────────
  static const String _businessName    = 'AL-SAEED\nSWEETS & BAKERS';
  static const String _receiptTitle    = 'Cash Sale';
  static const String _ntn            = 'NTN: 3537483-7';
  static const String _strn           = 'STRN: 3277876143974';
  static const String _thankYou       = 'Thank You';
  static const String _visitAgain     = 'We wish to see you again';
  static const double _posCharges     = 1.00;          // POS fee per transaction
  static const double _gstRate        = 0.18;          // 18 % GST
  // ────────────────────────────────────────────────────────────────────────────

  static Future<void> printReceipt({
    required Sale sale,
    required List<ReceiptItem> cart,
    required String customerName,
    required String customerPhone,
    required String cashierName,
    required String invoiceNo,
    required String fbrInvoiceNumber,
    required double subtotal,
    required double taxAmount,
    required double discount,
    required double total,
    required double amountGiven,
    User? currentUser,
    double posCharges = _posCharges,
  }) async {
    try {
      final pdf = pw.Document();

      // 80-mm thermal roll width (~226 pt usable) with increased padding
      const pageFormat = PdfPageFormat(
        226,          // 80 mm in points ≈ 226.77, round down for safety
        double.infinity,
        marginLeft: 10,   // Increased left padding
        marginRight: 10,  // Increased right padding
        marginTop: 10,    // Increased top padding
        marginBottom: 10, // Increased bottom padding
      );

      final netTotal   = total + posCharges;
      final change     = amountGiven > 0 ? amountGiven - netTotal : 0.0;

      // Get branch details from current user
      final branchAddress = _getBranchAddress(currentUser);
      final branchPhone = _getBranchPhone(currentUser);

      // Debug output
      print('📋 Branch Address: "$branchAddress"');
      print('📋 Branch Phone: "$branchPhone"');
      print('📋 Current User: ${currentUser?.name}');
      print('📋 User Branch: ${currentUser?.branch?.name ?? "none"}');

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // ── Business header ────────────────────────────────────────
                pw.Text(
                  _businessName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _receiptTitle,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 4),

                // ── Branch Address and Phone ──────────────────────────────
                if (branchAddress.isNotEmpty)
                  pw.Text(branchAddress, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
                if (branchPhone.isNotEmpty)
                  pw.Text('Ph: $branchPhone', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),

                pw.SizedBox(height: 2),
                pw.Text(_ntn, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(_strn, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),

                // ── Cashier / Date row ─────────────────────────────────────
                _twoColRow('Cashier:', cashierName,  'Date:', _formatDate(sale.saleDate)),
                pw.SizedBox(height: 2),
                _twoColRow('Invoice No:', invoiceNo, 'Time:', _formatTime(sale.saleDate)),
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Customer: ${customerName.isEmpty ? "" : customerName}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5),

                // ── Items table header ─────────────────────────────────────
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3.0),   // Item (slightly reduced)
                    1: pw.FlexColumnWidth(1.0),   // Qty
                    2: pw.FlexColumnWidth(1.8),   // Rate
                    3: pw.FlexColumnWidth(1.8),   // GST 18%
                    4: pw.FlexColumnWidth(2.8),   // Amount (INCREASED from 2.3 to 2.8)
                  },
                  border: pw.TableBorder.symmetric(
                    inside: pw.BorderSide(width: 0.5, color: PdfColors.grey400),
                  ),
                  children: [
                    // Header row
                    pw.TableRow(
                      children: [
                        _tableCell('Item',     bold: true),
                        _tableCell('Qty',      bold: true, align: pw.TextAlign.center),
                        _tableCell('Rate',     bold: true, align: pw.TextAlign.right),
                        _tableCell('GST', bold: true, align: pw.TextAlign.right),
                        _tableCell('Amount',   bold: true, align: pw.TextAlign.right),
                      ],
                    ),
                    ...cart.map((item) {
                      final rate      = item.productPrice;
                      final gstAmt    = rate * (item.taxPercentage / 100) * item.quantity;
                      final lineTotal = rate * item.quantity + gstAmt;
                      return pw.TableRow(
                        children: [
                          _tableCell(item.productName),
                          _tableCell('${item.quantity}', align: pw.TextAlign.center),
                          _tableCell(_n(rate),           align: pw.TextAlign.right),
                          _tableCell(_n(gstAmt),         align: pw.TextAlign.right),
                          _tableCell(_n(lineTotal),      align: pw.TextAlign.right),
                        ],
                      );
                    }),
                  ],
                ),

                // ── GST subtotal ───────────────────────────────────────────
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total GST:  ${_n(taxAmount)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),

                // ── Cart total line ────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${cart.fold(0, (s, i) => s + i.quantity)}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_n(total), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),

                // ── Financial summary ──────────────────────────────────────
                _summaryRow('POS Charges:', _n(posCharges)),
                _summaryRow('Net:',         _n(netTotal)),
                if (discount > 0) _summaryRow('Discount:', '- ${_n(discount)}'),
                _summaryRow('Advance:', ''),
                _summaryRow('Received:', amountGiven > 0 ? _n(amountGiven) : ''),
                _summaryRow('Card:', ''),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Mode: Cash', style: const pw.TextStyle(fontSize: 9)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Balance:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(_n(change >= 0 ? change : 0),
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 6),

                // ── Footer ─────────────────────────────────────────────────
                pw.Text(_thankYou,   style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(_visitAgain, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),

                // ── FBR section ────────────────────────────────────────────
                if (fbrInvoiceNumber.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 0.5),
                  pw.SizedBox(height: 6),
                  pw.Text('FBR Verified Invoice', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(fbrInvoiceNumber, style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 8),

                  // QR Code — FBR invoice number encode karta hai
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: fbrInvoiceNumber,
                      width: 80,
                      height: 80,
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Barcode (Code128) — already tha, saath rakh lo
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: fbrInvoiceNumber,
                      width: 150,
                      height: 40,
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                ],
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('Print error: $e');
      rethrow;
    }
  }

  // ── Helper methods to get branch details ──────────────────────────────────

  static String _getBranchAddress(User? user) {
    if (user == null) {
      print('⚠️ User is null');
      return '';
    }

    if (user.branch == null) {
      print('⚠️ User has no branch assigned: ${user.name}');
      return '';
    }

    print('✅ Found branch: ${user.branch!.name} - ${user.branch!.address}');
    return user.branch!.address;
  }

  static String _getBranchPhone(User? user) {
    if (user == null) {
      print('⚠️ User is null');
      return '';
    }

    if (user.branch == null) {
      print('⚠️ User has no branch assigned: ${user.name}');
      return '';
    }

    print('✅ Found branch phone: ${user.branch!.phone}');
    return user.branch!.phone;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Two-column meta row: [label1  value1   label2  value2]
  static pw.Widget _twoColRow(
      String l1, String v1, String l2, String v2) {
    return pw.Row(
      children: [
        pw.Text(l1, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(width: 2),
        pw.Expanded(child: pw.Text(v1, style: const pw.TextStyle(fontSize: 9))),
        pw.Text(l2, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(width: 2),
        pw.Text(v2, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  /// Right-aligned summary row
  static pw.Widget _summaryRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  /// Table cell helper
  static pw.Widget _tableCell(
      String text, {
        bool bold = false,
        pw.TextAlign align = pw.TextAlign.left,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Format number without trailing zeroes when whole
  static String _n(double v) =>
      v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(2);

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().substring(2)}';

  static String _formatTime(DateTime d) {
    final h   = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m   = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}