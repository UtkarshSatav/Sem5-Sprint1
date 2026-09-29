import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_shuttle/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reserve decrements availability and cancel restores it', () async {
    final store = ShuttleStore();
    await store.load();
    final before = store.trip('north-0815').available;

    expect(store.reserve('north-0815'), isTrue);
    expect(store.trip('north-0815').available, before - 1);
    expect(store.bookings, hasLength(1));

    store.cancel(store.bookings.single.id);
    expect(store.trip('north-0815').available, before);
    expect(store.bookings, isEmpty);
  });

  test('cannot reserve a trip twice in the single-user prototype', () async {
    final store = ShuttleStore();
    await store.load();

    expect(store.reserve('res-0845'), isTrue);
    expect(store.reserve('res-0845'), isFalse);
    expect(store.bookings, hasLength(1));
  });

  test('reservations are restored from local storage', () async {
    final store = ShuttleStore();
    await store.load();
    store.reserve('west-0915');

    final reopened = ShuttleStore();
    await reopened.load();
    expect(reopened.bookings, hasLength(1));
    expect(reopened.trip('west-0915').available, 11);
  });

  test('ignores duplicate and unknown saved bookings', () async {
    SharedPreferences.setMockInitialValues({
      'campus_shuttle_bookings_v1': jsonEncode([
        {
          'id': 'first',
          'tripId': 'north-0815',
          'bookedAt': '2026-09-28T10:00:00.000'
        },
        {
          'id': 'duplicate',
          'tripId': 'north-0815',
          'bookedAt': '2026-09-28T10:01:00.000'
        },
        {
          'id': 'stale',
          'tripId': 'removed-trip',
          'bookedAt': '2026-09-28T10:02:00.000'
        },
      ]),
    });

    final store = ShuttleStore();
    await store.load();

    expect(store.bookings, hasLength(1));
    expect(store.trip('north-0815').available, 7);
  });

  test('reserve is unavailable until saved state has loaded', () {
    final store = ShuttleStore();
    expect(store.reserve('north-0815'), isFalse);
  });
}
