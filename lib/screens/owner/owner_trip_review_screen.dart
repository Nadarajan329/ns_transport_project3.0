import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../providers/trip_provider.dart';
import 'driver_management_screen.dart' show driversProvider;
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/core/theme/app_theme.dart';

class OwnerTripReviewScreen extends ConsumerStatefulWidget {
  const OwnerTripReviewScreen({super.key});

  @override
  ConsumerState<OwnerTripReviewScreen> createState() => _OwnerTripReviewScreenState();
}

class _OwnerTripReviewScreenState extends ConsumerState<OwnerTripReviewScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripProvider);
    final driversAsync = ref.watch(driversProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.get('trip_reviews', locale), style: AppTheme.getFont(locale, color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: tripsAsync.when(
        data: (trips) {
          final driversMap = driversAsync.maybeWhen(
            data: (drivers) => {for (var d in drivers) d['id'] as String: d['name'] as String? ?? AppTranslations.get('unknown_driver', locale)},
            orElse: () => <String, String>{},
          );

          final submittedTrips = trips.where((t) {
            if (t.status != 'submitted') return false;
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            final driverName = (driversMap[t.driverId] ?? t.driverId).toLowerCase();

            return driverName.contains(query) ||
                   t.fromLocation.toLowerCase().contains(query) ||
                   t.toLocation.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  style: AppTheme.getFont(locale),
                  decoration: InputDecoration(
                    hintText: AppTranslations.get('search_driver_location', locale),
                    hintStyle: AppTheme.getFont(locale),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              if (submittedTrips.isEmpty)
                Expanded(
                  child: EmptyState(
                    icon: Icons.check_circle_outline,
                    title: AppTranslations.get('no_pending_reviews', locale),
                    message: AppTranslations.get('no_submitted_trips_match', locale),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: submittedTrips.length,
                    itemBuilder: (context, index) {
                      final trip = submittedTrips[index];
                      final dateStr = DateFormat('MMM dd, yyyy').format(trip.tripDate);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          title: Text(
                            '${AppTranslations.get('driver_prefix', locale)}${driversMap[trip.driverId] ?? trip.driverId}',
                            style: AppTheme.getFont(locale, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.route, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${trip.fromLocation} to ${trip.toLocation}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.getFont(locale),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(dateStr, style: AppTheme.getFont(locale)),
                                  ],
                                ),
                              ],
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
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            '${AppTranslations.get('error', locale)}: $error',
            style: AppTheme.getFont(locale, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
