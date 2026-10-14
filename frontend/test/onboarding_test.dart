import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodlink/main.dart';
import 'package:foodlink/providers/auth_provider.dart';
import 'package:foodlink/screens/login_screen.dart';
import 'package:foodlink/screens/onboarding/onboarding_content.dart';
import 'package:foodlink/screens/onboarding/onboarding_screen.dart';
import 'package:foodlink/screens/signup_screen.dart';
import 'package:foodlink/services/onboarding_service.dart';

/// Taps through to the last slide with the Next button.
Future<void> _goToLastSlide(WidgetTester tester) async {
  for (var i = 1; i < kOnboardingSlides.length; i++) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
}

Widget _onboarding({ValueChanged<OnboardingResult>? onFinished}) {
  return MaterialApp(home: OnboardingScreen(onFinished: onFinished ?? (_) {}));
}

/// The real app, as started by main().
Widget _app() {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: const MyApp(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('slide content', () {
    test('introduces the four FoodLink roles in order', () {
      expect(kOnboardingSlides.map((slide) => slide.roleName).toList(), [
        'Food Donor',
        'Recipient',
        'Volunteer',
        'NGO',
      ]);
    });

    test('each slide has a headline, description and 3-4 features', () {
      for (final slide in kOnboardingSlides) {
        expect(slide.headline, isNotEmpty);
        expect(slide.description, isNotEmpty);
        expect(slide.features.length, inInclusiveRange(3, 4));
      }
    });
  });

  group('onboarding screen', () {
    testWidgets('shows each role with its headline and features', (
      tester,
    ) async {
      await tester.pumpWidget(_onboarding());

      for (var i = 0; i < kOnboardingSlides.length; i++) {
        final slide = kOnboardingSlides[i];

        expect(find.text(slide.headline), findsOneWidget);
        expect(find.text('For ${slide.roleName}s'), findsOneWidget);
        for (final feature in slide.features) {
          expect(find.text(feature.text), findsOneWidget);
        }

        if (i < kOnboardingSlides.length - 1) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('slides can be swiped', (tester) async {
      await tester.pumpWidget(_onboarding());

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(kOnboardingSlides[1].headline), findsOneWidget);
    });

    testWidgets('only a centred Next button, swipe right goes back', (
      tester,
    ) async {
      await tester.pumpWidget(_onboarding());

      // No Back button; Next is centred.
      expect(find.text('Back'), findsNothing);
      final next = tester.getCenter(find.widgetWithText(FilledButton, 'Next'));
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(next.dx, moreOrLessEquals(screenWidth / 2, epsilon: 1));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(kOnboardingSlides[0].headline), findsOneWidget);
    });

    testWidgets('system back goes to the previous slide', (tester) async {
      await tester.pumpWidget(_onboarding());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final popped = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.text(kOnboardingSlides[0].headline), findsOneWidget);
    });

    testWidgets('Skip finishes with logIn', (tester) async {
      OnboardingResult? result;
      await tester.pumpWidget(_onboarding(onFinished: (r) => result = r));

      await tester.tap(find.text('Skip'));
      expect(result, OnboardingResult.logIn);
    });

    testWidgets('last slide offers Get Started and log in', (tester) async {
      OnboardingResult? result;
      await tester.pumpWidget(_onboarding(onFinished: (r) => result = r));

      await _goToLastSlide(tester);

      expect(find.text('Next'), findsNothing);

      // Skip keeps its space (so the header does not jump) but is hidden
      // and cannot be tapped.
      final skip = tester.widget<Visibility>(
        find.ancestor(of: find.text('Skip'), matching: find.byType(Visibility)),
      );
      expect(skip.visible, isFalse);

      await tester.tap(find.text('Get Started'));
      expect(result, OnboardingResult.signUp);

      await tester.tap(find.text('I already have an account'));
      expect(result, OnboardingResult.logIn);
    });

    testWidgets('fits a small phone screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_onboarding());

      for (var i = 1; i < kOnboardingSlides.length; i++) {
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('startup flow', () {
    testWidgets('first launch shows onboarding, Skip opens Login', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(await OnboardingService.hasSeen(), isTrue);
    });

    testWidgets('Get Started opens sign-up, and Back returns to Login', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await _goToLastSlide(tester);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('returning logged-out user goes straight to Login', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  test('logging out keeps the onboarding flag', () async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'auth_token': 'token',
    });

    await AuthProvider().logout();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
    expect(await OnboardingService.hasSeen(), isTrue);
  });
}
