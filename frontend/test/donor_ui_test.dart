import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodlink/screens/donor/donor_ui.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('maps connection problems to a network message', () {
      expect(
        friendlyErrorMessage(const SocketException('Connection refused')),
        kNetworkErrorMessage,
      );
      expect(
        friendlyErrorMessage(
          Exception('ClientException: Connection closed, uri=http://x'),
        ),
        kNetworkErrorMessage,
      );
    });

    test('maps technical server responses to a plain message', () {
      expect(
        friendlyErrorMessage(
          Exception('The server returned a non-JSON response (HTTP 502).'),
        ),
        kServerErrorMessage,
      );
    });

    test('maps auth failures to a session message', () {
      expect(
        friendlyErrorMessage(Exception('Unauthorized')),
        kSessionErrorMessage,
      );
    });

    test('keeps readable server validation messages', () {
      expect(
        friendlyErrorMessage(Exception('Expiry date must be in the future')),
        'Expiry date must be in the future',
      );
    });
  });

  test('formatQuantity drops trailing .0 and uses short units', () {
    expect(formatQuantity(10, 'KG'), '10 kg');
    expect(formatQuantity(2.5, 'LITRE'), '2.5 L');
    expect(formatQuantity(3, 'PACKETS'), '3 packets');
  });

  test('formatFriendlyDateTime is readable', () {
    final date = DateTime(2026, 10, 14, 16, 30);
    expect(formatFriendlyDateTime(date), 'Wed, 14 Oct 2026 at 4:30 PM');
  });

  test('every donation status has a label and icon', () {
    for (final status in [
      'PENDING',
      'APPROVED',
      'AVAILABLE',
      'REJECTED',
      'CANCELLED',
      'COLLECTED',
      'EXPIRED',
    ]) {
      final style = DonationStatusStyle.of(status);
      expect(style.label, isNot(status));
      expect(style.description, isNotEmpty);
    }
  });

  testWidgets('error view shows a retry button that works', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DonorMessageView.error(
            title: 'Could not load your donations',
            message: kNetworkErrorMessage,
            onAction: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Could not load your donations'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);

    // Tap target is at least 48px tall.
    final button = tester.getSize(find.byType(FilledButton));
    expect(button.height, greaterThanOrEqualTo(kDonorTapHeight));
  });

  group('selection fields', () {
    Widget host(Widget child) => MaterialApp(
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        );

    const provinces = [
      DonorOption(value: 'Western', label: 'Western'),
      DonorOption(value: 'Central', label: 'Central'),
      DonorOption(value: 'Southern', label: 'Southern'),
      DonorOption(value: 'Northern', label: 'Northern'),
      DonorOption(value: 'Eastern', label: 'Eastern'),
      DonorOption(value: 'Uva', label: 'Uva'),
      DonorOption(value: 'Sabaragamuwa', label: 'Sabaragamuwa'),
    ];

    testWidgets('picker opens a sheet, searches and returns the choice',
        (tester) async {
      String? picked;

      await tester.pumpWidget(host(
        StatefulBuilder(
          builder: (context, setState) => DonorPickerField(
            label: 'Province',
            icon: Icons.map_outlined,
            value: picked,
            options: provinces,
            requiredMessage: 'Choose your province.',
            onChanged: (value) => setState(() => picked = value),
          ),
        ),
      ));

      await tester.tap(find.text('Province'));
      await tester.pumpAndSettle();

      // More than 6 options, so a search box is shown.
      expect(find.text('Choose province'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'sab');
      await tester.pumpAndSettle();
      expect(find.text('Western'), findsNothing);

      await tester.tap(find.text('Sabaragamuwa'));
      await tester.pumpAndSettle();

      expect(picked, 'Sabaragamuwa');
      expect(find.text('Sabaragamuwa'), findsOneWidget);
    });

    testWidgets('picker is locked and explains why when it has no options',
        (tester) async {
      await tester.pumpWidget(host(
        DonorPickerField(
          label: 'District',
          icon: Icons.location_city_outlined,
          value: null,
          options: const [],
          disabledHint: 'Choose a province first',
          requiredMessage: 'Choose your district.',
          onChanged: (_) => fail('Locked field must not change'),
        ),
      ));

      expect(find.text('Choose a province first'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await tester.tap(find.text('District'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('picker shows the required message when validated empty',
        (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(host(
        Form(
          key: formKey,
          child: DonorPickerField(
            label: 'City',
            icon: Icons.place_outlined,
            value: null,
            options: provinces,
            requiredMessage: 'Choose your city.',
            onChanged: (_) {},
          ),
        ),
      ));

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Choose your city.'), findsOneWidget);
    });

    testWidgets('choice cards select with one tap', (tester) async {
      String? type;

      await tester.pumpWidget(host(
        StatefulBuilder(
          builder: (context, setState) => DonorChoiceCards(
            label: 'I am donating as',
            value: type,
            options: const [
              DonorOption(value: 'INDIVIDUAL', label: 'Individual'),
              DonorOption(value: 'ORGANIZATION', label: 'Organization'),
            ],
            requiredMessage: 'Choose one.',
            onChanged: (value) => setState(() => type = value),
          ),
        ),
      ));

      await tester.tap(find.text('Organization'));
      await tester.pump();

      expect(type, 'ORGANIZATION');
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('chip selector changes the unit', (tester) async {
      var unit = 'KG';

      await tester.pumpWidget(host(
        StatefulBuilder(
          builder: (context, setState) => DonorChipSelector(
            label: 'Unit',
            value: unit,
            options: const [
              DonorOption(value: 'KG', label: 'kg'),
              DonorOption(value: 'PACKETS', label: 'Packets'),
            ],
            onChanged: (value) => setState(() => unit = value),
          ),
        ),
      ));

      await tester.tap(find.text('Packets'));
      await tester.pump();
      expect(unit, 'PACKETS');
    });
  });
}
