import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../widgets/app_drawer.dart';
import '../../widgets/empty_state.dart';
import '../../providers/salary_provider.dart';
import '../../utils/formatters.dart';

class OwnerSalaryScreen extends ConsumerStatefulWidget {
  const OwnerSalaryScreen({super.key});

  @override
  ConsumerState<OwnerSalaryScreen> createState() => _OwnerSalaryScreenState();
}

class _OwnerSalaryScreenState extends ConsumerState<OwnerSalaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salaryProvider.notifier).loadSalaries();
    });
  }

  void _showPaymentDialog(BuildContext context, String initialDriverId) {
    final formKey = GlobalKey<FormState>();
    String selectedDriverId = initialDriverId;
    String paymentType = 'advance';
    double amount = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Payment'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: selectedDriverId,
                  decoration: const InputDecoration(
                    labelText: 'Driver ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  onSaved: (value) => selectedDriverId = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: paymentType,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'advance', child: Text('Advance Payment')),
                    DropdownMenuItem(value: 'salary', child: Text('Salary Settlement')),
                  ],
                  onChanged: (value) {
                    if (value != null) paymentType = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Invalid amount';
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value ?? '0'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  // TODO: Save payment using salary provider or payment provider
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Recorded $paymentType of ₹${amount.toStringAsFixed(2)} for $selectedDriverId',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salariesAsync = ref.watch(salaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salaries & Payments'),
      ),
      drawer: const AppDrawer(),
      body: salariesAsync.when(
        data: (salaries) {
          if (salaries.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Salary Records',
              message: 'There are no salary records for the current period.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: salaries.length,
            itemBuilder: (context, index) {
              final salary = salaries[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Driver: ${salary.driverId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: salary.status == 'paid'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              salary.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: salary.status == 'paid'
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAmountColumn('Base Salary', salary.baseSalary),
                          _buildAmountColumn('Advances', salary.advances),
                          _buildAmountColumn(
                            'Net Payable',
                            salary.netSalary,
                            isHighlight: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.payment),
                          label: const Text('Record Payment'),
                          onPressed: () => _showPaymentDialog(context, salary.driverId),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading salaries: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(context, ''),
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? const Color(0xFF1565C0) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
