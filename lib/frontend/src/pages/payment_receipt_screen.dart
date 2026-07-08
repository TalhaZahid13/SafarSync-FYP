import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../utils/payment_service.dart';
import '../utils/safe_parse.dart';

class PaymentReceiptScreen extends StatefulWidget {
  final int? paymentId;
  final int bookingId;
  final String destinationName;
  final double amountPaid;

  const PaymentReceiptScreen({
    super.key,
    this.paymentId,
    required this.bookingId,
    required this.destinationName,
    required this.amountPaid,
  });

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  Map<String, dynamic>? _receipt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.paymentId != null) {
      try {
        final r = await PaymentService.getReceipt(widget.paymentId!);
        if (mounted) setState(() { _receipt = r; _loading = false; });
        return;
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  String get _bookingId => '#${widget.bookingId}';
  String get _destination => _receipt?['destination_name'] as String? ?? widget.destinationName;
  String get _userName => _receipt?['full_name'] as String? ?? 'Traveler';
  String get _userEmail => _receipt?['email'] as String? ?? '';
  String get _txRef =>
      _receipt?['transaction_reference'] as String? ??
      _receipt?['stripe_payment_intent_id'] as String? ??
      'N/A';
  String get _payDate =>
      _receipt?['transaction_date'] as String? ??
      DateFormat('yyyy-MM-dd').format(DateTime.now());
  double get _amount =>
      asDouble(_receipt?['amount']) ?? widget.amountPaid;

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('SafarSync',
                  style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700)),
              pw.Text('RECEIPT',
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Your Smart Travel Companion',
              style: pw.TextStyle(color: PdfColors.grey500, fontSize: 11)),
          pw.Divider(height: 30, color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILLED TO',
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(_userName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  if (_userEmail.isNotEmpty)
                    pw.Text(_userEmail,
                        style: pw.TextStyle(
                            color: PdfColors.grey600, fontSize: 11)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('RECEIPT DATE',
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(_payDate,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('BOOKING ID',
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(_bookingId,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300)),
            ),
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.Expanded(
                    flex: 3,
                    child: pw.Text('DESCRIPTION',
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey500,
                            fontWeight: pw.FontWeight.bold))),
                pw.Expanded(
                    child: pw.Text('AMOUNT',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey500,
                            fontWeight: pw.FontWeight.bold))),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Travel Package — $_destination',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Booking ${_bookingId}',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                    ],
                  )),
              pw.Expanded(
                  child: pw.Text('PKR ${_amount.toStringAsFixed(0)}',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            ],
          ),
          pw.Divider(height: 24, color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('AMOUNT PAID',
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('PKR ${_amount.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TRANSACTION DETAILS',
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('Reference: $_txRef',
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text('Status: PAID',
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfColors.green700)),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Divider(color: PdfColors.grey300),
          pw.Center(
            child: pw.Text(
              'Thank you for choosing SafarSync. Safe travels!',
              style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
            ),
          ),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'SafarSync_Receipt_${widget.bookingId}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF',
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 72),
                  const SizedBox(height: 12),
                  Text('Payment Successful!',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Your booking is confirmed',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  Material(
                    borderRadius: BorderRadius.circular(16),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Receipt',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24),
                          _row('Traveler', _userName),
                          _row('Booking ID', _bookingId),
                          _row('Destination', _destination),
                          _row('Payment Date', _payDate),
                          _row('Transaction Ref', _txRef),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Amount Paid',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(
                                'PKR ${_amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF Receipt'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text('$label:', style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}
