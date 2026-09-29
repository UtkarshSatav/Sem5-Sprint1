# CampusShuttle — Case 10

CampusShuttle is a focused Flutter case-study prototype for viewing campus shuttle departures, inspecting a trip, reserving one seat, and managing active bookings. It follows the assigned deliverables: Flutter, Dart, Material 3, Provider-managed seat state, local persistence, route colour coding, and the three required views.

## Deliverables

| Required item | Implementation |
| --- | --- |
| Figma design | [Figma file](https://www.figma.com/design/jscHLuJNuLOS6WgEtpsQzH) and [clickable prototype](https://www.figma.com/proto/jscHLuJNuLOS6WgEtpsQzH?node-id=2-2&starting-point-node-id=2-2); frames and styles are described in `design/FIGMA.md`. `design/campusshuttle-flow.svg` is the earlier static export. |
| Route Timetable | A searchable `ListView` of colour-coded `Card` widgets with route, time, stop endpoints, icons, and seats remaining. |
| Trip Detail | Origin, destination, times, full stop sequence, remaining seats, confirmation prompt, and booking-success state. |
| My Bookings | A `ListView` of locally persisted active bookings with cancellation and restored seat availability. |
| Provider | `ShuttleStore` is the single state source for trips, bookings, and live seat counts. It also tracks `othersReserved` per trip, with the invariant available + othersReserved + (booked on this device ? 1 : 0) = capacity. |
| Live seat updates | `ShuttleStore.startLiveUpdates()` simulates other students: every 6 seconds one books or cancels a seat, and they never take the last seat. See `docs/APP_FLOW.md` ("Data model" and "Live updates"). |
| Local persistence | `shared_preferences` stores active bookings on the current device/browser. |
| Material 3 | Responsive Material 3 layout for narrow and wide screens, with `Card`, `Icon`, `NavigationBar`, buttons, chips, and dialogs. |
| Guided flow | A visible four-step cue follows Timetable → Trip details → Reserve seat → Confirmation. |

## Run

```sh
flutter pub get
flutter run -d chrome
```

The hosted web app is at https://campusshuttle-1be8c.web.app. It shows the last deployed build until it is redeployed with the commands below.

Build and deploy the static web app:

```sh
flutter build web --release
firebase deploy --only hosting --project campusshuttle-1be8c
```

## Demonstration flow

1. Open **Route timetable** and show the colour-coded routes and current seat counts.
2. Search by route or stop, then open a departure.
3. Review the full stop sequence and press **Reserve a seat**.
4. Confirm the booking. Provider decrements the seat count and every listening screen rebuilds. Watch other seat counts change on their own as the simulated live feed runs.
5. Open **My Bookings**, cancel the booking, and show that Provider restores the seat.
6. Refresh the browser before cancellation to demonstrate local persistence.

## 60-second viva explanation

“CampusShuttle helps students view shuttle timings, inspect all stops, reserve one seat, and manage the reservation. Static trip data is the input. A Provider `ChangeNotifier` owns the trips and bookings, so reserving decreases the selected trip’s available seats and cancellation restores it everywhere in the UI. A simulated live feed, started by `startLiveUpdates()`, has other students book and cancel every 6 seconds, so seat counts keep moving; the store tracks `othersReserved` so cancelling always returns the count to capacity minus other students’ seats. `shared_preferences` serializes active bookings so they survive a browser refresh. Material 3 cards and route colours make departures easy to scan. The output is a confirmed booking in My Bookings. I validate duplicate, unavailable, stale, and cancelled bookings. This is a case-study prototype, so schedules and capacity are sample data and persistence is limited to one browser; a production system would use an authoritative backend and transactions for cross-device capacity.”

## Scope boundary

Routes, schedules, and capacities are sample data. Bookings are stored only on the current device, which matches the local-persistence deliverable. This prototype does not claim cross-device inventory, GPS tracking, authentication, payments, QR check-in, or dispatcher administration.
