import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(
    create: (_) => ShuttleStore()..load(),
    child: const CampusShuttleApp(),
  ));
}

class ShuttleTrip {
  ShuttleTrip({
    required this.id,
    required this.route,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.departure,
    required this.arrival,
    required this.available,
    required this.capacity,
    required this.color,
  }) : initialAvailable = available;

  final String id;
  final String route;
  final String origin;
  final String destination;
  final List<String> stops;
  final String departure;
  final String arrival;
  final int capacity;
  final int initialAvailable;
  final Color color;
  int available;
}

class ShuttleBooking {
  const ShuttleBooking({
    required this.id,
    required this.tripId,
    required this.bookedAt,
  });

  final String id;
  final String tripId;
  final DateTime bookedAt;

  Map<String, String> toJson() => {
        'id': id,
        'tripId': tripId,
        'bookedAt': bookedAt.toIso8601String(),
      };

  factory ShuttleBooking.fromJson(Map<String, dynamic> json) => ShuttleBooking(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        bookedAt: DateTime.parse(json['bookedAt'] as String),
      );
}

class ShuttleStore extends ChangeNotifier {
  static const _storageKey = 'campus_shuttle_bookings_v1';

  final List<ShuttleTrip> _trips = [
    ShuttleTrip(
      id: 'north-0815',
      route: 'North Loop',
      origin: 'North Gate',
      destination: 'Main Campus',
      stops: const [
        'North Gate',
        'Library Square',
        'Science Block',
        'Main Campus'
      ],
      departure: '8:15 AM',
      arrival: '8:35 AM',
      available: 8,
      capacity: 24,
      color: const Color(0xFF2F6FED),
    ),
    ShuttleTrip(
      id: 'res-0845',
      route: 'Residences',
      origin: 'Maple Residence',
      destination: 'Main Campus',
      stops: const [
        'Maple Residence',
        'Oak Hall',
        'Sports Centre',
        'Main Campus'
      ],
      departure: '8:45 AM',
      arrival: '9:05 AM',
      available: 4,
      capacity: 20,
      color: const Color(0xFF149477),
    ),
    ShuttleTrip(
      id: 'west-0915',
      route: 'West Connector',
      origin: 'West Parking',
      destination: 'Engineering',
      stops: const [
        'West Parking',
        'Arts Quad',
        'Student Union',
        'Engineering'
      ],
      departure: '9:15 AM',
      arrival: '9:32 AM',
      available: 12,
      capacity: 24,
      color: const Color(0xFFE2782D),
    ),
    ShuttleTrip(
      id: 'north-0945',
      route: 'North Loop',
      origin: 'North Gate',
      destination: 'Main Campus',
      stops: const [
        'North Gate',
        'Library Square',
        'Science Block',
        'Main Campus'
      ],
      departure: '9:45 AM',
      arrival: '10:05 AM',
      available: 2,
      capacity: 24,
      color: const Color(0xFF2F6FED),
    ),
  ];

  final List<ShuttleBooking> _bookings = [];
  bool ready = false;

  List<ShuttleTrip> get trips => List.unmodifiable(_trips);
  List<ShuttleBooking> get bookings => List.unmodifiable(_bookings);
  ShuttleTrip trip(String id) => _trips.firstWhere((item) => item.id == id);
  int get totalSeats => _trips.fold(0, (sum, item) => sum + item.available);
  bool isBooked(String tripId) =>
      _bookings.any((item) => item.tripId == tripId);

  Future<void> load() async {
    for (final trip in _trips) {
      trip.available = trip.initialAvailable;
    }
    _bookings.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final seenTrips = <String>{};
          for (final item in decoded.whereType<Map>()) {
            try {
              final booking =
                  ShuttleBooking.fromJson(Map<String, dynamic>.from(item));
              final known = _trips.any((trip) => trip.id == booking.tripId);
              if (!known || !seenTrips.add(booking.tripId)) continue;
              final selected = trip(booking.tripId);
              if (selected.available <= 0) continue;
              selected.available--;
              _bookings.add(booking);
            } catch (_) {
              // Ignore malformed browser-local demo entries.
            }
          }
        }
      }
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  bool reserve(String tripId, {DateTime? serviceDate}) {
    if (!ready || isBooked(tripId)) return false;
    final selected = trip(tripId);
    if (selected.available <= 0) return false;
    selected.available--;
    _bookings.add(ShuttleBooking(
      id: 'CS-${DateTime.now().microsecondsSinceEpoch}',
      tripId: tripId,
      bookedAt: serviceDate ?? DateTime.now(),
    ));
    notifyListeners();
    unawaited(_save());
    return true;
  }

  void cancel(String bookingId) {
    final index = _bookings.indexWhere((item) => item.id == bookingId);
    if (index < 0) return;
    final booking = _bookings.removeAt(index);
    final selected = trip(booking.tripId);
    if (selected.available < selected.initialAvailable) selected.available++;
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_bookings.map((item) => item.toJson()).toList()),
    );
  }
}

