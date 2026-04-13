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
import 'screens/baptism_booking_screen.dart';
import 'screens/wedding_booking_screen.dart';
import 'screens/confirmation_booking_screen.dart';
import 'screens/Eucharist_Screen.dart';
import 'screens/Reconciliation_Screen.dart';
import 'screens/Anointing_The_Sick.dart';
import 'screens/Mass_Intention_Screen.dart';
import 'screens/Funeral_Mass_Screen.dart';
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
            routes: {
              '/': (context) => SplashScreen(),
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(),
              '/parish-selection': (context) => ParishSelectionScreen(),
              '/register': (context) => RegisterScreen(),
              '/baptism-booking': (context) => BaptismBookingScreen(),
              '/wedding-booking': (context) => WeddingBookingScreen(),
              '/confirmation-booking': (context) => ConfirmationBookingScreen(),
              '/eucharist': (context) => EucharistScreen(),
              '/reconciliation': (context) => ReconciliationScreen(),
              '/anointing-the-sick': (context) => AnointingTheSickScreen(),
              '/mass-intention': (context) => MassIntentionScreen(),
              '/funeral-mass': (context) => FuneralMassScreen(),
              // Admin routes
              '/admin-dashboard': (context) => AdminDashboardScreen(),
              '/admin-bookings': (context) => AdminBookingsScreen(),
              '/admin-parishes': (context) => AdminParishesScreen(),
              '/admin-users': (context) => AdminUsersScreen(),
              '/admin-records': (context) => AdminRecordsScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}