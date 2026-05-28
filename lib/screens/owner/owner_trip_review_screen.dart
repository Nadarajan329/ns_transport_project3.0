import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../providers/trip_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Reviews'),
      ),
      drawer: const AppDrawer(),
      body: tripsAsync.when(
        data: (trips) {
          final submittedTrips = trips.where((t) {
            if (t.status != 'submitted') return false;
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return t.driverId.toLowerCase().contains(query) ||
                   t.fromLocation.toLowerCase().contains(query) ||
                   t.toLocation.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by driver or location...',
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
                const Expanded(
                  child: EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No Pending Reviews',
                    message: 'No submitted trips match your search.',
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
                            'Driver: ${trip.driverId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(dateStr),
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
            'Error loading trips: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
