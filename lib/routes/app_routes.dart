import 'package:flutter/material.dart';
import 'package:ns_transport/models/trip_model.dart';
import 'package:ns_transport/screens/auth/splash_screen.dart';
import 'package:ns_transport/screens/auth/login_screen.dart';
import 'package:ns_transport/screens/auth/register_screen.dart';
import 'package:ns_transport/screens/owner/owner_dashboard.dart';
import 'package:ns_transport/screens/owner/driver_management_screen.dart';
import 'package:ns_transport/screens/owner/owner_salary_screen.dart';
import 'package:ns_transport/screens/owner/owner_trip_review_screen.dart';
import 'package:ns_transport/screens/owner/driver_locations_screen.dart';
import 'package:ns_transport/screens/driver/driver_dashboard.dart';
import 'package:ns_transport/screens/driver/trip_form_screen.dart';
import 'package:ns_transport/screens/driver/driver_salary_screen.dart';
import 'package:ns_transport/screens/shared/trip_detail_screen.dart';
import 'package:ns_transport/screens/shared/settings_screen.dart';
import 'package:ns_transport/screens/owner/owner_submitted_screen.dart';
import 'package:ns_transport/screens/owner/employee_detail_screen.dart';
import 'package:ns_transport/screens/driver/driver_profile_edit_screen.dart';



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
  static const String ownerSubmitted = '/owner/submitted';
  static const String settings = '/settings';
  static const String employeeDetail = '/owner/employee-detail';
  static const String driverLocations = '/owner/driver-locations';
  static const String driverProfileEdit = '/driver/profile-edit';

  // ── Route Generator ──────────────────────────────────────────────────
  static Route<dynamic> _buildRoute(Widget child, {bool isFade = false}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (isFade) {
          return FadeTransition(opacity: animation, child: child);
        }
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), isFade: true);

      case login:
        return _buildRoute(const LoginScreen(), isFade: true);

      case register:
        return _buildRoute(const RegisterScreen());

      case ownerDashboard:
        return _buildRoute(const OwnerDashboard(), isFade: true);

      case driverDashboard:
        return _buildRoute(const DriverDashboard(), isFade: true);

      case tripForm:
        final trip = settings.arguments as TripModel?;
        return _buildRoute(TripFormScreen(existingTrip: trip));

      case tripDetail:
        final tripId = settings.arguments as String;
        return _buildRoute(TripDetailScreen(tripId: tripId));

      case driverManagement:
        return _buildRoute(const DriverManagementScreen());

      case ownerSalary:
        return _buildRoute(const OwnerSalaryScreen());

      case driverSalary:
        return _buildRoute(const DriverSalaryScreen());

      case ownerTripReview:
        return _buildRoute(const OwnerTripReviewScreen());

      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen());

      case ownerSubmitted:
        return _buildRoute(const OwnerSubmittedScreen());

      case employeeDetail:
        final driver = settings.arguments as Map<String, dynamic>;
        return _buildRoute(EmployeeDetailScreen(driver: driver));

      case driverLocations:
        return _buildRoute(const DriverLocationsScreen());

      case driverProfileEdit:
        return _buildRoute(const DriverProfileEditScreen());

      default:
        return _buildRoute(const _NotFoundScreen(), isFade: true);
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
