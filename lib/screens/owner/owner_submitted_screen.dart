import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/app_drawer.dart';

class OwnerSubmittedScreen extends ConsumerStatefulWidget {
  const OwnerSubmittedScreen({super.key});

  @override
  ConsumerState<OwnerSubmittedScreen> createState() => _OwnerSubmittedScreenState();
}

class _OwnerSubmittedScreenState extends ConsumerState<OwnerSubmittedScreen> {
  String selectedMonth = 'May';
  String selectedYear = '2026';
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'submitted',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.0, color: Colors.white, inherit: false),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDropdown(
                  value: selectedMonth,
                  items: const [
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                  ],
                  onChanged: (val) => setState(() => selectedMonth = val!),
                ),
                _buildDropdown(
                  value: selectedYear,
                  items: List.generate(20, (index) => (2020 + index).toString()),
                  onChanged: (val) => setState(() => selectedYear = val!),
                ),
                _buildDropdown(
                  value: selectedFilter,
                  items: ['All', 'Approved', 'Pending'],
                  onChanged: (val) => setState(() => selectedFilter = val!),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    size: 90,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No submissions found',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No submissions for $selectedMonth $selectedYear',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      elevation: 16,
      style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
      underline: Container(
        height: 1,
        color: Colors.grey.shade300,
      ),
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
