import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/routes/app_routes.dart';

import 'package:ns_transport/routes/app_routes.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _navigateTo(BuildContext context, String routeName, bool isOwner, bool isDriver) {
    Navigator.pop(context); // close drawer
    
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final homeRoute = isOwner ? AppRoutes.ownerDashboard : AppRoutes.driverDashboard;
    
    if (routeName == homeRoute) {
      if (currentRoute != homeRoute) {
        Navigator.popUntil(context, (route) => route.settings.name == homeRoute || route.isFirst);
      }
      return;
    }
    
    if (currentRoute == homeRoute) {
      // Push on top of dashboard so user can slide/swipe back
      Navigator.pushNamed(context, routeName);
    } else if (currentRoute != routeName) {
      // Replace sibling screen to keep the stack flat at [Dashboard, Screen]
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    final isOwner = user?.isOwner ?? false;
    final isDriver = user?.isDriver ?? false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFF3C5A80),
            padding: const EdgeInsets.only(top: 60, left: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.domain, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.get('ns_transport', locale),
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
                    title: AppTranslations.get('owner_dashboard', locale),
                    onTap: () => _navigateTo(context, AppRoutes.ownerDashboard, isOwner, isDriver),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: AppTranslations.get('drivers_profile', locale),
                    onTap: () => _navigateTo(context, AppRoutes.driverManagement, isOwner, isDriver),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: AppTranslations.get('profile', locale),
                    onTap: () => _navigateTo(context, AppRoutes.settings, isOwner, isDriver),
                  ),
                ],
                if (isDriver) ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: AppTranslations.get('driver_dashboard', locale),
                    onTap: () => _navigateTo(context, AppRoutes.driverDashboard, isOwner, isDriver),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_road,
                    title: AppTranslations.get('create_trip', locale),
                    onTap: () => _navigateTo(context, AppRoutes.tripForm, isOwner, isDriver),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: AppTranslations.get('my_salary', locale),
                    onTap: () => _navigateTo(context, AppRoutes.driverSalary, isOwner, isDriver),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: AppTranslations.get('profile', locale),
                    onTap: () => _navigateTo(context, AppRoutes.settings, isOwner, isDriver),
                  ),
                ],
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: AppTranslations.get('logout', locale),
                  color: Colors.red,
                  onTap: () async {
                    final nav = Navigator.of(context);
                    nav.pop(); // Close drawer
                    await ref.read(authProvider.notifier).signOut();
                    nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
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
    Color? color,
    required VoidCallback onTap,
  }) {
    final itemColor = color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);

    return ListTile(
      leading: Icon(icon, color: itemColor, size: 26),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
    );
  }
}
