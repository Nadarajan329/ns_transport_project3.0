import 'package:flutter/material.dart';
import 'package:ns_transport/screens/auth/splash_screen.dart';
import 'package:ns_transport/screens/auth/login_screen.dart';
import 'package:ns_transport/screens/auth/register_screen.dart';
import 'package:ns_transport/screens/owner/owner_dashboard.dart';
import 'package:ns_transport/screens/owner/driver_management_screen.dart';
import 'package:ns_transport/screens/owner/owner_salary_screen.dart';
import 'package:ns_transport/screens/owner/owner_trip_review_screen.dart';
import 'package:ns_transport/screens/driver/driver_dashboard.dart';
import 'package:ns_transport/screens/driver/trip_form_screen.dart';
import 'package:ns_transport/screens/driver/driver_salary_screen.dart';
import 'package:ns_transport/screens/shared/trip_detail_screen.dart';
import 'package:ns_transport/screens/shared/settings_screen.dart';

/// Custom page route that slides from right with a fade effect.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final slideTween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            final fadeTween = Tween<double>(begin: 0.5, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Application route names and route generation.
abstract final class AppRoutes {
  // ── Route Names ──────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String ownerDashboard = '/owner/dashboard';
  static const String driverDashboard = '/driver/dashboard';
  static const String tripForm = '/driver/trip-form';
  static const String tripDetail = '/trip/detail';
  static const String driverManagement = '/owner/drivers';
  static const String ownerSalary = '/owner/salary';
  static const String driverSalary = '/driver/salary';
  static const String ownerTripReview = '/owner/trip-review';
  static const String settings = '/settings';

  // ── Route Generator ──────────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return SlidePageRoute(
          page: const SplashScreen(),
        );

      case login:
        return SlidePageRoute(
          page: const LoginScreen(),
        );

      case register:
        return SlidePageRoute(
          page: const RegisterScreen(),
        );

      case ownerDashboard:
        return SlidePageRoute(
          page: const OwnerDashboard(),
        );

      case driverDashboard:
        return SlidePageRoute(
          page: const DriverDashboard(),
        );

      case tripForm:
        return SlidePageRoute(
          page: const TripFormScreen(),
        );

      case tripDetail:
        final tripId = settings.arguments as String;
        return SlidePageRoute(
          page: TripDetailScreen(tripId: tripId),
        );

      case driverManagement:
        return SlidePageRoute(
          page: const DriverManagementScreen(),
        );

      case ownerSalary:
        return SlidePageRoute(
          page: const OwnerSalaryScreen(),
        );

      case driverSalary:
        return SlidePageRoute(
          page: const DriverSalaryScreen(),
        );

      case ownerTripReview:
        return SlidePageRoute(
          page: const OwnerTripReviewScreen(),
        );

      case AppRoutes.settings:
        return SlidePageRoute(
          page: const SettingsScreen(),
        );

      default:
        return SlidePageRoute(page: const _NotFoundScreen());
    }
  }
}


// ── 404 Not Found Screen ───────────────────────────────────────────────
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Page not found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
