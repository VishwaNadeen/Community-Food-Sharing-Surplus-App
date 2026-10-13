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
}
