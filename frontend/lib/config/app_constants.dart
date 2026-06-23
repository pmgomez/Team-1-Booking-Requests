class AppConstants {
  static const String appName = 'Diocese of Kalookan';
  static const String version = '1.0.0';
  static const String packageName = 'com.diocese.kalookan';
  
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://rcdok-booking-backend.up.railway.app');
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  
  // Validation Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^[0-9]{10,15}$'; // Adjust as needed for Philippine numbers
  
  // App Strings
  static const String welcomeMessage = 'Welcome to Diocese of Kalookan';
  static const String loginTitle = 'Sign in to your account';
  static const String registerTitle = 'Create an account';
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String unauthorizedErrorMessage = 'Unauthorized. Please log in again.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  
  // Sacrament Types
  static const List<String> sacramentTypes = [
    'Baptism',
    'Wedding',
    'Confirmation',
  ];
  
  // Mass Intention Types
  static const List<String> intentionTypes = [
    'Deceased',
    'Thanksgiving',
    'Petition',
  ];
  
  // Roles
  static const String roleParishioner = 'parishioner';
  static const String roleStaff = 'staff';
  static const String rolePriest = 'priest';
  static const String roleAdmin = 'admin';
}