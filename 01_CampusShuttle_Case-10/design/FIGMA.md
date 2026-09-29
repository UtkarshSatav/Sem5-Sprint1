# CampusShuttle Figma design

- Figma file: https://www.figma.com/design/jscHLuJNuLOS6WgEtpsQzH
- Prototype: https://www.figma.com/proto/jscHLuJNuLOS6WgEtpsQzH?node-id=2-2&starting-point-node-id=2-2

File "CampusShuttle — Case 10" has two pages: `01 Styles` and `02 Flow`.

## Flow frames (390x844, each with a "BOOKING JOURNEY · STEP n OF 4" strip)
1. `1 Timetable` (step 1): header, live strip, route filter chips, four trip cards, route legend. Card 1 links to frame 2.
2. `2 Trip detail` (step 2): North Loop header, seat meter, times, stop sequence, "Reserve a seat" (links to frame 3).
3. `3 Reserve` (step 3): dimmed frame 2 with a "Confirm your seat" dialog; "Reserve seat" links to frame 4.
4. `4 Confirmation` (step 4): "Booking confirmed", booking ID CS-1727600000000; "View My Bookings" links to frame 5.
5. `5 My Bookings` (step 4): booking card with "Cancel" (links back to frame 1).

Frame 1 is the prototype starting point.

## Styles
- Colour styles: Primary #2456C7; North Loop #2F6FED, Residences #149477, West Connector #E2782D; Surface #F5F7FB, Card #FFFFFF, Border #E8ECF3; Text #182230, Muted #667085, Success #067647, Low-seat #FFF1E8.
- Text styles (Inter): Display 34/800, Title 20/700, Body 14/400, Caption 12/400, Label 10/700 uppercase with 0.7 letter-spacing.
- One colour per route so each line is recognisable at a glance; the palette comes from a Material 3 seed colour.

`campusshuttle-flow.svg` is the earlier static export of this flow.
