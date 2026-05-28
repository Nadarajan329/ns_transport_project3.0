/// App-wide string constants for NS Transport.
///
/// Centralises all user-facing text so that future localisation
/// or copy changes only need to touch this file.
abstract final class AppStrings {
  // ─── App Identity ─────────────────────────────────────────────────
  static const String appName = 'NS Transport';
  static const String appTagline = 'Smart Transport Management';
  static const String appVersion = '3.0.0';

  // ─── Auth – Labels ────────────────────────────────────────────────
  static const String login = 'Login';
  static const String register = 'Register';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phoneNumber = 'Phone Number';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String createAccount = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String orContinueWith = 'Or continue with';
  static const String continueWithGoogle = 'Continue with Google';
  static const String selectRole = 'Select Role';
  static const String welcomeBack = 'Welcome Back';
  static const String getStarted = 'Get Started';

  // ─── Roles ────────────────────────────────────────────────────────
  static const String roleOwner = 'Owner';
  static const String roleDriver = 'Driver';
  static const String roleOwnerDescription =
      'Manage fleet, drivers, and trips';
  static const String roleDriverDescription =
      'View assigned trips and submit reports';

  // ─── Trip Status Labels ───────────────────────────────────────────
  static const String statusDraft = 'Draft';
  static const String statusSubmitted = 'Submitted';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';
  static const String statusInProgress = 'In Progress';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
  static const String statusPending = 'Pending';

  // ─── Navigation Labels ────────────────────────────────────────────
  static const String home = 'Home';
  static const String dashboard = 'Dashboard';
  static const String trips = 'Trips';
  static const String drivers = 'Drivers';
  static const String salary = 'Salary';
  static const String salaries = 'Salaries';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String reports = 'Reports';

  // ─── Trip Labels ──────────────────────────────────────────────────
  static const String newTrip = 'New Trip';
  static const String editTrip = 'Edit Trip';
  static const String tripDetails = 'Trip Details';
  static const String startLocation = 'Start Location';
  static const String endLocation = 'End Location';
  static const String tripDate = 'Trip Date';
  static const String distance = 'Distance';
  static const String amount = 'Amount';
  static const String assignDriver = 'Assign Driver';
  static const String noTripsFound = 'No trips found';

  // ─── Error Messages ───────────────────────────────────────────────
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork =
      'Network error. Please check your connection.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorPasswordTooShort =
      'Password must be at least 6 characters.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorFieldRequired = 'This field is required.';
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorEmailAlreadyInUse =
      'This email is already registered.';
  static const String errorSessionExpired =
      'Session expired. Please login again.';
  static const String errorUnauthorized =
      'You are not authorized to perform this action.';
  static const String errorLoadingData = 'Failed to load data.';
  static const String errorSavingData = 'Failed to save data.';

  // ─── Success Messages ─────────────────────────────────────────────
  static const String successLogin = 'Logged in successfully!';
  static const String successRegister = 'Account created successfully!';
  static const String successLogout = 'Logged out successfully.';
  static const String successTripCreated = 'Trip created successfully!';
  static const String successTripUpdated = 'Trip updated successfully!';
  static const String successTripDeleted = 'Trip deleted successfully.';
  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successPasswordReset =
      'Password reset email sent. Check your inbox.';
  static const String successSalarySaved = 'Salary record saved successfully!';

  // ─── Button Labels ────────────────────────────────────────────────
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String submit = 'Submit';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String apply = 'Apply';
  static const String filter = 'Filter';
  static const String search = 'Search';
  static const String viewAll = 'View All';
  static const String loadMore = 'Load More';

  // ─── Miscellaneous ────────────────────────────────────────────────
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String noResults = 'No results found';
  static const String deleteConfirmation =
      'Are you sure you want to delete this?';
  static const String logoutConfirmation = 'Are you sure you want to logout?';
}
