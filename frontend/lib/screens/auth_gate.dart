
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';

import 'login_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'recipient/recipient_home_screen.dart';
import 'donor/donor_home_screen.dart';
import 'ngo/ngo_home_screen.dart';
import 'volunteer/volunteer_home_screen.dart';

import 'recipient/recipient_profile_screen.dart';
import 'volunteer/volunteer_profile_setup_screen.dart';

/// Decides which screen to show based on authentication state and role.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loaded = false;

  // Welcome slides are shown only on first launch, before login.
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    await auth.loadFromStorage();

    final hasSeenOnboarding = await OnboardingService.hasSeen();

    // Someone already signed in on this device does not need the slides.
    if (auth.isLoggedIn && !hasSeenOnboarding) {
      await OnboardingService.markSeen();
    }

    if (mounted) {
      setState(() {
        _showOnboarding = !auth.isLoggedIn && !hasSeenOnboarding;
        _loaded = true;
      });
    }
  }

  Future<void> _finishOnboarding(OnboardingResult result) async {
    await OnboardingService.markSeen();

    if (!mounted) return;

    // Login screen takes over from here.
    setState(() => _showOnboarding = false);

    if (result == OnboardingResult.signUp) {
      // Open sign-up on top of Login, so Back returns to Login.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushNamed('/signup');
      });
    }
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
        if (!auth.isLoggedIn) {
          if (_showOnboarding) {
            return OnboardingScreen(onFinished: _finishOnboarding);
          }

          return const LoginScreen();
        }

        final role = auth.roleCode;

        // Recipient
        if (role == 'R') {
          if (!auth.profileCompleted) {
            return RecipientProfileScreen(
              token: auth.token!,
            );
          }

          return const RecipientHomeScreen();
        }

        // Donor
        if (role == 'D') {
          return const DonorHomeScreen();
        }

        // NGO coordinator
        if (role == 'N') {
          return const NgoHomeScreen();
        }

        // Volunteer
        if (role == 'V') {
          if (!auth.profileCompleted) {
            return const VolunteerProfileSetupScreen();
          }

          return const VolunteerHomeScreen();
        }

        // Unknown role
        return const LoginScreen();
      },
    );
  }
}
