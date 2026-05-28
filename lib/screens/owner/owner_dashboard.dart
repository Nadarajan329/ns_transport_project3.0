import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/widgets/app_drawer.dart';
import 'package:ns_transport/routes/app_routes.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider.notifier).loadTrips();
    });
  }

  Future<void> _refresh() async {
    await ref.read(tripProvider.notifier).loadTrips();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    int totalTrips = 0;
    int pendingReports = 0;
    double totalIncome = 0;

    final trips = tripState.value ?? [];
    
    totalTrips = trips.length;
    for (var trip in trips) {
      if (trip.status == 'submitted') {
        pendingReports++;
      }
      totalIncome += trip.rentAmount;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Owner Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: tripState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3EDF7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome to NS\nTransport',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102A43),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Manage your employees, approve submissions,\nand track performance efficiently.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF334E68),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Quick Statistics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.1,
                      children: [
                        _buildStatCard(
                          'Total Employees',
                          '--',
                          Icons.people,
                          const Color(0xFF3498DB), // Blue
                        ),
                        _buildStatCard(
                          'Pending Approvals',
                          pendingReports.toString(),
                          Icons.assignment_turned_in,
                          const Color(0xFFF39C12), // Orange
                        ),
                        _buildStatCard(
                          'Monthly Earnings',
                          '₹${totalIncome.toStringAsFixed(0)}',
                          Icons.trending_up,
                          const Color(0xFF2ECC71), // Green
                        ),
                        _buildStatCard(
                          'Total Trips',
                          totalTrips.toString(),
                          Icons.directions_car,
                          const Color(0xFF9B59B6), // Purple
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 140,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quick actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(Icons.person_add, 'Add Driver'),
                        _buildActionButton(Icons.add_road, 'New Route'),
                        _buildActionButton(Icons.receipt_long, 'Reports'),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF1976D2), size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF334E68),
          ),
        ),
      ],
    );
  }
}
