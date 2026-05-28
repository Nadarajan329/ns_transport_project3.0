import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/widgets/app_drawer.dart';
import 'package:ns_transport/widgets/empty_state.dart';
import 'package:ns_transport/widgets/status_badge.dart';
import 'package:ns_transport/utils/formatters.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider.notifier).loadTrips();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(tripProvider.notifier).loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final user = ref.watch(authProvider).value;

    final primaryColor = const Color(0xFF1565C0);


    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Driver Dashboard',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primaryColor,
        child: tripState.when(
          data: (trips) {
            final query = _searchQuery.toLowerCase();
            final filteredTrips = trips.where((t) {
              if (query.isEmpty) return true;
              return t.vehicleNumber.toLowerCase().contains(query) ||
                     t.fromLocation.toLowerCase().contains(query) ||
                     t.toLocation.toLowerCase().contains(query);
            }).toList();

            final activeTrips = filteredTrips.where((t) => t.status != 'draft').toList();
            final draftTrips = filteredTrips.where((t) => t.status == 'draft').toList();
            
            // Statistics calculations
            final totalTrips = filteredTrips.length;
            final pendingApprovals = filteredTrips.where((t) => t.status == 'submitted').length;
            final double totalRent = filteredTrips
                .where((t) => t.status == 'approved')
                .fold(0.0, (sum, item) => sum + item.rentAmount);

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.name ?? 'Driver',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Glassmorphic Statistics Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  'My Trips',
                                  totalTrips.toString(),
                                  Icons.local_shipping_outlined,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white30,
                                ),
                                _buildStatItem(
                                  'Pending',
                                  pendingApprovals.toString(),
                                  Icons.hourglass_empty,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white30,
                                ),
                                _buildStatItem(
                                  'Earnings',
                                  Formatters.formatCurrency(totalRent, compact: true),
                                  Icons.account_balance_wallet_outlined,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search trips...',
                              hintStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.search, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: primaryColor,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'My Trips'),
                          Tab(text: 'Drafts'),
                          Tab(text: 'All History'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildTripList(activeTrips, 'No submitted trips yet.'),
                  _buildTripList(draftTrips, 'No draft reports saved.', isDraft: true),
                  _buildTripList(filteredTrips, 'No trips in history.'),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error loading dashboard: $err',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.tripForm).then((_) {
            ref.read(tripProvider.notifier).loadTrips();
          });
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('New Trip', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTripList(List<dynamic> list, String emptyMessage, {bool isDraft = false}) {
    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: EmptyState(
            icon: isDraft ? Icons.edit_note : Icons.local_shipping_outlined,
            title: isDraft ? 'No Drafts' : 'No Trips',
            message: emptyMessage,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final trip = list[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip.vehicleNumber,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                StatusBadge(status: trip.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${trip.fromLocation} → ${trip.toLocation}',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatDate(trip.tripDate),
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.formatCurrency(trip.rentAmount),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.tripDetail,
                arguments: trip.id,
              ).then((_) {
                ref.read(tripProvider.notifier).loadTrips();
              });
            },
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
