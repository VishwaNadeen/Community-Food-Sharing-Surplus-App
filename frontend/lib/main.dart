import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/recipient/recipient_home_screen.dart';
import 'screens/donor/donor_home_screen.dart';
import 'screens/ngo/ngo_dashboard_screen.dart';
import 'screens/volunteer/volunteer_home_screen.dart';
import 'screens/volunteer/volunteer_profile_screen.dart';
import 'screens/volunteer/volunteer_profile_setup_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      //home: const AuthGate(),
      home: const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/verify-email':
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: email),
            );
          case '/forgot-password':
            return MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen());
          case '/reset-password':
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: email),
            );
          case '/change-password':
            return MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen());
          case '/recipient-home':
            return MaterialPageRoute(
                builder: (_) => const RecipientHomeScreen());
          case '/donor-home':
            return MaterialPageRoute(builder: (_) => const DonorHomeScreen());
          case '/ngo-dashboard':
            return MaterialPageRoute(
                builder: (_) => const NgoDashboardScreen());
          case '/volunteer-home':
            return MaterialPageRoute(
                builder: (_) => const VolunteerHomeScreen());
          case '/volunteer-profile':
            return MaterialPageRoute(
                builder: (_) => const VolunteerProfileScreen());
          case '/volunteer-profile-setup':
            return MaterialPageRoute(
                builder: (_) => const VolunteerProfileSetupScreen());
          default:
            return MaterialPageRoute(builder: (_) => const AuthGate());
        }
      },
    );
  }
}