class CampusShuttleApp extends StatelessWidget {
  const CampusShuttleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CampusShuttle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2456C7)),
          scaffoldBackgroundColor: const Color(0xFFF5F7FB),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE8ECF3)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9DFEA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9DFEA)),
            ),
          ),
        ),
        home: const ShuttleHome(),
      );
}

class ShuttleHome extends StatefulWidget {
  const ShuttleHome({super.key});

  @override
  State<ShuttleHome> createState() => _ShuttleHomeState();
}

class _ShuttleHomeState extends State<ShuttleHome> {
  int _tab = 0;
  String? _selectedTrip;

  void _go(int tab) => setState(() {
        _tab = tab;
        _selectedTrip = null;
      });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShuttleStore>();
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final Widget body;
    if (!store.ready) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_selectedTrip != null) {
      body = TripDetail(
        tripId: _selectedTrip!,
        onBack: () => setState(() => _selectedTrip = null),
        onBookings: () => _go(1),
      );
    } else if (_tab == 1) {
      body = BookingList(onBrowse: () => _go(0));
    } else {
      body = Timetable(onSelect: (id) => setState(() => _selectedTrip = id));
    }
    return Scaffold(
      body: SafeArea(
        child: Row(children: [
          if (wide) _DesktopNav(selected: _tab, onSelect: _go),
          Expanded(
            child: Column(children: [
              const _TopBar(),
              Expanded(child: body),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _go,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.schedule_rounded), label: 'Timetable'),
                NavigationDestination(
                    icon: Icon(Icons.confirmation_number_outlined),
                    selectedIcon: Icon(Icons.confirmation_number_rounded),
                    label: 'My Bookings'),
              ],
            ),
    );
  }
}

