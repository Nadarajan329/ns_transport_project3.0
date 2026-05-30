import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ns_transport/core/constants/api_constants.dart';

class DriverProfileEditScreen extends ConsumerStatefulWidget {
  const DriverProfileEditScreen({super.key});

  @override
  ConsumerState<DriverProfileEditScreen> createState() => _DriverProfileEditScreenState();
}

class _DriverProfileEditScreenState extends ConsumerState<DriverProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _fatherNameController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _dobController = TextEditingController();
  final _accNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _branchController = TextEditingController();

  String? _gender;
  
  XFile? _aadharImage;
  XFile? _dlImage;
  String? _existingAadharUrl;
  String? _existingDlUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final user = ref.read(authProvider).value;
    if (user != null && user.isDriver) {
      // Fetch fresh data from users table just in case authProvider doesn't have all new columns
      _fetchUserData(user.id);
    }
  }

  Future<void> _fetchUserData(String userId) async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _fatherNameController.text = response['father_name'] ?? '';
        _homeAddressController.text = response['home_address'] ?? '';
        _gender = response['gender'];
        _dobController.text = response['date_of_birth'] ?? '';
        _accNumberController.text = response['account_number'] ?? '';
        _ifscController.text = response['ifsc_code'] ?? '';
        _branchController.text = response['branch_name'] ?? '';
        _existingAadharUrl = response['aadhar_card_url'];
        _existingDlUrl = response['driving_license_url'];
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fatherNameController.dispose();
    _homeAddressController.dispose();
    _dobController.dispose();
    _accNumberController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAadhar) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        if (isAadhar) {
          _aadharImage = image;
        } else {
          _dlImage = image;
        }
      });
    }
  }

  Future<String?> _uploadImage(XFile imageFile, String folderPath) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.contains('.') ? imageFile.name.split('.').last : 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$folderPath/$fileName';

      await Supabase.instance.client.storage
          .from(ApiConstants.profileImagesBucket)
          .uploadBinary(
            filePath, 
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      return Supabase.instance.client.storage
          .from(ApiConstants.profileImagesBucket)
          .getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      String? newAadharUrl = _existingAadharUrl;
      String? newDlUrl = _existingDlUrl;

      if (_aadharImage != null) {
        newAadharUrl = await _uploadImage(_aadharImage!, '$userId/aadhar');
      }
      if (_dlImage != null) {
        newDlUrl = await _uploadImage(_dlImage!, '$userId/dl');
      }

      await Supabase.instance.client.from('users').update({
        'father_name': _fatherNameController.text.trim(),
        'home_address': _homeAddressController.text.trim(),
        'gender': _gender,
        'date_of_birth': _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
        'account_number': _accNumberController.text.trim(),
        'ifsc_code': _ifscController.text.trim(),
        'branch_name': _branchController.text.trim(),
        if (newAadharUrl != null) 'aadhar_card_url': newAadharUrl,
        if (newDlUrl != null) 'driving_license_url': newDlUrl,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // default 18 years ago
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, inherit: false)),
        backgroundColor: const Color(0xFF1565C0),
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
                    _buildSectionTitle('Personal Information', isDark),
                    _buildTextField(
                      controller: _fatherNameController,
                      label: "Father's Name",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _homeAddressController,
                      label: "Home Address",
                      icon: Icons.home_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.people_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) => setState(() => _gender = val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Bank Details', isDark),
                    _buildTextField(
                      controller: _accNumberController,
                      label: "Account Number",
                      icon: Icons.account_balance,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _ifscController,
                      label: "IFSC Code",
                      icon: Icons.code,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _branchController,
                      label: "Branch Name",
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('ID Proofs', isDark),
                    _buildImagePicker('Aadhar Card', true, _aadharImage, _existingAadharUrl, isDark),
                    const SizedBox(height: 16),
                    _buildImagePicker('Driving License', false, _dlImage, _existingDlUrl, isDark),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1565C0),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildImagePicker(String title, bool isAadhar, XFile? currentImage, String? existingUrl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(isAadhar),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: currentImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(currentImage.path, fit: BoxFit.cover),
                  )
                : (existingUrl != null && existingUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(existingUrl, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to upload $title', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}
