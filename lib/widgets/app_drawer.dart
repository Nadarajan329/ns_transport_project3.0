import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/routes/app_routes.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    final isOwner = user?.isOwner ?? false;
    final isDriver = user?.isDriver ?? false;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF3C5A80), // Slate blue matching the image
            padding: const EdgeInsets.only(top: 60, left: 24, bottom: 24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.domain, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text(
                  'NS Transport',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isOwner) ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'dashboard',
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.ownerDashboard),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: 'Drivers Profile',
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.driverManagement),
                  ),


                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.settings),
                  ),

                ],
                if (isDriver) ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_road,
                    title: 'Create Trip',
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.tripForm),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: 'My Salary',
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.driverSalary),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.settings),
                  ),
                ],
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  color: Colors.red,
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color color = Colors.black87,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 26),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
    );
  }
}
