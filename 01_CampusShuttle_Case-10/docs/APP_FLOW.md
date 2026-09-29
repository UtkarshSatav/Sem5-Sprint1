# CampusShuttle app flow

```mermaid
flowchart LR
    A[Route Timetable] -->|Select trip| B[Trip Detail]
    B -->|Reserve seat| C[Confirmation prompt]
    C -->|Confirm reservation| D[Provider decrements seats]
    D --> E[Booking confirmed]
    E --> F[Persist active booking locally]
    F --> G[My Bookings]
    G -->|Cancel| H[Provider restores seat]
    H --> A
```

The interface displays the four journey cues on the relevant screens: Timetable, Trip details, Reserve seat, and Confirmation. The timetable and booking collections use `ListView`; trip and booking content use Material 3 `Card` and `Icon` widgets.

## State ownership

`ShuttleStore` extends `ChangeNotifier` and owns the trip list and active bookings. Widgets read it through Provider. A successful reservation updates the selected trip and booking list before calling `notifyListeners()`, so Route Timetable, Trip Detail, summary metrics, and My Bookings stay synchronized.

## Persistence

Bookings are encoded as JSON under `campus_shuttle_bookings_v1` in `shared_preferences`. On startup, the store accepts only known trip IDs, ignores malformed records, and prevents duplicate bookings for the same departure. Loading a valid booking decrements that trip’s displayed availability.

## Edge cases

- A trip cannot be booked twice on the same device.
- A trip with zero available seats disables reservation.
- Unknown, malformed, and duplicate stored bookings are ignored.
- Cancellation restores at most the trip’s initial available-seat count.
- Search with no match shows a clear empty state.

## Data boundary

Trip definitions are in app memory. Active bookings are stored locally. There is no remote database in this assessed prototype. A production multi-user implementation would require a server-side booking transaction so concurrent students cannot oversell capacity.

## Data model

```mermaid
classDiagram
  class ShuttleRoute { +id +name +color }
  class ShuttleTrip { +id +origin +destination +stops +departure +arrival +capacity +available +othersReserved +reserved() }
  class ShuttleBooking { +id +tripId +bookedAt +toJson() +fromJson() }
  class ShuttleStore { +trips +bookings +reserve(tripId) +cancel(bookingId) +load() +simulateOtherStudent() }
  ShuttleRoute "1" --> "many" ShuttleTrip : colour-coded line
  ShuttleTrip "1" --> "0..1" ShuttleBooking : this device
  ShuttleStore o-- ShuttleTrip
  ShuttleStore o-- ShuttleBooking
```

Invariant for every trip: `available + othersReserved + (booked on this device ? 1 : 0) = capacity`.

## Live updates

The brief asks for seat counts that update live as other students book. With no backend in this prototype, `ShuttleStore.startLiveUpdates()` runs a timer that simulates another student booking or cancelling every 6 seconds and calls `notifyListeners()`. Timetable, Trip Detail and My Bookings all rebuild at the same moment. That is the synchronisation Provider provides. Simulated students never take a trip's last seat, so the demo user can always book. In production, the timer would be replaced by a server stream (for example a Firestore snapshot listener) that feeds the same store.
