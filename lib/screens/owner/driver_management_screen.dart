import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/widgets/app_drawer.dart';
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/core/theme/app_theme.dart';

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
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.get('manage_drivers', locale), style: AppTheme.getFont(locale, color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: driversAsync.when(
        data: (drivers) {
          if (drivers.isEmpty) {
            return _buildEmptyState(locale);
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
                    style: AppTheme.getFont(locale),
                    decoration: InputDecoration(
                      hintText: AppTranslations.get('search_name_email', locale),
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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = filteredDrivers[index];
                      final name = driver['name'] ?? AppTranslations.get('unknown_driver', locale);
                      final email = driver['email'] ?? AppTranslations.get('no_email_provided', locale);
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
                            backgroundImage: driver['avatar_url'] != null && driver['avatar_url'].isNotEmpty
                                ? NetworkImage(driver['avatar_url'])
                                : null,
                            child: driver['avatar_url'] == null || driver['avatar_url'].isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(name, style: AppTheme.getFont(locale, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email, style: AppTheme.getFont(locale)),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(phone, style: AppTheme.getFont(locale, color: Colors.grey.shade600)),
                                ]
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppTranslations.get('edit_coming_soon', locale), style: AppTheme.getFont(locale))),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(AppTranslations.get('edit_driver', locale), style: AppTheme.getFont(locale)),
                              ),
                              PopupMenuItem(
                                value: 'disable',
                                child: Text(AppTranslations.get('disable_access', locale), style: AppTheme.getFont(locale)),
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
              Text('${AppTranslations.get('error', locale)}:\n$error', textAlign: TextAlign.center, style: AppTheme.getFont(locale)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(driversProvider),
                child: Text(AppTranslations.get('retry', locale), style: AppTheme.getFont(locale)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTranslations.get('use_register_screen', locale), style: AppTheme.getFont(locale))),
          );
        },
        icon: const Icon(Icons.person_add),
        label: Text(AppTranslations.get('add_driver_button', locale), style: AppTheme.getFont(locale)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(String locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            AppTranslations.get('no_drivers_found', locale),
            style: AppTheme.getFont(locale, fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.get('add_driver_started', locale),
            style: AppTheme.getFont(locale, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // ignore: unused_result
              ref.refresh(driversProvider);
            },
            icon: const Icon(Icons.refresh),
            label: Text(AppTranslations.get('refresh', locale), style: AppTheme.getFont(locale)),
          ),
        ],
      ),
    );
  }
}
