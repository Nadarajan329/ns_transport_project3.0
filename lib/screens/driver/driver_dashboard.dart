import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/widgets/gradient_text.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/providers/salary_provider.dart';
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/core/theme/app_theme.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/widgets/app_drawer.dart';
import 'package:ns_transport/widgets/empty_state.dart';
import 'package:ns_transport/widgets/status_badge.dart';
import 'package:ns_transport/utils/formatters.dart';
import 'package:ns_transport/services/location_service.dart';
import 'package:ns_transport/widgets/notification_bell.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _glitterController;
  String _searchQuery = '';
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _glitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider.notifier).loadTrips();
      ref.read(salaryProvider.notifier).loadSalaries();
      _startLocationTracking();
    });
  }

  Future<void> _startLocationTracking() async {
    final hasPermission = await LocationService.instance.checkPermission();
    if (hasPermission) {
      await LocationService.instance.startTracking(intervalSeconds: 30);
      if (mounted) setState(() => _locationEnabled = true);
    } else {
      if (mounted) setState(() => _locationEnabled = false);
    }
  }

  @override
  void dispose() {
    LocationService.instance.stopTracking();
    _glitterController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(tripProvider.notifier).loadTrips(),
      ref.read(salaryProvider.notifier).loadSalaries(),
    ]);
  }

  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final salaryState = ref.watch(salaryProvider);
    final user = ref.watch(authProvider).value;
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final headerColor = isDark ? Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFF1E1E1E) : const Color(0xFF1565C0);


    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTranslations.get('driver_dashboard', locale),
          style: AppTheme.getFont(locale, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: headerColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          const NotificationBell(),
          Tooltip(
            message: _locationEnabled ? 'Live location active' : 'Location off — tap to enable',
            child: IconButton(
              icon: Icon(
                _locationEnabled ? Icons.location_on : Icons.location_off,
                color: _locationEnabled ? Colors.greenAccent : Colors.white70,
              ),
              onPressed: () async {
                if (!_locationEnabled) {
                  await _startLocationTracking();
                  if (mounted && _locationEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live location enabled')),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location permission denied. Please enable it in settings.')),
                    );
                  }
                } else {
                  LocationService.instance.stopTracking();
                  setState(() => _locationEnabled = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live location disabled')),
                    );
                  }
                }
              },
            ),
          ),
        ],
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
            
            final double totalEarned = activeTrips.fold(0.0, (sum, trip) => sum + (trip.rentAmount * 0.15));
            final double totalPaid = salaryState.value?.where((s) => s.driverId == user?.id).fold(0.0, (sum, item) => sum! + item.paidAmount) ?? 0.0;
            final double totalDriverSalary = totalEarned - totalPaid;

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
                          colors: [headerColor, isDark ? headerColor.withValues(alpha: 0.9) : primaryColor.withValues(alpha: 0.8)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.get('welcome_back', locale),
                            style: AppTheme.getFont(locale,
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          isDark 
                            ? GradientText(
                              user?.name ?? AppTranslations.get('driver', locale),
                              gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]),
                              style: AppTheme.getFont(locale,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : Text(
                              user?.name ?? AppTranslations.get('driver', locale),
                              style: AppTheme.getFont(locale,
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 20),
                          
                          // Glassmorphic Statistics Card with Glitter
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: AnimatedBuilder(
                                animation: _glitterController,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Shimmer sweep overlay
                                        if (!isDark)
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.white.withValues(alpha: 0.08),
                                                      Colors.white.withValues(alpha: 0.18),
                                                      Colors.white.withValues(alpha: 0.08),
                                                      Colors.transparent,
                                                    ],
                                                    stops: [
                                                      0.0,
                                                      (_glitterController.value - 0.15).clamp(0.0, 1.0),
                                                      _glitterController.value,
                                                      (_glitterController.value + 0.15).clamp(0.0, 1.0),
                                                      1.0,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        // Glitter sparkle dots
                                        if (!isDark)
                                          ..._buildGlitterDots(_glitterController.value),
                                        // Content
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildStatItem(
                                              AppTranslations.get('my_trips', locale),
                                              totalTrips.toString(),
                                              Icons.local_shipping_outlined,
                                              isDark,
                                              locale,
                                            ),
                                            Container(
                                              width: 1,
                                              height: 40,
                                              color: Colors.white30,
                                            ),
                                            _buildStatItem(
                                              AppTranslations.get('earnings', locale),
                                              Formatters.formatCurrency(totalDriverSalary, compact: true),
                                              Icons.account_balance_wallet_outlined,
                                              isDark,
                                              locale,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            decoration: InputDecoration(
                              hintText: AppTranslations.get('search_trips', locale),
                              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.white70),
                              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
                        tabs: [
                          Tab(text: AppTranslations.get('my_trips', locale)),
                          Tab(text: AppTranslations.get('drafts', locale)),
                          Tab(text: AppTranslations.get('all_history', locale)),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildTripList(activeTrips, AppTranslations.get('no_submitted_trips', locale), locale),
                  _buildTripList(draftTrips, AppTranslations.get('no_draft_reports', locale), locale, isDraft: true),
                  _buildTripList(filteredTrips, AppTranslations.get('no_trips_history', locale), locale),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Center(
            child: Text(
              '${AppTranslations.get('error_loading', locale)}: $err',
              style: AppTheme.getFont(locale, color: Colors.red),
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
        label: Text(AppTranslations.get('new_trip', locale), style: AppTheme.getFont(locale, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark, String locale) {
    return Column(
      children: [
        Icon(icon, color: isDark ? Theme.of(context).colorScheme.primary : Colors.white, size: 24),
        const SizedBox(height: 6),
        isDark 
          ? GradientText(
              value,
              gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]),
              style: AppTheme.getFont(locale,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : Text(
              value,
              style: AppTheme.getFont(locale,
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
        Text(
          label,
          style: AppTheme.getFont(locale,
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGlitterDots(double animValue) {
    final random = Random(42); // Fixed seed for consistent positions
    return List.generate(12, (index) {
      final dx = random.nextDouble();
      final dy = random.nextDouble();
      final phase = (animValue + index * 0.08) % 1.0;
      final opacity = (sin(phase * pi * 2) * 0.5 + 0.5) * 0.7;
      final size = 2.0 + random.nextDouble() * 3.0;
      return Positioned(
        left: dx * 280,
        top: dy * 70,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTripList(List<dynamic> list, String emptyMessage, String locale, {bool isDraft = false}) {
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
            side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip.vehicleNumber,
                  style: AppTheme.getFont(locale,
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
                        style: AppTheme.getFont(locale, fontSize: 14),
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
                      style: AppTheme.getFont(locale, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.formatCurrency(trip.rentAmount),
                      style: AppTheme.getFont(locale,
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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
