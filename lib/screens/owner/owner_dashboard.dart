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

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, bool isDark, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Owner Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5, color: Colors.white, inherit: false),
        ),
        backgroundColor: isDark ? Theme.of(context).appBarTheme.backgroundColor : const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
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
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE3EDF7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to NS\nTransport',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF102A43),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Manage your employees, approve submissions,\nand track performance efficiently.',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey.shade300 : const Color(0xFF334E68),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Quick Statistics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF102A43),
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
                          isDark, context
                        ),
                        _buildStatCard(
                          'Pending Approvals',
                          pendingReports.toString(),
                          Icons.assignment_turned_in,
                          const Color(0xFFF39C12), // Orange
                          isDark, context
                        ),
                        _buildStatCard(
                          'Monthly Earnings',
                          '₹${totalIncome.toStringAsFixed(0)}',
                          Icons.trending_up,
                          const Color(0xFF2ECC71), // Green
                          isDark, context
                        ),
                        _buildStatCard(
                          'Total Trips',
                          totalTrips.toString(),
                          Icons.directions_car,
                          const Color(0xFF9B59B6), // Purple
                          isDark, context
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 140,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quick actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(Icons.person_add, 'Add Driver', isDark, context),
                        _buildActionButton(Icons.add_road, 'New Route', isDark, context),
                        _buildActionButton(Icons.receipt_long, 'Reports', isDark, context),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, bool isDark, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Icon(icon, color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2), size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334E68),
          ),
        ),
      ],
    );
  }
}
