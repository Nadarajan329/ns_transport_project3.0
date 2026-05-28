import 'package:ns_transport/routes/app_routes.dart';

/// Role-based route protection.
class RouteGuard {
  RouteGuard._();

  // ── Public Routes (no authentication required) ───────────────────────
  static const List<String> publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
  ];

  // ── Owner-only Routes ────────────────────────────────────────────────
  static const List<String> ownerRoutes = [
    AppRoutes.ownerDashboard,
    AppRoutes.driverManagement,
    AppRoutes.ownerSalary,
    AppRoutes.ownerTripReview,
  ];

  // ── Driver-only Routes ───────────────────────────────────────────────
  static const List<String> driverRoutes = [
    AppRoutes.driverDashboard,
    AppRoutes.tripForm,
    AppRoutes.driverSalary,
  ];

  // ── Shared Routes (accessible by any authenticated user) ─────────────
  static const List<String> _sharedRoutes = [
    AppRoutes.tripDetail,
    AppRoutes.settings,
  ];

  /// Returns `true` if [userRole] is allowed to access the given [route].
  ///
  /// - Public routes are always accessible.
  /// - `null` role can only access public routes.
  /// - 'owner' and 'driver' can access their own routes plus shared routes.
  static bool canAccess(String route, String? userRole) {
    // Public routes are always accessible.
    if (publicRoutes.contains(route)) return true;

    // Unauthenticated users can only see public routes.
    if (userRole == null) return false;

    // Shared routes are accessible to any authenticated user.
    if (_sharedRoutes.contains(route)) return true;

    // Role-specific checks.
    switch (userRole) {
      case 'owner':
        return ownerRoutes.contains(route);
      case 'driver':
        return driverRoutes.contains(route);
      default:
        return false;
    }
  }

  /// Returns the default dashboard route for the given [role].
  static String getHomeRoute(String role) {
    switch (role) {
      case 'owner':
        return AppRoutes.ownerDashboard;
      case 'driver':
        return AppRoutes.driverDashboard;
      default:
        return AppRoutes.login;
    }
  }
}
