import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/models/trip_model.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/widgets/status_badge.dart';
import 'package:ns_transport/utils/formatters.dart';
import 'package:ns_transport/services/pdf_service.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  final _commentController = TextEditingController();
  bool _isActionLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      await ref.read(tripProvider.notifier).updateTripStatus(
        widget.tripId,
        status,
      );
      
      // If owner comments, update database comment as well
      if (_commentController.text.isNotEmpty) {
        await ref.read(tripServiceProvider).updateTripStatus(
          widget.tripId,
          status,
          comment: _commentController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trip status updated to $status')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf(TripModel trip) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      await PdfService.generateAndPrintTripReport(trip);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final tripState = ref.watch(tripProvider);

    final primaryColor = const Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          tripState.when(
            data: (trips) {
              final trip = trips.firstWhere((t) => t.id == widget.tripId);
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: _isActionLoading ? null : () => _downloadPdf(trip),
                tooltip: 'Export PDF',
              );
            },
            loading: () => const SizedBox(),
            error: (err, stack) => const SizedBox(),
          )
        ],
      ),
      body: tripState.when(
        data: (trips) {
          final tripIndex = trips.indexWhere((t) => t.id == widget.tripId);
          if (tripIndex == -1) {
            return const Center(child: Text('Trip not found.'));
          }
          final trip = trips[tripIndex];

          // Compute values
          final totalExpenses = trip.fuelExpense + trip.tollExpense + trip.foodExpense + trip.otherExpense;
          final netProfit = trip.rentAmount - totalExpenses;
          final remainingBalance = trip.rentAmount - trip.advanceAmount - totalExpenses;

          if (trip.ownerComment != null && _commentController.text.isEmpty) {
            _commentController.text = trip.ownerComment!;
          }

          return _isActionLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeaderCard(trip),
                      const SizedBox(height: 24),

                      // Location Route Card
                      _buildRouteCard(trip),
                      const SizedBox(height: 24),

                      // Financial Summary List
                      _buildFinancialSummary(trip, totalExpenses, netProfit, remainingBalance),
                      const SizedBox(height: 24),

                      // Attachments Section
                      _buildAttachments(trip),
                      const SizedBox(height: 24),

                      // Notes Section
                      if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                        _buildNotesSection(trip),
                        const SizedBox(height: 24),
                      ],

                      // Owner Comment & Actions
                      if (user != null) ...[
                        if (user.isOwner)
                          _buildOwnerActions(trip)
                        else
                          _buildDriverActions(trip),
                      ],
                    ],
                  ),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading trip details: $err')),
      ),
    );
  }

  Widget _buildHeaderCard(TripModel trip) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.vehicleNumber,
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${Formatters.formatDate(trip.tripDate)}',
                    style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Driver ID: ${trip.driverId}',
                    style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            StatusBadge(status: trip.status),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(TripModel trip) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route Info', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trip.fromLocation,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Container(
                width: 2,
                height: 24,
                color: Colors.grey.shade300,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trip.toLocation,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (trip.loadType != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Load Type:', style: GoogleFonts.inter(color: Colors.grey)),
                  Text(trip.loadType!, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Customer:', style: GoogleFonts.inter(color: Colors.grey)),
                Text(trip.customerName, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(TripModel trip, double totalExpenses, double netProfit, double remainingBalance) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Summary', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildFinancialRow('Rent Amount', trip.rentAmount, isPrimary: true),
            _buildFinancialRow('Fuel Expense', -trip.fuelExpense),
            _buildFinancialRow('Toll Expense', -trip.tollExpense),
            _buildFinancialRow('Food Expense', -trip.foodExpense),
            _buildFinancialRow('Other Expense', -trip.otherExpense),
            const Divider(height: 24),
            _buildFinancialRow('Total Expenses', totalExpenses, isBold: true),
            _buildFinancialRow('Advance Received', -trip.advanceAmount),
            const Divider(height: 24),
            _buildFinancialRow('Net Profit', netProfit, isHighlight: true, isProfit: netProfit >= 0),
            _buildFinancialRow('Outstanding Balance', remainingBalance, isBold: true, isProfit: remainingBalance >= 0),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, double amount, {bool isPrimary = false, bool isBold = false, bool isHighlight = false, bool? isProfit}) {
    Color valColor = Colors.black87;
    if (amount < 0 && isHighlight != true) valColor = Colors.red.shade700;
    if (amount > 0 && isPrimary) valColor = Colors.green.shade700;
    if (isProfit != null) {
      valColor = isProfit ? Colors.green.shade700 : Colors.red.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: (isBold || isHighlight) ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            Formatters.formatCurrency(amount),
            style: GoogleFonts.inter(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: (isBold || isHighlight) ? FontWeight.bold : FontWeight.w600,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(TripModel trip) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipts & Documents', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildImageThumbnail('Bill Photo', trip.billImage)),
                const SizedBox(width: 16),
                Expanded(child: _buildImageThumbnail('Fuel Receipt', trip.receiptImage)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String label, String? path) {
    Widget imageWidget;
    if (path == null) {
      imageWidget = Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    } else if (path.startsWith('http') || path.startsWith('https')) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(path, height: 100, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.grey);
        }),
      );
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb 
            ? Image.network(path, height: 100, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, color: Colors.grey);
              })
            : Image.file(File(path), height: 100, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, color: Colors.grey);
              }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: path != null
              ? () {
                  // Simple lightbox preview
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: InteractiveViewer(
                        child: path.startsWith('http')
                            ? Image.network(path)
                            : (kIsWeb ? Image.network(path) : Image.file(File(path))),
                      ),
                    ),
                  );
                }
              : null,
          child: imageWidget,
        ),
      ],
    );
  }

  Widget _buildNotesSection(TripModel trip) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              trip.notes!,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerActions(TripModel trip) {
    final isPending = trip.status == 'submitted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text('Owner Review Comment', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter approval comments or rejection reasons...',
            fillColor: Colors.grey.shade50,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        if (isPending)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus('rejected'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Reject Report', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus('approved'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Approve & Settle', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _updateStatus('submitted'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.orange.shade700, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Reopen for Edit / Review',
                style: GoogleFonts.inter(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDriverActions(TripModel trip) {
    if (trip.status != 'draft' && trip.status != 'rejected') return const SizedBox();

    return Column(
      children: [
        const Divider(height: 32),
        if (trip.ownerComment != null && trip.ownerComment!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner Comment:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.ownerComment!,
                  style: GoogleFonts.inter(color: Colors.orange.shade900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: Text('Edit Report', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // TODO: Navigate to Edit screen (in our case we can support editing on TripFormScreen by passing TripModel)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit draft functionality is triggered.')),
              );
            },
          ),
        ),
      ],
    );
  }
}
