import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/providers/salary_provider.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/models/salary_model.dart';
import 'package:ns_transport/routes/app_routes.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> driver;

  const EmployeeDetailScreen({super.key, required this.driver});

  @override
  ConsumerState<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String _selectedDay = DateTime.now().day.toString();
  String _selectedMonth = DateTime.now().month.toString();
  String _selectedYear = DateTime.now().year.toString();

  String _selectedTripMonth = 'All Months';
  String _selectedTripYear = 'All Years';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salaryProvider.notifier).loadSalaries();
      ref.read(tripProvider.notifier).loadTrips();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final day = DateTime.now().day;
    final month = DateTime.now().month;
    final year = DateTime.now().year;
    final driverId = widget.driver['id']?.toString() ?? '';

    try {
      final salary = SalaryModel(
        driverId: driverId,
        totalSalary: 0,
        paidAmount: amount,
        advanceAmount: 0,
        month: month,
        year: year,
        day: day,
      );

      await ref.read(salaryProvider.notifier).upsertSalary(salary);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.driver['name'] ?? 'Unknown';
    final driverEmail = widget.driver['email'] ?? '';
    final driverPhone = widget.driver['phone'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          driverName,
          style: const TextStyle(color: Colors.white, inherit: false, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFBBDEFB),
                  backgroundImage: widget.driver['avatar_url'] != null && widget.driver['avatar_url'].isNotEmpty
                      ? NetworkImage(widget.driver['avatar_url'])
                      : null,
                  child: widget.driver['avatar_url'] == null || widget.driver['avatar_url'].isEmpty
                      ? Text(
                          driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1976D2),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              driverName,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driverEmail,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (driverPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              driverPhone,
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1976D2),
            unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            indicatorColor: const Color(0xFF1976D2),
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Profile Info'),
              Tab(icon: Icon(Icons.attach_money), text: 'Salary'),
              Tab(icon: Icon(Icons.route), text: 'Trips'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(isDark),
                _buildSalaryTab(isDark),
                _buildTripsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryTab(bool isDark) {
    final salariesAsync = ref.watch(salaryProvider);
    final tripsAsync = ref.watch(tripProvider);
    final driverId = widget.driver['id']?.toString() ?? '';

    if (salariesAsync.isLoading || tripsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (salariesAsync.hasError || tripsAsync.hasError) {
      return Center(child: Text('Error: ${salariesAsync.error ?? tripsAsync.error}'));
    }

    final salaries = salariesAsync.value ?? [];
    final trips = tripsAsync.value ?? [];

    final driverSalaries = salaries.where((s) => s.driverId == driverId).toList();
    final driverTrips = trips.where((t) => t.driverId == driverId).toList();

    double totalRent = 0;
    for (var t in driverTrips) {
      totalRent += t.rentAmount;
    }
    double totalSalary = totalRent * 0.15;

    double totalPaid = 0;
    for (var s in driverSalaries) {
      totalPaid += s.paidAmount;
    }
    double balance = totalSalary - totalPaid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _buildAmountCard(
                      'Total Salary',
                      totalSalary,
                      const Color(0xFFE3EDF7),
                      const Color(0xFF1976D2),
                      Icons.account_balance_wallet,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAmountCard(
                      'Paid Amount',
                      totalPaid,
                      const Color(0xFFE8F5E9),
                      const Color(0xFF2E7D32),
                      Icons.check_circle,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAmountCard(
                'Balance',
                balance.abs(),
                balance > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                balance > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                Icons.balance,
                isDark,
                fullWidth: true,
              ),
              const SizedBox(height: 32),
              Text(
                'Add Payment',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildAddPaymentForm(isDark),
              const SizedBox(height: 32),
              Text(
                'Payment History',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentHistory(driverSalaries, isDark),
            ],
          ),
        );

  }

  Widget _buildAmountCard(String title, double amount, Color bgColor, Color iconColor, IconData icon, bool isDark, {bool fullWidth = false, bool isInt = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? bgColor.withOpacity(0.1) : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: bgColor.withOpacity(0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isInt ? amount.toInt().toString() : amount.toStringAsFixed(2),
            style: GoogleFonts.inter(
              color: iconColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPaymentForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount Paid',
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF1976D2)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _recordPayment,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Record Payment', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory(List<SalaryModel> salaries, bool isDark) {
    if (salaries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No payment history found', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    String formatDateTime(DateTime dt) {
      String p(int n) => n.toString().padLeft(2, '0');
      String ampm = dt.hour >= 12 ? 'PM' : 'AM';
      int h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '${p(dt.day)}/${p(dt.month)}/${dt.year} ${p(h)}:${p(dt.minute)} $ampm';
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: salaries.length,
      itemBuilder: (context, index) {
        final salary = salaries[index];
        
        String titleText;
        if (salary.createdAt != null) {
          titleText = 'Date: ${formatDateTime(salary.createdAt!.toLocal())}';
        } else if (salary.day != null) {
          titleText = 'Date: ${salary.day}/${salary.month}/${salary.year}';
        } else {
          titleText = 'Month: ${salary.month}/${salary.year}';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.payments, color: Color(0xFF2E7D32)),
            ),
            title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '+${salary.paidAmount.toStringAsFixed(2)}',
              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripsTab(bool isDark) {
    final tripsAsync = ref.watch(tripProvider);
    final driverId = widget.driver['id']?.toString() ?? '';

    return tripsAsync.when(
      data: (trips) {
        var driverTrips = trips.where((t) => t.driverId == driverId).toList();
        
        // Filter
        if (_selectedTripMonth != 'All Months') {
          driverTrips = driverTrips.where((t) => t.tripDate.month.toString() == _selectedTripMonth).toList();
        }
        if (_selectedTripYear != 'All Years') {
          driverTrips = driverTrips.where((t) => t.tripDate.year.toString() == _selectedTripYear).toList();
        }

        int totalTrips = driverTrips.length;
        double totalRent = 0;
        for (var t in driverTrips) {
          totalRent += t.rentAmount;
        }
        double totalSalary = totalRent * 0.15;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildAmountCard(
                      'Total Trips',
                      totalTrips.toDouble(),
                      const Color(0xFFE3EDF7),
                      const Color(0xFF1976D2),
                      Icons.route,
                      isDark,
                      isInt: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAmountCard(
                      'Total Rent',
                      totalRent,
                      const Color(0xFFF3E5F5),
                      const Color(0xFF8E24AA),
                      Icons.attach_money,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAmountCard(
                'Total Salary (15%)',
                totalSalary,
                const Color(0xFFFFF3E0),
                const Color(0xFFF57C00),
                Icons.trending_up,
                isDark,
                fullWidth: true,
              ),
              const SizedBox(height: 32),
              Text(
                'Filter Trips',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTripMonth,
                      decoration: InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'All Months', child: Text('All Months')),
                        ...List.generate(12, (index) => DropdownMenuItem(value: (index + 1).toString(), child: Text('${index + 1}')))
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTripMonth = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTripYear,
                      decoration: InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'All Years', child: Text('All Years')),
                        ...List.generate(10, (index) {
                          final year = DateTime.now().year - 5 + index;
                          return DropdownMenuItem(value: year.toString(), child: Text('$year'));
                        })
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTripYear = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Trip History',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (driverTrips.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('No trips found', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: driverTrips.length,
                  itemBuilder: (context, index) {
                    final trip = driverTrips[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.tripDetail, arguments: trip.id);
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE3EDF7),
                          child: const Icon(Icons.local_shipping, color: Color(0xFF1976D2)),
                        ),
                        title: Text('${trip.fromLocation} to ${trip.toLocation}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Date: ${trip.tripDate.toString().split(' ')[0]} • Status: ${trip.status.toUpperCase()}'),
                        trailing: Text('₹${trip.rentAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildProfileTab(bool isDark) {
    final driver = widget.driver;

    final fatherName = driver['father_name'] as String?;
    final homeAddress = driver['home_address'] as String?;
    final gender = driver['gender'] as String?;
    final dobStr = driver['date_of_birth'] as String?;
    final accNumber = driver['account_number'] as String?;
    final ifsc = driver['ifsc_code'] as String?;
    final branch = driver['branch_name'] as String?;
    final aadharUrl = driver['aadhar_card_url'] as String?;
    final dlUrl = driver['driving_license_url'] as String?;

    String ageStr = 'Not Provided';
    if (dobStr != null && dobStr.isNotEmpty) {
      try {
        final dob = DateTime.parse(dobStr);
        final today = DateTime.now();
        int age = today.year - dob.year;
        if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
        ageStr = '$age years';
      } catch (e) {
        // ignore format error
      }
    }

    Widget buildSection(String title, List<Widget> children) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
    }

    Widget buildRow(String label, String? value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value != null && value.isNotEmpty ? value : 'Not Provided',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildImageDoc(String title, String? url) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (url != null && url.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    child: const Center(child: Text('Failed to load image')),
                  );
                },
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text('Not Provided'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSection('Personal Information', [
            buildRow('Father\'s Name', fatherName),
            buildRow('Gender', gender),
            buildRow('Date of Birth', dobStr),
            buildRow('Age', ageStr),
            buildRow('Home Address', homeAddress),
          ]),
          buildSection('Bank Details', [
            buildRow('Account Number', accNumber),
            buildRow('IFSC Code', ifsc),
            buildRow('Branch Name', branch),
          ]),
          buildSection('ID Proofs', [
            buildImageDoc('Aadhar Card', aadharUrl),
            buildImageDoc('Driving License', dlUrl),
          ]),
        ],
      ),
    );
  }
}
