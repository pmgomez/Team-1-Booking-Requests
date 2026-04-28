import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/parish_provider.dart';
import 'providers/baptism_provider.dart';
import 'providers/wedding_provider.dart';
import 'providers/confirmation_provider.dart';
import 'providers/eucharist_provider.dart';
import 'providers/reconciliation_provider.dart';
import 'providers/anointing_sick_provider.dart';
import 'providers/funeral_mass_provider.dart';
import 'providers/mass_intention_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/parish_selection_screen.dart';
import 'screens/register_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/baptism_booking_screen.dart';
import 'screens/baptism_detail_screen.dart';
import 'screens/wedding_booking_screen.dart';
import 'screens/wedding_detail_screen.dart';
import 'screens/confirmation_booking_screen.dart';
import 'screens/confirmation_detail_screen.dart';
import 'screens/Eucharist_Screen.dart';
import 'screens/eucharist_detail_screen.dart';
import 'screens/Reconciliation_Screen.dart';
import 'screens/Anointing_The_Sick.dart';
import 'screens/anointing_sick_detail_screen.dart';
import 'screens/Mass_Intention_Screen.dart';
import 'screens/mass_intention_detail_screen.dart';
import 'screens/Funeral_Mass_Screen.dart';
import 'screens/funeral_mass_detail_screen.dart';
import 'screens/reconciliation_detail_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_bookings_screen.dart';
import 'screens/admin_parishes_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_records_screen.dart';
import 'config/app_constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case '/parish-selection':
        return MaterialPageRoute(builder: (_) => ParishSelectionScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case '/baptism-booking':
        return MaterialPageRoute(builder: (_) => BaptismBookingScreen());
      case '/baptism-detail': {
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        print('=== NAVIGATING TO BAPTISM DETAIL ===');
        print('Arguments: $args');
        print('ID: ${args['id']}');
        print('fromStatusButton: ${args['fromStatusButton']}');
        return MaterialPageRoute(
          builder: (_) => BaptismDetailScreen(
            baptismId: args['id'] as int?,
            fromStatusButton: args['fromStatusButton'] as bool? ?? false,
          ),
        );
      }
      case '/wedding-booking':
        return MaterialPageRoute(builder: (_) => WeddingBookingScreen());
      case '/confirmation-booking':
        return MaterialPageRoute(builder: (_) => ConfirmationBookingScreen());
      case '/eucharist':
        return MaterialPageRoute(builder: (_) => EucharistScreen());
      case '/reconciliation':
        return MaterialPageRoute(builder: (_) => ReconciliationScreen());
      case '/anointing-the-sick':
        return MaterialPageRoute(builder: (_) => AnointingTheSickScreen());
      case '/mass-intention':
        return MaterialPageRoute(builder: (_) => MassIntentionScreen());
       case '/mass-intention-detail': {
         final args = settings.arguments as Map<String, dynamic>? ?? {};
         return MaterialPageRoute(
           builder: (_) => MassIntentionDetailScreen(
             massIntentionId: args['id'] as int?,
             fromStatusButton: args['fromStatusButton'] as bool? ?? false,
           ),
         );
       }
       case '/confirmation-detail': {
         final args = settings.arguments as Map<String, dynamic>? ?? {};
         return MaterialPageRoute(
           builder: (_) => ConfirmationDetailScreen(
             confirmationId: args['id'] as int?,
             fromStatusButton: args['fromStatusButton'] as bool? ?? false,
           ),
         );
       }
       case '/anointing-sick-detail': {
         final args = settings.arguments as Map<String, dynamic>? ?? {};
         return MaterialPageRoute(
           builder: (_) => AnointingSickDetailScreen(
             anointingSickId: args['id'] as int?,
             fromStatusButton: args['fromStatusButton'] as bool? ?? false,
           ),
         );
       }
       case '/reconciliation-detail': {
         final args = settings.arguments as Map<String, dynamic>? ?? {};
         return MaterialPageRoute(
           builder: (_) => ReconciliationDetailScreen(
             reconciliationId: args['id'] as int?,
             fromStatusButton: args['fromStatusButton'] as bool? ?? false,
           ),
         );
       }
        case '/funeral-mass-detail': {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => FuneralMassDetailScreen(
              funeralMassId: args['id'] as int?,
              fromStatusButton: args['fromStatusButton'] as bool? ?? false,
            ),
          );
        }
        case '/wedding-detail': {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => WeddingDetailScreen(
              weddingId: args['id'] as int?,
              fromStatusButton: args['fromStatusButton'] as bool? ?? false,
            ),
          );
        }
        case '/eucharist-detail': {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => EucharistDetailScreen(
              eucharistId: args['id'] as int?,
              fromStatusButton: args['fromStatusButton'] as bool? ?? false,
            ),
          );
        }
        case '/funeral-mass':
         return MaterialPageRoute(builder: (_) => FuneralMassScreen());
      case '/admin-dashboard':
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
      case '/admin-bookings':
        return MaterialPageRoute(builder: (_) => AdminBookingsScreen());
      case '/admin-parishes':
        return MaterialPageRoute(builder: (_) => AdminParishesScreen());
      case '/admin-users':
        return MaterialPageRoute(builder: (_) => AdminUsersScreen());
      case '/admin-records':
        return MaterialPageRoute(builder: (_) => AdminRecordsScreen());
      case '/change-password':
        return MaterialPageRoute(builder: (_) => ChangePasswordScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case '/my-bookings':
        return MaterialPageRoute(builder: (_) => MyBookingsScreen());
      case '/my-profile':
        return MaterialPageRoute(builder: (_) => const MyProfileScreen());
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ParishProvider()),
        ChangeNotifierProvider(create: (_) => BaptismProvider()),
        ChangeNotifierProvider(create: (_) => WeddingProvider()),
        ChangeNotifierProvider(create: (_) => ConfirmationProvider()),
        ChangeNotifierProvider(create: (_) => EucharistProvider()),
        ChangeNotifierProvider(create: (_) => ReconciliationProvider()),
        ChangeNotifierProvider(create: (_) => AnointingSickProvider()),
        ChangeNotifierProvider(create: (_) => FuneralMassProvider()),
        ChangeNotifierProvider(create: (_) => MassIntentionProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: 'Roboto',
            ),
            initialRoute: '/',
            onGenerateRoute: onGenerateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
