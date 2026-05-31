import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/providers/salary_provider.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/models/salary_model.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/providers/advance_provider.dart';
import 'package:ns_transport/models/advance_history_model.dart';
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  
  final _advanceFormKey = GlobalKey<FormState>();
  final _advanceAmountController = TextEditingController();
  final _advanceDescController = TextEditingController();
  
  final _deductAdvanceFormKey = GlobalKey<FormState>();
  final _deductAdvanceAmountController = TextEditingController();

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
    _advanceAmountController.dispose();
    _advanceDescController.dispose();
    _deductAdvanceAmountController.dispose();
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
        SnackBar(content: Text(AppTranslations.get('payment_success', ref.read(localeProvider)))),
      );
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppTranslations.get('failed_payment', ref.read(localeProvider))}: $e')),
      );
    }
  }

  void _recordAdvance() async {
    if (!_advanceFormKey.currentState!.validate()) return;

    final amount = double.tryParse(_advanceAmountController.text) ?? 0;
    if (amount <= 0) return;

    final driverId = widget.driver['id']?.toString() ?? '';
    final description = _advanceDescController.text.isEmpty ? 'Advance Payment' : _advanceDescController.text;

    try {
      await ref.read(advanceHistoryProvider(driverId).notifier).giveAdvance(amount, description);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.get('rent_advance_success', ref.read(localeProvider)))),
      );
      _advanceAmountController.clear();
      _advanceDescController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppTranslations.get('failed_advance', ref.read(localeProvider))}: $e')),
      );
    }
  }

  void _recordAdvanceDeduction() async {
    if (!_deductAdvanceFormKey.currentState!.validate()) return;

    final amount = double.tryParse(_deductAdvanceAmountController.text) ?? 0;
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
        advanceAmount: amount, // Used to identify this specific type of transaction in history
        month: month,
        year: year,
        day: day,
      );

      await ref.read(salaryProvider.notifier).upsertSalary(salary);
      await ref.read(advanceHistoryProvider(driverId).notifier).deductAdvance(amount, AppTranslations.get('advance_deduction', ref.read(localeProvider)));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.get('payment_success', ref.read(localeProvider)))),
      );
      _deductAdvanceAmountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppTranslations.get('failed_payment', ref.read(localeProvider))}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.driver['name'] ?? 'Unknown';
    final driverEmail = widget.driver['email'] ?? '';
    final driverPhone = widget.driver['phone'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          driverName,
          style: AppTheme.getFont(locale, color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                              AppTranslations.get('active', locale),
                              style: AppTheme.getFont(locale,
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
            tabs: [
              Tab(icon: const Icon(Icons.person), text: AppTranslations.get('profile_info', locale)),
              Tab(icon: const Icon(Icons.attach_money), text: AppTranslations.get('salary', locale)),
              Tab(icon: const Icon(Icons.route), text: AppTranslations.get('trips', locale)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(isDark, locale),
                _buildSalaryTab(isDark, locale),
                _buildTripsTab(isDark, locale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryTab(bool isDark, String locale) {
    final driverId = widget.driver['id']?.toString() ?? '';
    final salariesAsync = ref.watch(salaryProvider);
    final tripsAsync = ref.watch(tripProvider);
    final advanceAsync = ref.watch(advanceHistoryProvider(driverId));

    if (salariesAsync.isLoading || tripsAsync.isLoading || advanceAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (salariesAsync.hasError || tripsAsync.hasError || advanceAsync.hasError) {
      return Center(child: Text('Error loading data'));
    }

    final salaries = salariesAsync.value ?? [];
    final trips = tripsAsync.value ?? [];
    final advanceHistory = advanceAsync.value ?? [];

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
    
    double advanceBalance = advanceHistory.fold(0.0, (sum, item) => item.type == 'given_by_owner' ? sum + item.amount : sum - item.amount);

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
                      AppTranslations.get('total_salary', locale),
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
                      AppTranslations.get('paid_amount', locale),
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
              Row(
                children: [
                  Expanded(
                    child: _buildAmountCard(
                      AppTranslations.get('salary_balance', locale),
                      balance.abs(),
                      balance > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                      balance > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                      Icons.balance,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAmountCard(
                      AppTranslations.get('advance_balance', locale),
                      advanceBalance.abs(),
                      advanceBalance < 0 ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0),
                      advanceBalance < 0 ? const Color(0xFFC62828) : const Color(0xFFEF6C00),
                      Icons.money_off,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                AppTranslations.get('add_payment', locale),
                style: AppTheme.getFont(locale,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildAddPaymentForm(isDark, locale),
              const SizedBox(height: 32),
              Text(
                AppTranslations.get('give_advance', locale),
                style: AppTheme.getFont(locale,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildAddAdvanceForm(isDark, locale),
              const SizedBox(height: 32),
              Text(
                AppTranslations.get('deduct_advance_from_salary', locale),
                style: AppTheme.getFont(locale,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeductAdvanceForm(isDark, locale),
              const SizedBox(height: 32),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    AppTranslations.get('payment_history', locale),
                    style: AppTheme.getFont(locale,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 12),
                    _buildPaymentHistory(driverSalaries, isDark, locale),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    AppTranslations.get('advance_history', locale),
                    style: AppTheme.getFont(locale,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 12),
                    _buildAdvanceHistory(advanceHistory, isDark, locale),
                  ],
                ),
              ),
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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

  Widget _buildAddPaymentForm(bool isDark, String locale) {
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
                labelText: AppTranslations.get('amount_paid', locale),
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF1976D2)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => val == null || val.isEmpty ? AppTranslations.get('required', locale) : null,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _recordPayment,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(AppTranslations.get('record_payment', locale), style: AppTheme.getFont(locale, color: Colors.white, fontSize: 16)),
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

  Widget _buildAddAdvanceForm(bool isDark, String locale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Form(
        key: _advanceFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _advanceAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppTranslations.get('amount', locale),
                prefixIcon: const Icon(Icons.money, color: Color(0xFFEF6C00)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => val == null || val.isEmpty ? AppTranslations.get('required', locale) : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _advanceDescController,
              decoration: InputDecoration(
                labelText: AppTranslations.get('description_optional', locale),
                prefixIcon: const Icon(Icons.description, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _recordAdvance,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(AppTranslations.get('give_advance', locale), style: AppTheme.getFont(locale, color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductAdvanceForm(bool isDark, String locale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Form(
        key: _deductAdvanceFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _deductAdvanceAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppTranslations.get('amount', locale),
                prefixIcon: const Icon(Icons.money_off, color: Color(0xFF1976D2)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => val == null || val.isEmpty ? AppTranslations.get('required', locale) : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _recordAdvanceDeduction,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(AppTranslations.get('deduct_advance_from_salary', locale), style: AppTheme.getFont(locale, color: Colors.white, fontSize: 16)),
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

  Widget _buildPaymentHistory(List<SalaryModel> salaries, bool isDark, String locale) {
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
            Text(AppTranslations.get('no_payment_history', locale), style: AppTheme.getFont(locale, color: Colors.grey.shade500)),
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

        final isAdvanceDeduction = salary.advanceAmount > 0;
        final card = Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAdvanceDeduction ? const Color(0xFFE3EDF7) : const Color(0xFFE8F5E9),
              child: Icon(isAdvanceDeduction ? Icons.money_off : Icons.payments, color: isAdvanceDeduction ? const Color(0xFF1976D2) : const Color(0xFF2E7D32)),
            ),
            title: Text(isAdvanceDeduction ? AppTranslations.get('advance_deduction', locale) : titleText, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: isAdvanceDeduction ? Text(titleText, style: const TextStyle(fontSize: 12)) : null,
            trailing: Text(
              '+${salary.paidAmount.toStringAsFixed(2)}',
              style: TextStyle(color: isAdvanceDeduction ? const Color(0xFF1976D2) : const Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );

        return card.animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1500.ms, 
          color: isAdvanceDeduction ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.15),
        );
      },
    );
  }

  Widget _buildAdvanceHistory(List<AdvanceHistoryModel> history, bool isDark, String locale) {
    if (history.isEmpty) {
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
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(AppTranslations.get('no_advance_history', locale), style: AppTheme.getFont(locale, color: Colors.grey.shade500)),
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
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final isGiven = item.type == 'given_by_owner';
        
        final card = Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isGiven ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              child: Icon(isGiven ? Icons.arrow_downward : Icons.arrow_upward, color: isGiven ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
            ),
            title: Text(item.description ?? (isGiven ? AppTranslations.get('advance_given', locale) : AppTranslations.get('expense_deducted', locale)), style: AppTheme.getFont(locale, fontWeight: FontWeight.bold)),
            subtitle: item.createdAt != null ? Text(formatDateTime(item.createdAt!.toLocal()), style: AppTheme.getFont(locale)) : null,
            trailing: Text(
              '${isGiven ? '+' : '-'}${item.amount.toStringAsFixed(2)}',
              style: AppTheme.getFont(locale,
                color: isGiven ? const Color(0xFF2E7D32) : const Color(0xFFC62828), 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              ),
            ),
          ),
        );

        return card.animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1500.ms,
          color: isGiven ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        );
      },
    );
  }

  Widget _buildTripsTab(bool isDark, String locale) {
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
                      AppTranslations.get('total_trips_owner', locale),
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
                      AppTranslations.get('total_rent', locale),
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
                AppTranslations.get('total_salary_15', locale),
                totalSalary,
                const Color(0xFFFFF3E0),
                const Color(0xFFF57C00),
                Icons.trending_up,
                isDark,
                fullWidth: true,
              ),
              const SizedBox(height: 32),
              Text(
                AppTranslations.get('filter_trips', locale),
                style: AppTheme.getFont(locale,
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
                      isExpanded: true,
                      value: _selectedTripMonth,
                      decoration: InputDecoration(
                        labelText: AppTranslations.get('month', locale),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(value: 'All Months', child: Text(AppTranslations.get('all_months', locale))),
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
                      isExpanded: true,
                      value: _selectedTripYear,
                      decoration: InputDecoration(
                        labelText: AppTranslations.get('year', locale),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(value: 'All Years', child: Text(AppTranslations.get('all_years', locale))),
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
                AppTranslations.get('trip_history', locale),
                style: AppTheme.getFont(locale,
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
                    child: Text(AppTranslations.get('no_trips_found', locale), style: AppTheme.getFont(locale, color: Colors.grey.shade500)),
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
                        title: Text('${trip.fromLocation} to ${trip.toLocation}', style: AppTheme.getFont(locale, fontWeight: FontWeight.bold)),
                        subtitle: Text('${AppTranslations.get('date', locale)}: ${trip.tripDate.toString().split(' ')[0]} • ${AppTranslations.get('status', locale)}: ${trip.status.toUpperCase()}', style: AppTheme.getFont(locale)),
                        trailing: Text('₹${trip.rentAmount.toStringAsFixed(0)}', style: AppTheme.getFont(locale, fontWeight: FontWeight.bold)),
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

  Widget _buildProfileTab(bool isDark, String locale) {
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

    String ageStr = AppTranslations.get('not_provided', locale);
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
              style: AppTheme.getFont(locale,
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
                style: AppTheme.getFont(locale,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value != null && value.isNotEmpty ? value : AppTranslations.get('not_provided', locale),
                style: AppTheme.getFont(locale,
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
            style: AppTheme.getFont(locale,
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
              child: Center(
                child: Text(AppTranslations.get('not_provided', locale), style: AppTheme.getFont(locale)),
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
          buildSection(AppTranslations.get('personal_information', locale), [
            buildRow(AppTranslations.get('fathers_name', locale), fatherName),
            buildRow(AppTranslations.get('gender', locale), gender),
            buildRow(AppTranslations.get('date_of_birth', locale), dobStr),
            buildRow(AppTranslations.get('age', locale), ageStr),
            buildRow(AppTranslations.get('home_address', locale), homeAddress),
          ]),
          buildSection(AppTranslations.get('bank_details', locale), [
            buildRow(AppTranslations.get('account_number', locale), accNumber),
            buildRow(AppTranslations.get('ifsc_code', locale), ifsc),
            buildRow(AppTranslations.get('branch_name', locale), branch),
          ]),
          buildSection(AppTranslations.get('id_proofs', locale), [
            buildImageDoc(AppTranslations.get('aadhar_card', locale), aadharUrl),
            buildImageDoc(AppTranslations.get('driving_license', locale), dlUrl),
          ]),
        ],
      ),
    );
  }
}
