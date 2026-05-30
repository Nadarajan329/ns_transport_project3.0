import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that fetches all drivers with their location data from Supabase.
final driverLocationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('users')
      .select()
      .eq('role', 'driver');
  return List<Map<String, dynamic>>.from(response);
});

class DriverLocationsScreen extends ConsumerStatefulWidget {
  const DriverLocationsScreen({super.key});

  @override
  ConsumerState<DriverLocationsScreen> createState() =>
      _DriverLocationsScreenState();
}

class _DriverLocationsScreenState extends ConsumerState<DriverLocationsScreen> {
  final MapController _mapController = MapController();
  String? _selectedDriverId;

  // Default center — India
  static const _defaultCenter = LatLng(11.1271, 78.6569);
  static const _defaultZoom = 7.0;

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driverLocationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Locations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            inherit: false,
          ),
        ),
        backgroundColor:
            isDark ? Theme.of(context).appBarTheme.backgroundColor : const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Reset view',
            onPressed: () {
              _mapController.move(_defaultCenter, _defaultZoom);
              setState(() => _selectedDriverId = null);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(driverLocationsProvider),
          ),
        ],
      ),
      body: driversAsync.when(
        data: (drivers) => _buildMapView(drivers, isDark),
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading driver locations...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(driverLocationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(List<Map<String, dynamic>> drivers, bool isDark) {
    // Build markers for drivers that have lat/lng
    final List<Marker> markers = [];
    final List<Map<String, dynamic>> driversWithLocation = [];

    for (final driver in drivers) {
      final lat = driver['latitude'] as num?;
      final lng = driver['longitude'] as num?;

      if (lat != null && lng != null) {
        final name = driver['name'] ?? 'Unknown';
        final id = driver['id'] ?? '';
        final isSelected = _selectedDriverId == id;

        driversWithLocation.add(driver);

        markers.add(
          Marker(
            point: LatLng(lat.toDouble(), lng.toDouble()),
            width: isSelected ? 56 : 44,
            height: isSelected ? 56 : 44,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDriverId = _selectedDriverId == id ? null : id;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1976D2)
                      : const Color(0xFF42A5F5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.black)
                          .withOpacity(0.3),
                      blurRadius: isSelected ? 12 : 6,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSelected ? 20 : 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // Find selected driver info
    Map<String, dynamic>? selectedDriver;
    if (_selectedDriverId != null) {
      for (final d in driversWithLocation) {
        if (d['id'] == _selectedDriverId) {
          selectedDriver = d;
          break;
        }
      }
    }

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            minZoom: 4,
            maxZoom: 18,
            onTap: (_, __) {
              setState(() => _selectedDriverId = null);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ns_transport.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Driver count badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people,
                  size: 20,
                  color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
                ),
                const SizedBox(width: 8),
                Text(
                  '${driversWithLocation.length} / ${drivers.length} drivers on map',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF334E68),
                  ),
                ),
              ],
            ),
          ),
        ),

        // No-location notice
        if (driversWithLocation.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Driver Locations Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Driver location data will appear here once\ndrivers share their location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Selected driver info card
        if (selectedDriver != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildDriverInfoCard(selectedDriver, isDark),
          ),

        // Driver list at bottom (when none selected)
        if (selectedDriver == null && driversWithLocation.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
                    child: Text(
                      'Active Drivers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: driversWithLocation.length,
                      itemBuilder: (context, index) {
                        final d = driversWithLocation[index];
                        final name = d['name'] ?? 'Unknown';
                        return GestureDetector(
                          onTap: () {
                            final lat = d['latitude'] as num;
                            final lng = d['longitude'] as num;
                            _mapController.move(
                              LatLng(lat.toDouble(), lng.toDouble()),
                              14.0,
                            );
                            setState(() => _selectedDriverId = d['id']);
                          },
                          child: Container(
                            width: 72,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF42A5F5),
                                  radius: 22,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name.split(' ').first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDriverInfoCard(Map<String, dynamic> driver, bool isDark) {
    final name = driver['name'] ?? 'Unknown';
    final email = driver['email'] ?? 'No email';
    final phone = driver['phone'] ?? 'No phone';
    final lat = driver['latitude'] as num?;
    final lng = driver['longitude'] as num?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1976D2),
            radius: 28,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (lat != null && lng != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            onPressed: () => setState(() => _selectedDriverId = null),
          ),
        ],
      ),
    );
  }
}
