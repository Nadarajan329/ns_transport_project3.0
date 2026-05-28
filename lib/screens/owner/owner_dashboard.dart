import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/widgets/app_drawer.dart';
import 'package:ns_transport/widgets/summary_card.dart';
import 'package:ns_transport/widgets/status_badge.dart';
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

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    int totalTrips = 0;
    int pendingReports = 0;
    double totalIncome = 0;
    double netProfit = 0;

    final trips = tripState.value ?? [];
    
    totalTrips = trips.length;
    for (var trip in trips) {
      if (trip.status == 'submitted') {
        pendingReports++;
      }
      totalIncome += trip.rentAmount;
      netProfit += (trip.netProfit ?? 0.0);
    }

    // Filter to get submitted trips and take the first few (assuming latest are first or we could sort)
    final recentSubmittedTrips = trips.where((t) => t.status == 'submitted').toList();
    final recentTrips = recentSubmittedTrips.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: const Color(0xFF1565C0), // Primary
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: tripState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.2,
                      children: [
                        SummaryCard(
                          title: 'Total Trips',
                          value: totalTrips.toString(),
                          icon: Icons.local_shipping,
                          color: const Color(0xFF1565C0), // Primary
                        ),
                        SummaryCard(
                          title: 'Pending Reports',
                          value: pendingReports.toString(),
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                        ),
                        SummaryCard(
                          title: 'Total Income',
                          value: '₹${totalIncome.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
                        ),
                        SummaryCard(
                          title: 'Net Profit',
                          value: '₹${netProfit.toStringAsFixed(0)}',
                          icon: Icons.trending_up,
                          color: const Color(0xFF42A5F5), // PrimaryLight
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Income & Profit Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (totalIncome > 0 ? totalIncome : 10000) * 1.2,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('Income');
                                  if (value == 1) return const Text('Profit');
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('');
                                  return Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.withValues(alpha: 0.2),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: totalIncome,
                                  color: Colors.green,
                                  width: 24,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: netProfit,
                                  color: const Color(0xFF42A5F5),
                                  width: 24,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Recent Submitted Trips',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (recentTrips.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text('No pending submitted trips.'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentTrips.length,
                        itemBuilder: (context, index) {
                          final trip = recentTrips[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                trip.vehicleNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${trip.fromLocation} → ${trip.toLocation}',
                                ),
                              ),
                              trailing: StatusBadge(status: trip.status),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.tripDetail,
                                  arguments: trip.id,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
