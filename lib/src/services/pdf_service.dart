import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/quote.dart';

class PdfService {
  static final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Gera PDF do orçamento
  static Future<Uint8List> generateQuotePdf(Quote quote) async {
    final pdf = pw.Document();

    // Carrega fonte personalizada se necessário
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(quote, fontBold),
            pw.SizedBox(height: 20),
            _buildQuoteInfo(quote, font, fontBold),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(quote, font, fontBold),
            pw.SizedBox(height: 20),
            _buildItemsTable(quote, font, fontBold),
            pw.SizedBox(height: 20),
            _buildTotals(quote, font, fontBold),
            if (quote.notes != null && quote.notes!.isNotEmpty) ...
              _buildNotes(quote, font, fontBold),
            if (quote.terms != null && quote.terms!.isNotEmpty) ...
              _buildTerms(quote, font, fontBold),
            pw.Spacer(),
            _buildFooter(quote, font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Cabeçalho do PDF
  static pw.Widget _buildHeader(Quote quote, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ORÇAMENTO',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 24,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              'Nº ${quote.id}',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'BKCRM',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 20,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              'Sistema de Gestão',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Informações do orçamento
  static pw.Widget _buildQuoteInfo(Quote quote, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMAÇÕES DO ORÇAMENTO',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem('Título', quote.title, font, fontBold),
              ),
              pw.Expanded(
                child: _buildInfoItem('Status', _getStatusLabel(quote.status), font, fontBold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem('Data de Criação', _dateFormat.format(quote.createdAt), font, fontBold),
              ),
              pw.Expanded(
                child: _buildInfoItem('Válido até', quote.validUntil != null ? _dateFormat.format(quote.validUntil!) : 'Não definido', font, fontBold),
              ),
            ],
          ),
          if (quote.description != null && quote.description!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _buildInfoItem('Descrição', quote.description!, font, fontBold),
          ],
        ],
      ),
    );
  }

  /// Informações do cliente
  static pw.Widget _buildCustomerInfo(Quote quote, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DADOS DO CLIENTE',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
          ),
          pw.SizedBox(height: 12),
          _buildInfoItem('Nome', quote.customer.name, font, fontBold),
          if (quote.assignedAgent != null) ...[
            pw.SizedBox(height: 8),
            _buildInfoItem('Agente Responsável', quote.assignedAgent!.name, font, fontBold),
          ],
        ],
      ),
    );
  }

  /// Tabela de itens
  static pw.Widget _buildItemsTable(Quote quote, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ITENS DO ORÇAMENTO',
          style: pw.TextStyle(font: fontBold, fontSize: 14),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Cabeçalho
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Descrição', fontBold, isHeader: true),
                _buildTableCell('Qtd', fontBold, isHeader: true),
                _buildTableCell('Valor Unit.', fontBold, isHeader: true),
                _buildTableCell('Total', fontBold, isHeader: true),
              ],
            ),
            // Itens
            ...quote.items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item.description, font),
                _buildTableCell(item.quantity.toString(), font, alignment: pw.Alignment.center),
                _buildTableCell(_currencyFormat.format(item.unitPrice), font, alignment: pw.Alignment.centerRight),
                _buildTableCell(_currencyFormat.format(item.total), font, alignment: pw.Alignment.centerRight),
              ],
            )),
          ],
        ),
      ],
    );
  }

  /// Totais do orçamento
  static pw.Widget _buildTotals(Quote quote, pw.Font font, pw.Font fontBold) {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Container()),
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal:', _currencyFormat.format(quote.subtotal), font, fontBold),
              if (quote.additionalDiscount > 0) ...[
                pw.SizedBox(height: 4),
                _buildTotalRow('Desconto:', '-${_currencyFormat.format(quote.additionalDiscount)}', font, fontBold),
              ],
              if (quote.taxRate > 0) ...[
                pw.SizedBox(height: 4),
                _buildTotalRow('Impostos (${quote.taxRate.toStringAsFixed(1)}%):', _currencyFormat.format(quote.taxAmount), font, fontBold),
              ],
              pw.Divider(color: PdfColors.grey400),
              _buildTotalRow('TOTAL:', _currencyFormat.format(quote.total), fontBold, fontBold, isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  /// Observações
  static List<pw.Widget> _buildNotes(Quote quote, pw.Font font, pw.Font fontBold) {
    return [
      pw.SizedBox(height: 20),
      pw.Text(
        'OBSERVAÇÕES',
        style: pw.TextStyle(font: fontBold, fontSize: 14),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          quote.notes!,
          style: pw.TextStyle(font: font, fontSize: 11),
        ),
      ),
    ];
  }

  /// Termos e condições
  static List<pw.Widget> _buildTerms(Quote quote, pw.Font font, pw.Font fontBold) {
    return [
      pw.SizedBox(height: 20),
      pw.Text(
        'TERMOS E CONDIÇÕES',
        style: pw.TextStyle(font: fontBold, fontSize: 14),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          quote.terms!,
          style: pw.TextStyle(font: font, fontSize: 11),
        ),
      ),
    ];
  }

  /// Rodapé
  static pw.Widget _buildFooter(Quote quote, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado em ${_dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'BKCRM - Sistema de Gestão',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Helper para criar item de informação
  static pw.Widget _buildInfoItem(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  /// Helper para criar célula da tabela
  static pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false, pw.Alignment? alignment}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Helper para criar linha de total
  static pw.Widget _buildTotalRow(String label, String value, pw.Font labelFont, pw.Font valueFont, {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: labelFont,
            fontSize: isTotal ? 12 : 11,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: valueFont,
            fontSize: isTotal ? 12 : 11,
            fontWeight: pw.FontWeight.bold,
            color: isTotal ? PdfColors.blue800 : null,
          ),
        ),
      ],
    );
  }

  /// Converte status para label
  static String _getStatusLabel(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.draft:
        return 'Rascunho';
      case QuoteStatus.pending:
        return 'Pendente';
      case QuoteStatus.approved:
        return 'Aprovado';
      case QuoteStatus.rejected:
        return 'Rejeitado';
      case QuoteStatus.expired:
        return 'Expirado';
      case QuoteStatus.converted:
        return 'Convertido';
    }
  }

  /// Imprime o PDF
  static Future<void> printQuote(Quote quote) async {
    final pdfData = await generateQuotePdf(quote);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Orçamento ${quote.id}',
    );
  }

  /// Salva o PDF no dispositivo
  static Future<String?> saveQuotePdf(Quote quote) async {
    try {
      final pdfData = await generateQuotePdf(quote);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/orcamento_${quote.id}.pdf');
      await file.writeAsBytes(pdfData);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Compartilha o PDF
  static Future<void> shareQuotePdf(Quote quote) async {
    final pdfData = await generateQuotePdf(quote);
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'orcamento_${quote.id}.pdf',
    );
  }
}