import 'dart:io' show Platform, File, Directory, Process;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/french_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/order.dart';

/// Generates and prints a professional French-language A4 PDF invoice.
/// Layout is strictly LTR (Left-to-Right) as per French document standards.
/// All monetary amounts are formatted with the DH suffix.
class PdfInvoiceGenerator {
  PdfInvoiceGenerator._();

  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;
  static pw.MemoryImage? _cachedLogoImage;

  /// Triggers the invoice preview for the given [order].
  ///
  /// • **Windows / macOS / Linux (desktop)**: Saves to a system temp file
  ///   and opens it with the OS default PDF viewer.  This completely
  ///   bypasses the `printing` package's native plugin which can call
  ///   `abort()` on Windows when no printer is configured.
  /// • **Mobile / Web**: Uses [Printing.layoutPdf] for the standard
  ///   print-preview / share sheet.
  static Future<void> printInvoice(Order order) async {
    final pdf = await _buildPdf(order);
    final pdfName = '${FrenchStrings.invoiceTitle}_${order.id}.pdf';

    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // ── Desktop: save to temp and open with default viewer ──────────
      final bytes = await pdf.save();
      final tempDir = Directory.systemTemp.path;
      final tempPath = '$tempDir${Platform.pathSeparator}$pdfName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', tempPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [tempPath]);
      } else {
        await Process.run('xdg-open', [tempPath]);
      }
    } else {
      // ── Mobile / Web ────────────────────────────────────────────────
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: pdfName,
      );
    }
  }

  /// Preloads heavy assets (fonts, images) in the background so the first PDF generation is instantaneous.
  static Future<void> preloadAssets() async {
    if (_cachedRegularFont == null || _cachedBoldFont == null || _cachedLogoImage == null) {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBold = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _cachedRegularFont = pw.Font.ttf(fontData);
      _cachedBoldFont = pw.Font.ttf(fontBold);

      final logoData = await rootBundle.load('assets/images/logo1.png');
      _cachedLogoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    }
  }

  /// Builds and returns the PDF document.
  static Future<pw.Document> _buildPdf(Order order) async {
    // Ensure assets are loaded
    await preloadAssets();

    final regularFont = _cachedRegularFont!;
    final boldFont = _cachedBoldFont!;
    final logoImage = _cachedLogoImage!;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        textDirection: pw.TextDirection.ltr,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(regularFont, boldFont, logoImage),
              pw.SizedBox(height: 32),
              _buildInvoiceMeta(order, regularFont, boldFont),
              pw.SizedBox(height: 32),
              _buildItemsTable(order, regularFont, boldFont),
              pw.SizedBox(height: 16),
              _buildTotalSection(order, regularFont, boldFont),
              pw.Spacer(),
              _buildFooter(regularFont, boldFont),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
      pw.Font regular, pw.Font bold, pw.MemoryImage logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company info (left)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(logo, height: 70, fit: pw.BoxFit.contain),
            pw.SizedBox(height: 12),
            pw.Text(
              FrenchStrings.companyName,
              style: pw.TextStyle(
                font: bold,
                fontSize: 24,
                color: const PdfColor.fromInt(0xFF222222),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              FrenchStrings.companyTagline,
              style: pw.TextStyle(
                font: regular,
                fontSize: 11,
                color: const PdfColor.fromInt(0xFF888888),
              ),
            ),
          ],
        ),
        // Invoice title (right)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              FrenchStrings.invoiceTitle.toUpperCase(),
              style: pw.TextStyle(
                font: bold,
                fontSize: 32,
                color: const PdfColor.fromInt(0xFFD4A017),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Invoice Meta & Client Info ─────────────────────────────────────────────

  static pw.Widget _buildInvoiceMeta(
      Order order, pw.Font regular, pw.Font bold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Invoice Details
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8F9FA),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE9ECEF)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _metaEntry(
                    label: FrenchStrings.invoiceNumber,
                    value: order.id,
                    regular: regular,
                    bold: bold),
                pw.SizedBox(height: 8),
                _metaEntry(
                    label: FrenchStrings.invoiceDate,
                    value: DateFormatter.formatDate(order.createdAt),
                    regular: regular,
                    bold: bold),
                pw.SizedBox(height: 8),
                _metaEntry(
                    label: FrenchStrings.issuedBy,
                    value: order.createdByName,
                    regular: regular,
                    bold: bold),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        // Client Details
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8F9FA),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE9ECEF)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  FrenchStrings.clientSection.toUpperCase(),
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 10,
                    color: const PdfColor.fromInt(0xFFD4A017),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  order.customerName,
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 14,
                    color: const PdfColor.fromInt(0xFF222222),
                  ),
                ),
                if (order.customerDetails.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    order.customerDetails,
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 11,
                      color: const PdfColor.fromInt(0xFF555555),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaEntry({
    required String label,
    required String value,
    required pw.Font regular,
    required pw.Font bold,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: regular,
            fontSize: 11,
            color: const PdfColor.fromInt(0xFF888888),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: bold,
            fontSize: 11,
            color: const PdfColor.fromInt(0xFF222222),
          ),
        ),
      ],
    );
  }

  // ── Items Table ────────────────────────────────────────────────────────────

  static pw.Widget _buildItemsTable(
      Order order, pw.Font regular, pw.Font bold) {
    const headerBg = PdfColor.fromInt(0xFFD4A017);
    const headerText = PdfColor.fromInt(0xFFFFFFFF);
    const rowAlt = PdfColor.fromInt(0xFFF8F9FA);
    const rowText = PdfColor.fromInt(0xFF333333);
    const borderColor = PdfColor.fromInt(0xFFE9ECEF);

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerBg),
          children: [
            FrenchStrings.designation,
            FrenchStrings.quantity,
            FrenchStrings.unitPrice,
            FrenchStrings.total,
          ]
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: pw.Text(
                      h.toUpperCase(),
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 10,
                        color: headerText,
                      ),
                    ),
                  ))
              .toList(),
        ),
        // Data rows
        ...order.orderItems.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          final bg = idx.isEven ? const PdfColor.fromInt(0xFFFFFFFF) : rowAlt;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              item.productName,
              '${item.quantity}',
              CurrencyFormatter.format(item.unitPrice),
              CurrencyFormatter.format(item.subtotal),
            ]
                .map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: pw.Text(
                        v,
                        style: pw.TextStyle(
                          font: regular,
                          fontSize: 11,
                          color: rowText,
                        ),
                      ),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }

  // ── Total Section ──────────────────────────────────────────────────────────

  static pw.Widget _buildTotalSection(
      Order order, pw.Font regular, pw.Font bold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF8F9FA),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFE9ECEF)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                FrenchStrings.totalToPay.toUpperCase(),
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 12,
                  color: const PdfColor.fromInt(0xFF555555),
                ),
              ),
              pw.Text(
                CurrencyFormatter.format(order.totalAmount),
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 18,
                  color: const PdfColor.fromInt(0xFFD4A017),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.Font regular, pw.Font bold) {
    return pw.Column(
      children: [
        pw.Divider(color: const PdfColor.fromInt(0xFFD4A017), thickness: 2),
        pw.SizedBox(height: 12),
        pw.Text(
          'العنوان: الحي الصناعي الرحمة رقم 1244 قطاع د حي الرحمة سلا',
          style: pw.TextStyle(font: regular, fontSize: 11, color: const PdfColor.fromInt(0xFF555555)),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'darbelamri.rabat@gmail.com',
              style: pw.TextStyle(font: regular, fontSize: 11, color: const PdfColor.fromInt(0xFF555555)),
            ),
            pw.Text(
              '  |  ',
              style: pw.TextStyle(font: regular, fontSize: 11, color: const PdfColor.fromInt(0xFFDDDDDD)),
            ),
            pw.Text(
              '+212 661 352 715',
              style: pw.TextStyle(font: bold, fontSize: 11, color: const PdfColor.fromInt(0xFF555555)),
            ),
          ],
        ),
      ],
    );
  }
}
