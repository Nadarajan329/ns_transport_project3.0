import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/routes/app_routes.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

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
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.ownerDashboard);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: AppTranslations.get('drivers_profile', locale),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.driverManagement);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: AppTranslations.get('profile', locale),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.settings);
                    },
                  ),
                ],
                if (isDriver) ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: AppTranslations.get('driver_dashboard', locale),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_road,
                    title: AppTranslations.get('create_trip', locale),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.tripForm);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: AppTranslations.get('my_salary', locale),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.driverSalary);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: AppTranslations.get('profile', locale),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.settings);
                    },
                  ),
                ],
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: AppTranslations.get('logout', locale),
                  color: Colors.red,
                  onTap: () async {
                    Navigator.pop(context); // Close drawer
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
