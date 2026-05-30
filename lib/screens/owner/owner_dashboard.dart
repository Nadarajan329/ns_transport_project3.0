import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/widgets/gradient_text.dart';
import 'package:ns_transport/providers/trip_provider.dart';
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/core/theme/app_theme.dart';
import 'package:ns_transport/widgets/app_drawer.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/screens/owner/driver_management_screen.dart';

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

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, bool isDark, BuildContext context, String locale) {
    if (isDark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
                const Spacer(),
                isDark
                  ? GradientText(
                      value,
                      gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]),
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : Text(
                      value,
                      style: AppTheme.getFont(locale, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTheme.getFont(locale, fontSize: 14, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
            style: AppTheme.getFont(locale, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.getFont(locale, fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final driversState = ref.watch(driversProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    final totalEmployees = driversState.valueOrNull?.length ?? 0;

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
        title: Text(
          AppTranslations.get('owner_dashboard', locale),
          style: AppTheme.getFont(locale, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5, color: Colors.white),
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
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE3EDF7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isDark
                            ? GradientText(
                                AppTranslations.get('welcome_ns_transport', locale),
                                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF2979FF)]),
                                style: AppTheme.getFont(locale,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              )
                            : Text(
                                AppTranslations.get('welcome_ns_transport', locale),
                                style: AppTheme.getFont(locale,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF102A43),
                                  height: 1.2,
                                ),
                              ),
                          const SizedBox(height: 16),
                          Text(
                            AppTranslations.get('manage_employees_desc', locale),
                            style: AppTheme.getFont(locale,
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
                      AppTranslations.get('quick_statistics', locale),
                      style: AppTheme.getFont(locale,
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
                          AppTranslations.get('total_employees', locale),
                          totalEmployees.toString(),
                          Icons.people,
                          const Color(0xFF3498DB), // Blue
                          isDark, context, locale
                        ),
                        _buildStatCard(
                          AppTranslations.get('pending_approvals', locale),
                          pendingReports.toString(),
                          Icons.assignment_turned_in,
                          const Color(0xFFF39C12), // Orange
                          isDark, context, locale
                        ),
                        _buildStatCard(
                          AppTranslations.get('monthly_earnings', locale),
                          '₹${totalIncome.toStringAsFixed(0)}',
                          Icons.trending_up,
                          const Color(0xFF2ECC71), // Green
                          isDark, context, locale
                        ),
                        _buildStatCard(
                          AppTranslations.get('total_trips', locale),
                          totalTrips.toString(),
                          Icons.directions_car,
                          const Color(0xFF9B59B6), // Purple
                          isDark, context, locale
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.outfit(
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
                        _buildActionButton(Icons.person_add, 'Add Driver', isDark, context,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.driverManagement),
                        ),
                        _buildActionButton(Icons.map, 'Map', isDark, context,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.driverLocations),
                        ),
                        _buildActionButton(Icons.receipt_long, 'Reports', isDark, context,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.ownerTripReview),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, bool isDark, BuildContext context, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              shape: BoxShape.circle,
              border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
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
            child: Icon(icon, color: isDark ? Theme.of(context).colorScheme.primary : const Color(0xFF1976D2), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334E68),
            ),
          ),
        ],
      ),
    );
  }
}
