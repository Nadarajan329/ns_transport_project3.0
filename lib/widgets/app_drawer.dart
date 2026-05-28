import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/routes/app_routes.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    final name = user?.name ?? 'User';
    final email = user?.email ?? '';
    final role = user?.role ?? '';
    final isOwner = user?.isOwner ?? false;
    final isDriver = user?.isDriver ?? false;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarUrl = user?.avatarUrl;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            accountName: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(email),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isOwner) ...[
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.ownerDashboard),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Driver Management'),
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.driverManagement),
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Salary Management'),
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.ownerSalary),
                  ),
                ],
                if (isDriver) ...[
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_road),
                    title: const Text('Create Trip'),
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.tripForm),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('My Salary'),
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.driverSalary),
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.settings),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
