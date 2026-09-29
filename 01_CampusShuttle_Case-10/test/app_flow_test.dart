import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_shuttle/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rider can inspect a route, reserve it, and cancel it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ShuttleStore();
    await store.load();

    await tester.pumpWidget(ChangeNotifierProvider<ShuttleStore>.value(
      value: store,
      child: const CampusShuttleApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Scheduled departures'), findsOneWidget);
    final routeCard = find.byKey(const ValueKey('trip-card-north-0815'));
    await tester.ensureVisible(routeCard);
    await tester.tap(routeCard);
    await tester.pumpAndSettle();
    expect(find.text('Stops along this route'), findsOneWidget);

    final reserveButton = find.text('Reserve a seat');
    await tester.ensureVisible(reserveButton);
    await tester.tap(reserveButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirm your seat'), findsOneWidget);
    await tester.tap(find.text('Reserve seat'));
    await tester.pumpAndSettle();
    expect(find.text('Seat reserved'), findsOneWidget);

    final bookingsTab = find.text('My Bookings').first;
    await tester.tap(bookingsTab);
    await tester.pumpAndSettle();
    expect(find.text('My Bookings'), findsNWidgets(2));
    expect(find.text('1 reservation'), findsOneWidget);

    final cancelButton = find.text('Cancel').first;
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    expect(find.text('No bookings yet'), findsOneWidget);
    expect(store.trip('north-0815').available, 8);
  });
}
