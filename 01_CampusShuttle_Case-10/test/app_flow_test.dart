import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_shuttle/main.dart';

Future<ShuttleStore> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final store = ShuttleStore();
  await store.load();
  await tester.pumpWidget(ChangeNotifierProvider<ShuttleStore>.value(
    value: store,
    child: const CampusShuttleApp(),
  ));
  await tester.pumpAndSettle();
  return store;
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rider can inspect a route, reserve it, and cancel it',
      (tester) async {
    final store = await _pumpApp(tester);

    expect(find.text('Scheduled departures'), findsOneWidget);
    await _tapKey(tester, 'trip-card-north-0815');
    expect(find.text('Stops along this route'), findsOneWidget);

    await _tapKey(tester, 'reserve-button');
    expect(find.text('Confirm your seat'), findsOneWidget);
    await _tapKey(tester, 'confirm-reserve');
    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(store.trip('north-0815').available, 7);

    await _tapKey(tester, 'view-bookings');
    expect(find.text('1 reservation'), findsOneWidget);

    await _tapKey(tester, 'cancel-${store.bookings.single.id}');
    expect(find.text('Cancel this booking?'), findsOneWidget);
    await _tapKey(tester, 'confirm-cancel');
    expect(find.text('No bookings yet'), findsOneWidget);
    expect(store.trip('north-0815').available, 8);
  });

  testWidgets('seat count updates live on Trip Detail and My Bookings',
      (tester) async {
    final store = await _pumpApp(tester);

    await _tapKey(tester, 'trip-card-north-0815');
    expect(find.text('8 of 24 left'), findsOneWidget);
    expect(find.text('16 reserved · 8 left of 24'), findsOneWidget);

    store.simulateBooking('north-0815');
    await tester.pumpAndSettle();
    expect(find.text('7 of 24 left'), findsOneWidget);
    expect(find.text('17 reserved · 7 left of 24'), findsOneWidget);

    await _tapKey(tester, 'reserve-button');
    await _tapKey(tester, 'confirm-reserve');
    await _tapKey(tester, 'view-bookings');
    expect(find.text('6 of 24 left'), findsOneWidget);

    store.simulateCancellation('north-0815');
    await tester.pumpAndSettle();
    expect(find.text('7 of 24 left'), findsOneWidget);
  });
}