class _DesktopNav extends StatelessWidget {
  const _DesktopNav({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        width: 250,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 28, 16, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Brand(),
          const SizedBox(height: 48),
          _NavTile(
            icon: Icons.schedule_rounded,
            label: 'Route timetable',
            selected: selected == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.confirmation_number_outlined,
            label: 'My bookings',
            selected: selected == 1,
            onTap: () => onSelect(1),
          ),
          const Spacer(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('CASE 10 · LOCAL DEMO',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => const Row(children: [
        Icon(Icons.directions_bus_filled_rounded,
            color: Color(0xFF2456C7), size: 29),
        SizedBox(width: 10),
        Text('CampusShuttle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ]);
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFFEAF0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        leading: Icon(icon, size: 20),
        title: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        onTap: onTap,
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2))),
        ),
        child: Row(children: [
          if (MediaQuery.sizeOf(context).width < 920) const _Brand(),
          const Spacer(),
          const Icon(Icons.calendar_today_rounded,
              size: 17, color: Color(0xFF667085)),
          const SizedBox(width: 8),
          Text(_todayLabel(),
              style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
        ]),
      );
}

class Timetable extends StatefulWidget {
  const Timetable({super.key, required this.onSelect});
  final ValueChanged<String> onSelect;
  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  final _search = TextEditingController();
  String _route = 'All routes';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShuttleStore>();
    final query = _search.text.trim().toLowerCase();
    final trips = store.trips.where((trip) {
      final routeMatch = _route == 'All routes' || trip.route == _route;
      final text =
          '${trip.route} ${trip.origin} ${trip.destination} ${trip.stops.join(' ')}'
              .toLowerCase();
      return routeMatch && (query.isEmpty || text.contains(query));
    }).toList();
    final compact = MediaQuery.sizeOf(context).width < 720;

    return SingleChildScrollView(
      padding:
          EdgeInsets.fromLTRB(compact ? 18 : 38, 28, compact ? 18 : 38, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Campus transit · sample schedule',
                style: TextStyle(fontSize: 13, color: Color(0xFF667085))),
            const SizedBox(height: 7),
            Text('Plan a campus ride',
                style: TextStyle(
                    fontSize: compact ? 29 : 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8)),
            const SizedBox(height: 7),
            const Text('Find a route, inspect its stops, and reserve one seat.',
                style: TextStyle(color: Color(0xFF667085))),
            const SizedBox(height: 18),
            const _JourneyProgress(current: 0),
            const SizedBox(height: 14),
            const _DemoNotice(),
            const SizedBox(height: 18),
            _Overview(store: store),
            const SizedBox(height: 28),
            Row(children: [
              const Expanded(
                child: Text('Scheduled departures',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              Text('${trips.length} trips',
                  style: const TextStyle(color: Color(0xFF667085))),
            ]),
            const SizedBox(height: 13),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search routes or stops',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close_rounded)),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All routes',
                  'North Loop',
                  'Residences',
                  'West Connector'
                ]
                    .map((route) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(route),
                            selected: _route == route,
                            onSelected: (_) => setState(() => _route = route),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (trips.isEmpty)
              const _EmptySearch()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return _TripCard(
                    trip: trip,
                    booked: store.isBooked(trip.id),
                    onTap: () => widget.onSelect(trip.id),
                  );
                },
              ),
            const SizedBox(height: 8),
            const _RouteLegend(),
          ]),
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF2456C7)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Demo timetable · Provider keeps seat counts synchronized across screens. Active bookings persist in this browser.',
              style: TextStyle(color: Color(0xFF344054), height: 1.4),
            ),
          ),
        ]),
      );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.store});
  final ShuttleStore store;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(spacing: 36, runSpacing: 18, children: [
            _Metric(
                icon: Icons.directions_bus_outlined,
                value: '${store.trips.length}',
                label: 'Departures today'),
            _Metric(
                icon: Icons.event_seat_outlined,
                value: '${store.totalSeats}',
                label: 'Seats available'),
            _Metric(
                icon: Icons.confirmation_number_outlined,
                value: '${store.bookings.length}',
                label: 'Your bookings'),
          ]),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 190,
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2456C7)),
          ),
          const SizedBox(width: 13),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
          ]),
        ]),
      );
}

class _TripCard extends StatelessWidget {
  const _TripCard(
      {required this.trip, required this.booked, required this.onTap});
  final ShuttleTrip trip;
  final bool booked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: InkWell(
            key: ValueKey('trip-card-${trip.id}'),
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(builder: (context, box) {
                final route = Row(children: [
                  Container(
                    width: 5,
                    height: 62,
                    decoration: BoxDecoration(
                        color: trip.color,
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.route,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Text('${trip.origin}  →  ${trip.destination}',
                              style: const TextStyle(color: Color(0xFF667085))),
                          if (booked) ...[
                            const SizedBox(height: 7),
                            const Text('✓ Reserved',
                                style: TextStyle(
                                    color: Color(0xFF067647),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ]),
                  ),
                ]);
                final schedule = Row(mainAxisSize: MainAxisSize.min, children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.departure,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        Text('Arrives ${trip.arrival}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF667085))),
                      ]),
                  const SizedBox(width: 20),
                  _SeatBadge(trip: trip),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF98A2B3)),
                ]);
                return box.maxWidth < 610
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            route,
                            const SizedBox(height: 16),
                            schedule,
                          ])
                    : Row(children: [Expanded(child: route), schedule]);
              }),
            ),
          ),
        ),
      );
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.trip});
  final ShuttleTrip trip;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: trip.available <= 3
              ? const Color(0xFFFFF1E8)
              : const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.event_seat_outlined, size: 16),
          const SizedBox(width: 6),
          Text('${trip.available} left',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(34),
          child: Center(child: Text('No departures match this search.')),
        ),
      );
}

