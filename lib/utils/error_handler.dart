class ErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    final str = error.toString().toLowerCase();
    
    if (str.contains('socketexception') || 
        str.contains('failed host lookup') || 
        str.contains('network') || 
        str.contains('clientexception')) {
      return 'Network error. Please check your internet connection.';
    }
    if (str.contains('invalid login credentials') || 
        str.contains('invalid login') || 
        str.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }
    if (str.contains('user not found')) {
      return 'No account found with this email.';
    }
    if (str.contains('user already registered') || 
        str.contains('already registered') ||
        str.contains('user_already_exists')) {
      return 'An account with this email already exists.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}
