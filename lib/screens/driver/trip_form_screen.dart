import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ns_transport/models/trip_model.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/widgets/custom_text_field.dart';
import 'package:ns_transport/utils/formatters.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  final TripModel? existingTrip;
  const TripFormScreen({super.key, this.existingTrip});

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _vehicleNumberController = TextEditingController();
  final _dateController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _loadTypeController = TextEditingController();
  final _loadTonnageController = TextEditingController();
  
  final _rentAmountController = TextEditingController();
  final _fuelExpenseController = TextEditingController();
  final _tollExpenseController = TextEditingController();
  final _foodExpenseController = TextEditingController();
  final _otherExpenseController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  XFile? _billImage;
  XFile? _receiptImage;
  String? _existingBillUrl;
  String? _existingReceiptUrl;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    if (widget.existingTrip != null) {
      final trip = widget.existingTrip!;
      _selectedDate = trip.tripDate;
      _vehicleNumberController.text = trip.vehicleNumber;
      _fromLocationController.text = trip.fromLocation;
      _toLocationController.text = trip.toLocation;
      _loadTypeController.text = trip.loadType ?? '';
      _loadTonnageController.text = trip.loadTonnage;
      _rentAmountController.text = trip.rentAmount > 0 ? trip.rentAmount.toString() : '';
      _fuelExpenseController.text = trip.fuelExpense > 0 ? trip.fuelExpense.toString() : '';
      _tollExpenseController.text = trip.tollExpense > 0 ? trip.tollExpense.toString() : '';
      _foodExpenseController.text = trip.foodExpense > 0 ? trip.foodExpense.toString() : '';
      _otherExpenseController.text = trip.otherExpense > 0 ? trip.otherExpense.toString() : '';
      _advanceAmountController.text = trip.advanceAmount > 0 ? trip.advanceAmount.toString() : '';
      _notesController.text = trip.notes ?? '';
      _existingBillUrl = trip.billImage;
      _existingReceiptUrl = trip.receiptImage;
    }
    
    _dateController.text = Formatters.formatDate(_selectedDate, format: 'dd-MM-yyyy');
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _dateController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _loadTypeController.dispose();
    _loadTonnageController.dispose();
    _rentAmountController.dispose();
    _fuelExpenseController.dispose();
    _tollExpenseController.dispose();
    _foodExpenseController.dispose();
    _otherExpenseController.dispose();
    _advanceAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = Formatters.formatDate(_selectedDate, format: 'dd-MM-yyyy');
      });
    }
  }

  Future<void> _pickImage(bool isBill) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isBill) {
          _billImage = image;
        } else {
          _receiptImage = image;
        }
      });
    }
  }

  Future<void> _submit(String status) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      String? billUrl = _existingBillUrl;
      String? receiptUrl = _existingReceiptUrl;

      if (_billImage != null) {
        billUrl = await ref.read(tripServiceProvider).uploadImage(_billImage!, 'bills');
      }
      if (_receiptImage != null) {
        receiptUrl = await ref.read(tripServiceProvider).uploadImage(_receiptImage!, 'receipts');
      }

      final isEditing = widget.existingTrip != null;

      final trip = TripModel(
        id: isEditing ? widget.existingTrip!.id : null,
        driverId: user.id,
        vehicleNumber: _vehicleNumberController.text,
        tripDate: _selectedDate,
        fromLocation: _fromLocationController.text,
        toLocation: _toLocationController.text,
        loadType: _loadTypeController.text.isEmpty ? null : _loadTypeController.text,
        loadTonnage: _loadTonnageController.text,
        rentAmount: double.tryParse(_rentAmountController.text) ?? 0.0,
        fuelExpense: double.tryParse(_fuelExpenseController.text) ?? 0.0,
        tollExpense: double.tryParse(_tollExpenseController.text) ?? 0.0,
        foodExpense: double.tryParse(_foodExpenseController.text) ?? 0.0,
        otherExpense: double.tryParse(_otherExpenseController.text) ?? 0.0,
        advanceAmount: double.tryParse(_advanceAmountController.text) ?? 0.0,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: status,
        billImage: billUrl,
        receiptImage: receiptUrl,
        createdAt: isEditing ? widget.existingTrip!.createdAt : null,
        ownerComment: isEditing ? widget.existingTrip!.ownerComment : null,
      );

      if (isEditing) {
        await ref.read(tripProvider.notifier).updateTrip(trip);
      } else {
        await ref.read(tripProvider.notifier).addTrip(trip);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'draft' ? 'Draft saved' : 'Trip submitted successfully')),
        );
        Navigator.pop(context);
        if (isEditing) {
          // If edited from trip details, pop that screen too
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save trip: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePicker(String title, XFile? image, String? existingUrl, bool isBill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(isBill),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb ? Image.network(image.path, fit: BoxFit.cover) : Image.file(File(image.path), fit: BoxFit.cover),
                  )
                : (existingUrl != null && existingUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(existingUrl, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to select image', style: GoogleFonts.inter(color: Colors.grey.shade500)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1565C0);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTrip != null ? 'Edit Report' : 'New Trip', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('General Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _vehicleNumberController,
                    label: 'Vehicle Number',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _pickDate(context),
                    child: IgnorePointer(
                      child: CustomTextField(
                        controller: _dateController,
                        label: 'Date',
                        prefixIcon: Icons.calendar_today,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fromLocationController,
                    label: 'From Location',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _toLocationController,
                    label: 'To Location',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _loadTypeController,
                    label: 'Load Type (Optional)',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _loadTonnageController,
                    label: 'Load Tonnage',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  Text('Financial Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _rentAmountController,
                    label: 'Rent Amount',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _advanceAmountController,
                    label: 'Advance Amount',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fuelExpenseController,
                    label: 'Fuel Expense',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _tollExpenseController,
                    label: 'Toll Expense',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _foodExpenseController,
                    label: 'Food Expense',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _otherExpenseController,
                    label: 'Other Expense',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 32),
                  Text('Attachments & Notes', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 16),
                  _buildImagePicker('Bill Image', _billImage, _existingBillUrl, true),
                  const SizedBox(height: 16),
                  _buildImagePicker('Fuel Receipt', _receiptImage, _existingReceiptUrl, false),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      labelStyle: GoogleFonts.inter(color: Colors.grey.shade700),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _submit('draft'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: primaryColor, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Save as Draft', style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _submit('submitted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Submit Report', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }
}
