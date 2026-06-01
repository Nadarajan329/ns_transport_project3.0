import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/providers/salary_provider.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/providers/advance_provider.dart';
import 'package:ns_transport/models/salary_model.dart';
import 'package:ns_transport/models/advance_history_model.dart';
import 'package:ns_transport/widgets/app_drawer.dart';
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DriverSalaryScreen extends ConsumerStatefulWidget {
  const DriverSalaryScreen({super.key});

  @override
  ConsumerState<DriverSalaryScreen> createState() => _DriverSalaryScreenState();
}

class _DriverSalaryScreenState extends ConsumerState<DriverSalaryScreen> {
  final _advanceFormKey = GlobalKey<FormState>();
  final _advanceAmountController = TextEditingController();
  final _advanceDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salaryProvider.notifier).loadSalaries();
      ref.read(tripProvider.notifier).loadTrips();
    });
  }

  @override
  void dispose() {
    _advanceAmountController.dispose();
    _advanceDescController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(salaryProvider.notifier).loadSalaries();
    await ref.read(tripProvider.notifier).loadTrips();
  }

  void _recordAdvance() async {
    if (!_advanceFormKey.currentState!.validate()) return;

    final amount = double.tryParse(_advanceAmountController.text) ?? 0;
    if (amount <= 0) return;

    final user = ref.read(authProvider).value;
    final driverId = user?.id ?? '';
    final description = _advanceDescController.text.isEmpty ? 'Rent Advance' : _advanceDescController.text;

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final driverId = user?.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF1565C0);

    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.get('my_salary', locale), style: AppTheme.getFont(locale, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primaryColor,
        child: _buildSalaryContent(driverId, isDark, locale),
      ),
    );
  }

  Widget _buildSalaryContent(String driverId, bool isDark, String locale) {
    final salariesAsync = ref.watch(salaryProvider);
    final tripsAsync = ref.watch(tripProvider);
    final advanceAsync = ref.watch(advanceHistoryProvider(driverId));

    if (salariesAsync.isLoading || tripsAsync.isLoading || advanceAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (salariesAsync.hasError || tripsAsync.hasError || advanceAsync.hasError) {
      return Center(child: Text('Error loading data', style: TextStyle(color: Colors.red)));
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
      physics: const AlwaysScrollableScrollPhysics(),
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
            AppTranslations.get('rent_advance', locale),
            style: AppTheme.getFont(locale,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildAddAdvanceForm(isDark, locale),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isInt ? amount.toInt().toString() : amount.toStringAsFixed(2),
              style: GoogleFonts.inter(
                color: iconColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
                label: Text(AppTranslations.get('record_rent_advance', locale), style: AppTheme.getFont(locale, color: Colors.white, fontSize: 16)),
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
            Text('No advance history found', style: TextStyle(color: Colors.grey.shade500)),
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
            title: Text(item.description ?? (isGiven ? 'Advance Received' : 'Expense Deducted'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: item.createdAt != null ? Text(formatDateTime(item.createdAt!.toLocal())) : null,
            trailing: Text(
              '${isGiven ? '+' : '-'}${item.amount.toStringAsFixed(2)}',
              style: TextStyle(
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
}
