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
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/core/theme/app_theme.dart';

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
  final _loadingExpenseController = TextEditingController();
  final _unloadingExpenseController = TextEditingController();
  List<Map<String, TextEditingController>> _otherExpenses = [];
  
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<XFile> _billImages = [];
  List<XFile> _receiptImages = [];
  List<String> _existingBillUrls = [];
  List<String> _existingReceiptUrls = [];
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
      _loadingExpenseController.text = trip.loadingExpense > 0 ? trip.loadingExpense.toString() : '';
      _unloadingExpenseController.text = trip.unloadingExpense > 0 ? trip.unloadingExpense.toString() : '';
      
      if (trip.otherExpenseDetails != null) {
        for (var detail in trip.otherExpenseDetails!) {
          _otherExpenses.add({
            'description': TextEditingController(text: detail['description'] ?? ''),
            'amount': TextEditingController(text: detail['amount']?.toString() ?? ''),
          });
        }
      }
      _notesController.text = trip.notes ?? '';
      _existingBillUrls = trip.billImages ?? [];
      _existingReceiptUrls = trip.receiptImages ?? [];
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
    _loadingExpenseController.dispose();
    _unloadingExpenseController.dispose();
    for (var expense in _otherExpenses) {
      expense['description']?.dispose();
      expense['amount']?.dispose();
    }
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
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        if (isBill) {
          _billImages.addAll(images);
        } else {
          _receiptImages.addAll(images);
        }
      });
    }
  }

  Future<void> _takePhoto(bool isBill) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        if (isBill) {
          _billImages.add(photo);
        } else {
          _receiptImages.add(photo);
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
          SnackBar(content: Text(AppTranslations.get('user_not_authenticated', ref.read(localeProvider)))),
        );
        return;
      }

      List<String> finalBillUrls = List.from(_existingBillUrls);
      List<String> finalReceiptUrls = List.from(_existingReceiptUrls);

      for (var img in _billImages) {
        String url = await ref.read(tripServiceProvider).uploadImage(img, 'bills');
        finalBillUrls.add(url);
      }
      
      for (var img in _receiptImages) {
        String url = await ref.read(tripServiceProvider).uploadImage(img, 'receipts');
        finalReceiptUrls.add(url);
      }

      double otherExpenseSum = 0;
      List<Map<String, dynamic>> otherExpenseDetailsList = [];
      for (var expense in _otherExpenses) {
        final amountText = expense['amount']!.text;
        final descText = expense['description']!.text;
        if (amountText.isNotEmpty) {
          final amt = double.tryParse(amountText) ?? 0.0;
          otherExpenseSum += amt;
          otherExpenseDetailsList.add({
            'description': descText,
            'amount': amt,
          });
        }
      }

      final isEditing = widget.existingTrip != null;

      final trip = TripModel(
        id: isEditing ? widget.existingTrip!.id : null,
        driverId: isEditing ? widget.existingTrip!.driverId : user.id,
        vehicleNumber: _vehicleNumberController.text,
        tripDate: _selectedDate,
        fromLocation: _fromLocationController.text,
        toLocation: _toLocationController.text,
        loadType: _loadTypeController.text.isEmpty ? null : _loadTypeController.text,
        loadTonnage: _loadTonnageController.text,
        rentAmount: double.tryParse(_rentAmountController.text) ?? 0.0,
        loadingExpense: double.tryParse(_loadingExpenseController.text) ?? 0.0,
        unloadingExpense: double.tryParse(_unloadingExpenseController.text) ?? 0.0,
        otherExpense: otherExpenseSum,
        otherExpenseDetails: otherExpenseDetailsList.isEmpty ? null : otherExpenseDetailsList,
        advanceAmount: isEditing ? widget.existingTrip!.advanceAmount : 0.0,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: status,
        billImages: finalBillUrls.isEmpty ? null : finalBillUrls,
        receiptImages: finalReceiptUrls.isEmpty ? null : finalReceiptUrls,
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
          SnackBar(content: Text(status == 'draft' ? AppTranslations.get('draft_saved', ref.read(localeProvider)) : AppTranslations.get('trip_submitted', ref.read(localeProvider)))),
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
          SnackBar(content: Text('${AppTranslations.get('failed_save_trip', ref.read(localeProvider))}: $e')),
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

  Widget _buildMultiImagePicker(String title, List<XFile> images, List<String> existingUrls, bool isBill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            ),
            TextButton.icon(
              onPressed: () => _takePhoto(isBill),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: Text(AppTranslations.get('take_photo', ref.read(localeProvider)), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: () => _pickImage(isBill),
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: Text(AppTranslations.get('add_images', ref.read(localeProvider)), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (images.isEmpty && existingUrls.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Take Photo option
                Expanded(
                  child: InkWell(
                    onTap: () => _takePhoto(isBill),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt, size: 28, color: const Color(0xFF1565C0)),
                        ),
                        const SizedBox(height: 8),
                        Text(AppTranslations.get('take_photo', ref.read(localeProvider)), style: GoogleFonts.inter(color: const Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey.shade300,
                ),
                // Pick from gallery option
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(isBill),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_photo_alternate, size: 28, color: const Color(0xFF1565C0)),
                        ),
                        const SizedBox(height: 8),
                        Text(AppTranslations.get('add_images', ref.read(localeProvider)), style: GoogleFonts.inter(color: const Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...existingUrls.asMap().entries.map((entry) {
                  int index = entry.key;
                  String url = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, height: 120, width: 120, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isBill) {
                                  _existingBillUrls.removeAt(index);
                                } else {
                                  _existingReceiptUrls.removeAt(index);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                ...images.asMap().entries.map((entry) {
                  int index = entry.key;
                  XFile img = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb 
                              ? Image.network(img.path, height: 120, width: 120, fit: BoxFit.cover) 
                              : Image.file(File(img.path), height: 120, width: 120, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isBill) {
                                  _billImages.removeAt(index);
                                } else {
                                  _receiptImages.removeAt(index);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOtherExpensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._otherExpenses.asMap().entries.map((entry) {
          int index = entry.key;
          var expense = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: expense['description']!,
                    label: AppTranslations.get('description_optional', ref.read(localeProvider)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    controller: expense['amount']!,
                    label: AppTranslations.get('amount', ref.read(localeProvider)),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _otherExpenses[index]['description']?.dispose();
                      _otherExpenses[index]['amount']?.dispose();
                      _otherExpenses.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        if (_otherExpenses.length < 15)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _otherExpenses.add({
                  'description': TextEditingController(),
                  'amount': TextEditingController(),
                });
              });
            },
            icon: const Icon(Icons.add_circle, color: Color(0xFF1565C0)),
            label: Text(AppTranslations.get('add_other_expense', ref.read(localeProvider)), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1565C0))),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1565C0);
    final locale = ref.watch(localeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTrip != null ? AppTranslations.get('edit_report', locale) : AppTranslations.get('new_trip', locale), style: AppTheme.getFont(locale, fontWeight: FontWeight.w600, color: Colors.white)),
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
                  Text(AppTranslations.get('general_details', locale), style: AppTheme.getFont(locale, fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _vehicleNumberController,
                    label: AppTranslations.get('vehicle_number', locale),
                    validator: (v) => v == null || v.isEmpty ? AppTranslations.get('required', locale) : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _pickDate(context),
                    child: IgnorePointer(
                      child: CustomTextField(
                        controller: _dateController,
                        label: AppTranslations.get('date', locale),
                        prefixIcon: Icons.calendar_today,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fromLocationController,
                    label: AppTranslations.get('from_location', locale),
                    validator: (v) => v == null || v.isEmpty ? AppTranslations.get('required', locale) : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _toLocationController,
                    label: AppTranslations.get('to_location', locale),
                    validator: (v) => v == null || v.isEmpty ? AppTranslations.get('required', locale) : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _loadTypeController,
                    label: AppTranslations.get('load_type_optional', locale),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _loadTonnageController,
                    label: AppTranslations.get('load_tonnage', locale),
                    validator: (v) => v == null || v.isEmpty ? AppTranslations.get('required', locale) : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _rentAmountController,
                    label: AppTranslations.get('rent_amount', locale),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? AppTranslations.get('required', locale) : null,
                  ),
                  
                  const SizedBox(height: 32),
                  Text(AppTranslations.get('trip_expenses', locale), style: AppTheme.getFont(locale, fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _loadingExpenseController,
                    label: AppTranslations.get('loading_expense', locale),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? AppTranslations.get('required', locale) : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _unloadingExpenseController,
                    label: AppTranslations.get('unloading_expense', locale),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? AppTranslations.get('required', locale) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(AppTranslations.get('other_expenses_opt', locale), style: AppTheme.getFont(locale, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  _buildOtherExpensesSection(),

                  const SizedBox(height: 32),
                  Text(AppTranslations.get('attachments_notes', locale), style: AppTheme.getFont(locale, fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 16),
                  _buildMultiImagePicker(AppTranslations.get('bill_images', locale), _billImages, _existingBillUrls, true),
                  const SizedBox(height: 16),
                  _buildMultiImagePicker(AppTranslations.get('fuel_receipts', locale), _receiptImages, _existingReceiptUrls, false),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    style: AppTheme.getFont(locale,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: AppTranslations.get('notes', locale),
                      labelStyle: AppTheme.getFont(locale, color: Colors.grey.shade700),
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
                          child: Text(AppTranslations.get('save_as_draft', locale), style: AppTheme.getFont(locale, color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
                          child: Text(AppTranslations.get('submit_report', locale), style: AppTheme.getFont(locale, fontWeight: FontWeight.bold, fontSize: 16)),
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
