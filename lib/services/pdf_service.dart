import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ns_transport/models/trip_model.dart';
import 'package:ns_transport/utils/formatters.dart';

class PdfService {
  static Future<void> generateAndPrintTripReport(TripModel trip) async {
    final pdf = pw.Document();

    final totalExpenses = trip.loadingExpense + trip.unloadingExpense + trip.otherExpense;
    final netProfit = trip.rentAmount - totalExpenses;
    final remainingBalance = trip.rentAmount - trip.advanceAmount - totalExpenses;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NS TRANSPORT SYSTEM',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('Official Trip Summary Report', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Trip Ref: ${trip.id ?? "N/A"}'),
                        pw.Text('Date: ${Formatters.formatDate(trip.tripDate)}'),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // General Information Table
                pw.Text('Trip Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Vehicle Number')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(trip.vehicleNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ]),
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Driver ID')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(trip.driverId)),
                    ]),
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Route')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${trip.fromLocation} to ${trip.toLocation}')),
                    ]),
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Load Tonnage')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(trip.loadTonnage)),
                    ]),
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Status')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(trip.status.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ]),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Financials Summary Table
                pw.Text('Financial breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _buildPdfTableRow('Rent Revenue', Formatters.formatCurrency(trip.rentAmount)),
                    _buildPdfTableRow('Loading Expenses', '- ${Formatters.formatCurrency(trip.loadingExpense)}'),
                    _buildPdfTableRow('Unloading Expenses', '- ${Formatters.formatCurrency(trip.unloadingExpense)}'),
                    if (trip.otherExpenseDetails != null && trip.otherExpenseDetails!.isNotEmpty)
                      ...trip.otherExpenseDetails!.map((e) => _buildPdfTableRow(
                        e['description']?.toString().isNotEmpty == true ? e['description']! : 'Other Expense', 
                        '- ${Formatters.formatCurrency((e['amount'] as num).toDouble())}'
                      ))
                    else if (trip.otherExpense > 0)
                      _buildPdfTableRow('Other Expenses', '- ${Formatters.formatCurrency(trip.otherExpense)}'),
                    _buildPdfTableRow('Total Trip Expenses', Formatters.formatCurrency(totalExpenses), isBold: true),
                    _buildPdfTableRow('Advance Paid to Driver', '- ${Formatters.formatCurrency(trip.advanceAmount)}'),
                    _buildPdfTableRow('Net Profit Margin', Formatters.formatCurrency(netProfit), isBold: true),
                    _buildPdfTableRow('Outstanding Balance Payable', Formatters.formatCurrency(remainingBalance), isBold: true, highlight: true),
                  ],
                ),

                pw.SizedBox(height: 40),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Owner Authorized Signature', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save and print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'trip_report_${trip.id ?? "unknown"}.pdf',
    );
  }

  static pw.TableRow _buildPdfTableRow(String label, String value, {bool isBold = false, bool highlight = false}) {
    return pw.TableRow(
      decoration: highlight ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: (isBold || highlight) ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