class TripDetail extends StatelessWidget {
  const TripDetail({
    super.key,
    required this.tripId,
    required this.onBack,
    required this.onBookings,
  });
  final String tripId;
  final VoidCallback onBack;
  final VoidCallback onBookings;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShuttleStore>();
    final trip = store.trip(tripId);
    final booked = store.isBooked(tripId);
    final compact = MediaQuery.sizeOf(context).width < 720;
    return SingleChildScrollView(
      padding:
          EdgeInsets.fromLTRB(compact ? 18 : 38, 20, compact ? 18 : 38, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to timetable'),
            ),
            const SizedBox(height: 8),
            const _JourneyProgress(current: 1),
            const SizedBox(height: 18),
            Row(children: [
              Container(
                width: 6,
                height: 58,
                decoration: BoxDecoration(
                    color: trip.color, borderRadius: BorderRadius.circular(5)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.route,
                          style: TextStyle(
                              fontSize: compact ? 28 : 34,
                              fontWeight: FontWeight.w800)),
                      Text('${trip.origin} → ${trip.destination}',
                          style: const TextStyle(color: Color(0xFF667085))),
                    ]),
              ),
              _SeatBadge(trip: trip),
            ]),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trip details',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: _PlaceTime(
                                label: 'Departure',
                                time: trip.departure,
                                place: trip.origin)),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Color(0xFF98A2B3)),
                        const SizedBox(width: 22),
                        Expanded(
                            child: _PlaceTime(
                                label: 'Arrival',
                                time: trip.arrival,
                                place: trip.destination)),
                      ]),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 18),
                      const Text('Stops along this route',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      for (var i = 0; i < trip.stops.length; i++)
                        _StopRow(
                          name: trip.stops[i],
                          color: trip.color,
                          first: i == 0,
                          last: i == trip.stops.length - 1,
                        ),
                    ]),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: booked
                  ? FilledButton.icon(
                      onPressed: onBookings,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Seat reserved · View My Bookings'))
                  : FilledButton.icon(
                      onPressed: trip.available == 0
                          ? null
                          : () =>
                              _confirmReservation(context, trip, onBookings),
                      icon: const Icon(Icons.event_seat_rounded),
                      label: Text(trip.available == 0
                          ? 'No seats available'
                          : 'Reserve a seat'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 17))),
            ),
          ]),
        ),
      ),
    );
  }
}

Future<void> _confirmReservation(
  BuildContext context,
  ShuttleTrip trip,
  VoidCallback onBookings,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Confirm your seat'),
      content: Text(
          'Step 3 of 4 · Reserve\n\n${trip.route}\n${trip.departure} · ${trip.origin} to ${trip.destination}\n\nThe booking will be saved on this device.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Go back')),
        FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reserve seat')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final reserved = context.read<ShuttleStore>().reserve(trip.id);
  if (!reserved) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('This trip is already booked or no longer available.'),
    ));
    return;
  }

  if (!context.mounted) return;
  final viewBookings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.check_circle_rounded,
          size: 44, color: Color(0xFF067647)),
      title: const Text('Booking confirmed'),
      content: Text(
          'Step 4 of 4 · Confirmation\n\n${trip.route} at ${trip.departure}\n${trip.origin} to ${trip.destination}\n\nThe available-seat count has been updated through Provider and this booking is saved on this device.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay on trip')),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.confirmation_number_outlined),
          label: const Text('View My Bookings'),
        ),
      ],
    ),
  );
  if (viewBookings == true && context.mounted) onBookings();
}

class _PlaceTime extends StatelessWidget {
  const _PlaceTime(
      {required this.label, required this.time, required this.place});
  final String label;
  final String time;
  final String place;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: .8,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(time,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(place, style: const TextStyle(color: Color(0xFF667085))),
        ],
      );
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.name,
    required this.color,
    required this.first,
    required this.last,
  });
  final String name;
  final Color color;
  final bool first;
  final bool last;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: Row(children: [
          SizedBox(
            width: 18,
            child: Column(children: [
              Expanded(
                  child: Container(
                      width: 2,
                      color: first
                          ? Colors.transparent
                          : color.withValues(alpha: .25))),
              Container(
                width: first || last ? 11 : 8,
                height: first || last ? 11 : 8,
                decoration: BoxDecoration(
                    color: first || last ? color : const Color(0xFFB7C0CF),
                    shape: BoxShape.circle),
              ),
              Expanded(
                  child: Container(
                      width: 2,
                      color: last
                          ? Colors.transparent
                          : color.withValues(alpha: .25))),
            ]),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    fontWeight:
                        first || last ? FontWeight.w700 : FontWeight.w500)),
          ),
          if (first || last)
            Text(first ? 'PICKUP' : 'DESTINATION',
                style: const TextStyle(
                    fontSize: 9, letterSpacing: .6, color: Color(0xFF667085))),
        ]),
      );
}

