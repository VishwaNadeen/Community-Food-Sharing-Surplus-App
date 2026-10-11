import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'recipient/recipient_home_screen.dart';
import 'donor/donor_home_screen.dart';
import 'ngo/ngo_home_screen.dart';
import 'volunteer/volunteer_home_screen.dart';
import 'volunteer/volunteer_profile_setup_screen.dart';
import 'recipient_profile_screen.dart';

/// Decides which screen to show based on auth state and role.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Provider.of<AuthProvider>(context, listen: false).loadFromStorage();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) return const LoginScreen();

        final role = auth.roleCode;

        if (role == 'R') {
          if (!auth.profileCompleted) {
            return RecipientProfileScreen(token: auth.token!);
          }
          return const RecipientHomeScreen();
        }

        if (role == 'D') return const DonorHomeScreen();
        if (role == 'D') return const DonorHomeScreen();

        if (role == 'N') return const NgoHomeScreen();

        if (role == 'V') {
          if (!auth.profileCompleted) {
            return const VolunteerProfileSetupScreen();
          }
          return const VolunteerHomeScreen();
        }

        // Fallback
        return const LoginScreen();
      },
    );
  }
}
