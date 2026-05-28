import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/widgets/app_drawer.dart';

final driversProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('users')
      .select()
      .eq('role', 'driver');
  return List<Map<String, dynamic>>.from(response);
});

class DriverManagementScreen extends ConsumerStatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  ConsumerState<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends ConsumerState<DriverManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers', style: TextStyle(color: Colors.white, inherit: false)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: driversAsync.when(
        data: (drivers) {
          if (drivers.isEmpty) {
            return _buildEmptyState();
          }

          final filteredDrivers = drivers.where((d) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            final name = (d['name'] ?? '').toLowerCase();
            final email = (d['email'] ?? '').toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(driversProvider);
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = filteredDrivers[index];
                      final name = driver['name'] ?? 'Unknown Driver';
                      final email = driver['email'] ?? 'No email provided';
                      final phone = driver['phone'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/owner/employee-detail',
                              arguments: driver,
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF42A5F5),
                            radius: 24,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(phone, style: TextStyle(color: Colors.grey.shade600)),
                                ]
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit feature coming soon')),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Driver'),
                              ),
                              const PopupMenuItem(
                                value: 'disable',
                                child: Text('Disable Access'),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error loading drivers:\n$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(driversProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Use register screen to add drivers')),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No drivers found.',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a driver to get started.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // ignore: unused_result
              ref.refresh(driversProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