class BookingList extends StatelessWidget {
  const BookingList({super.key, required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShuttleStore>();
    final compact = MediaQuery.sizeOf(context).width < 720;
    return SingleChildScrollView(
      padding:
          EdgeInsets.fromLTRB(compact ? 18 : 38, 28, compact ? 18 : 38, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your trips',
                style: TextStyle(fontSize: 13, color: Color(0xFF667085))),
            const SizedBox(height: 7),
            Text('My Bookings',
                style: TextStyle(
                    fontSize: compact ? 29 : 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8)),
            const SizedBox(height: 7),
            const Text('Manage seats reserved on this device.',
                style: TextStyle(color: Color(0xFF667085))),
            const SizedBox(height: 18),
            const _JourneyProgress(current: 3),
            const SizedBox(height: 20),
            if (store.bookings.isEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
                  child: Center(
                    child: Column(children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 42, color: Color(0xFF2456C7)),
                      const SizedBox(height: 15),
                      const Text('No bookings yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 7),
                      const Text(
                          'Choose a departure and reserve a seat to see it here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF667085))),
                      const SizedBox(height: 17),
                      OutlinedButton.icon(
                        onPressed: onBrowse,
                        icon: const Icon(Icons.schedule_rounded),
                        label: const Text('Browse departures'),
                      ),
                    ]),
                  ),
                ),
              )
            else ...[
              Text(
                '${store.bookings.length} ${store.bookings.length == 1 ? 'reservation' : 'reservations'}',
                style: const TextStyle(color: Color(0xFF667085)),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: store.bookings.length,
                itemBuilder: (context, index) {
                  final booking =
                      store.bookings[store.bookings.length - 1 - index];
                  return _BookingCard(booking: booking);
                },
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final ShuttleBooking booking;
  @override
  Widget build(BuildContext context) {
    final trip = context.read<ShuttleStore>().trip(booking.tripId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(builder: (context, box) {
            final details = Row(children: [
              Container(
                width: 5,
                height: 50,
                decoration: BoxDecoration(
                    color: trip.color, borderRadius: BorderRadius.circular(5)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.route,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${trip.origin} → ${trip.destination}',
                          style: const TextStyle(color: Color(0xFF667085))),
                    ]),
              ),
            ]);
            final action = Row(mainAxisSize: MainAxisSize.min, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip.departure,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Booked ${_shortDate(booking.bookedAt)}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF667085))),
              ]),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => _confirmCancellation(context, booking, trip),
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('Cancel'),
              ),
            ]);
            return box.maxWidth < 560
                ? Column(children: [
                    details,
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ])
                : Row(children: [Expanded(child: details), action]);
          }),
        ),
      ),
    );
  }
}

Future<void> _confirmCancellation(
  BuildContext context,
  ShuttleBooking booking,
  ShuttleTrip trip,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel this booking?'),
      content: Text(
          '${trip.route} at ${trip.departure}\n\nThe seat will return to availability.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking')),
        FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel booking')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  context.read<ShuttleStore>().cancel(booking.id);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Booking cancelled. Seat count restored.')),
  );
}

class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final labels = compact
              ? const ['Timetable', 'Trip', 'Reserve', 'Done']
              : const [
                  'Timetable',
                  'Trip details',
                  'Reserve seat',
                  'Confirmation'
                ];
          return Semantics(
            label: 'Booking journey, step ${current + 1} of 4',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKING JOURNEY  ·  STEP ${current + 1} OF 4',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(labels.length, (index) {
                      final reached = index <= current;
                      final active = index == current;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: index == labels.length - 1 ? 0 : 7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: reached
                                      ? const Color(0xFF2456C7)
                                      : const Color(0xFFDDE3ED),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                labels[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: reached
                                      ? const Color(0xFF182230)
                                      : const Color(0xFF7D899B),
                                  fontSize: compact ? 10 : 11,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _RouteLegend extends StatelessWidget {
  const _RouteLegend();
  @override
  Widget build(BuildContext context) => const Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _LegendDot(color: Color(0xFF2F6FED), label: 'North Loop'),
          _LegendDot(color: Color(0xFF149477), label: 'Residences'),
          _LegendDot(color: Color(0xFFE2782D), label: 'West Connector'),
        ],
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
      ]);
}

String _todayLabel() {
  final now = DateTime.now();
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]}';
}
