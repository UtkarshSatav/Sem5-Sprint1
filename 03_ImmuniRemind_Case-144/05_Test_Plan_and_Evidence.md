# Test Plan and Evidence — ImmuniRemind

This document is the IEEE 829-lite test plan for ImmuniRemind, together with the test designs (equivalence classes, boundary value analysis, decision table) and the test evidence. The plan, fixture and test designs are planned artefacts. The test log and defect data in §6 and the figures in §7 are **Simulated for the case study**. They are not results from a real deployment.

## 1. Test plan (IEEE 829-lite)

**1.1 Identifier:** TP-IR-01

**1.2 Test items**

| Module | Requirements covered |
|---|---|
| Registration | FR-02, FR-03, FR-04 |
| Schedule generator (rules and status) | FR-05, FR-06, FR-07, FR-08 |
| SMS reminders | FR-09, FR-10 |
| Supervisor dashboard | FR-11, FR-12 |
| Auth/common | FR-01; NFR-03, NFR-05 |

**1.3 Features to be tested**
- Child registration and validation of date of birth and guardian contact
- Dose status calculation (NotYetDue, Due, Overdue, Missed) for all 12 fixture doses
- Series-predecessor and 4-week minimum-gap rules, and catch-up handling
- Reminder policy: advance SMS, due-day SMS, catch-up SMS (repeat after 14 days, maximum 2)
- Role and post-scope authorization, audit entries
- Supervisor due/overdue lists and report filters

**1.4 Features not tested**
- The Could-priority items in the SRS
- Real SMS gateway billing and operator-side delivery (the SMS simulator stands in for the gateway)
- Clinical validity of the fixture, which is a teaching fixture and not clinical guidance

**1.5 Approach**

| Level | Technique |
|---|---|
| Unit | Equivalence partitioning (§3), boundary value analysis by age in weeks (§4), decision table (§5) |
| Integration | Schedule generator to reminder queue to SMS simulator (success, failure, timeout, retry, duplicate job) |
| System | End-to-end flows: register, generate schedule, record dose, list due/overdue, send reminders |
| UAT | Five health-post workers run the task scripts on synthetic records |

**1.6 Entry criteria**
- The build is deployed to the test environment.
- The dose fixture (§2) is approved by the rule owner.

**1.7 Exit criteria**
- 100% of planned cases are executed.
- 0 open critical or high defects.
- DRE target ≥ 90% (measured in §7).

**1.8 Test environment:** synthetic records only, no real child or guardian data. An SMS simulator replaces the gateway.

**1.9 Schedule:** Task G (Testing) is planned for days 29–36. In the simulated actuals it ran on days 32–39 because Registration and Supervisor dashboard finished late.

**1.10 Roles**

| Role | Responsibility |
|---|---|
| QA lead | Owns this plan, confirms exit criteria, reports DRE and density |
| QA tester | Designs and executes cases, raises defects |
| Developer | Fixes defects, supports unit and integration tests |
| Rule owner (health authority) | Approves the fixture and expected results |
| Health-post workers (5) | Perform UAT |
| Project manager | Tracks schedule and change requests |

**1.11 Deliverables:** this document, the executed test log (§6), the defect log, and the DRE and defect-density report (§7).

## 2. Dose fixture

Teaching fixture aligned to India UIP timepoints — not clinical guidance. Ages are in completed weeks (`floor(days_since_birth / 7)`); 9 months is taken as 39 weeks and 16 months as 69 weeks.

| Code | Dose | Min age (wk) = due age | Max age (wk) | Series predecessor (≥ 4 wk earlier) |
|---|---|---:|---:|---|
| D01 | BCG | 0 | 52 | — |
| D02 | OPV-0 | 0 | 2 | — |
| D03 | Penta-1 | 6 | 52 | — |
| D04 | OPV-1 | 6 | 260 | — |
| D05 | Penta-2 | 10 | 52 | D03 |
| D06 | OPV-2 | 10 | 260 | D04 |
| D07 | Penta-3 | 14 | 52 | D05 |
| D08 | OPV-3 | 14 | 260 | D06 |
| D09 | MR-1 | 39 | 260 | — |
| D10 | MR-2 | 69 | 260 | D09 |
| D11 | DPT Booster-1 | 69 | 260 | D07 |
| D12 | OPV Booster | 69 | 260 | D08 |

**Status rule** (for age `a`, min age `m`, max age `M`, when the dose is not yet administered):
- `a < 0` → **Invalid** (a future date of birth)
- `a < m` → **NotYetDue**
- `m ≤ a ≤ m+4` and `a ≤ M` → **Due**
- `m+4 < a ≤ M` → **Overdue** (catch-up allowed)
- `a > M` → **Missed** (no longer eligible; refer to the medical officer)
- `a > 260` → out of programme scope (the child is over 5 and is not registered)

**Reminder policy:**
- Advance SMS 3 days before the due date, at 09:00 local time
- Due-day SMS at 09:00
- On becoming Overdue, a catch-up SMS, repeated after 14 days, with a maximum of 2 catch-ups

## 3. Equivalence classes

**3.1 Child age in weeks** (per dose, with m = min age and M = max age; representative values for Penta-1, m = 6, M = 52)

| Class | Range | Valid? | Expected status | Representative value (Penta-1, m = 6, M = 52) |
|---|---|---|---|---:|
| EC1 | a < 0 | No | Invalid (future DOB); rejected at registration | −1 |
| EC2 | 0 ≤ a < m | Yes | NotYetDue | 3 |
| EC3 | m ≤ a ≤ min(m+4, M) | Yes | Due | 8 |
| EC4 | m+4 < a ≤ M | Yes | Overdue | 30 |
| EC5 | M < a ≤ 260 | Yes | Missed (refer to the medical officer) | 100 |
| EC6 | a > 260 | No | Out of scope (over 5); rejected | 270 |

For doses with M = 260, EC5 is empty. The value 261 is then both Missed under the status rule (§4 records it so) and beyond programme scope (EC6).

**3.2 Non-age inputs**

| Input / function | Equivalence classes | Boundary values / expected handling |
|---|---|---|
| Guardian contact (FR-02, FR-09) | Valid configured phone format; missing; malformed; duplicate/ambiguous contact | Minimum/maximum accepted normalized length under the selected numbering policy; one below/at/one above; no send for invalid or ineligible contact |
| Authorization (FR-01/03/04/11) | Worker assigned to post; worker from another post; supervisor authorized scope; disabled/unauthenticated account | Exact post-scope boundary: permitted post succeeds; one unrelated post is denied; inactive and no-session cases are denied |
| Rule version (FR-06/07) | Approved active; approved historical; not-yet-effective; expired; unapproved; overlapping | Effective date day before/on/day after activation and end; no overlapping or unapproved rule silently selected; ambiguous cases require review |
| Report filter (FR-11/12) | No filter; valid date range; empty range; invalid range; unauthorized post | Start/end boundaries inclusive as specified; same-day range; end before start is rejected; totals equal matching visible rows |

## 4. Boundary Value Analysis by child age in weeks

For each dose the ages tested are {m−1, m, m+4, m+5, M, M+1}. Values below 0 are dropped, m+4 is clamped to M, and duplicates are removed. Where m+4 is clamped to M, m+5 would exceed M and is redundant with M+1, so it is not listed. Status is taken strictly from the rule in §2. The dose column shows (m, M).

**Week convention:** completed weeks = floor(days ÷ 7). So 41 days = 5 weeks is NotYetDue for Penta-1, and 42 days = 6 weeks is Due.

| TC ID | Dose | Age (wk) | Boundary | Expected status |
|---|---|---:|---|---|
| TC-BVA-D01-1 | BCG (0, 52) | 0 | m | Due |
| TC-BVA-D01-2 | BCG (0, 52) | 4 | m+4 | Due |
| TC-BVA-D01-3 | BCG (0, 52) | 5 | m+5 | Overdue |
| TC-BVA-D01-4 | BCG (0, 52) | 52 | M | Overdue |
| TC-BVA-D01-5 | BCG (0, 52) | 53 | M+1 | Missed |
| TC-BVA-D02-1 | OPV-0 (0, 2) | 0 | m | Due |
| TC-BVA-D02-2 | OPV-0 (0, 2) | 2 | M (m+4 clamped to M) | Due |
| TC-BVA-D02-3 | OPV-0 (0, 2) | 3 | M+1 | Missed |
| TC-BVA-D03-1 | Penta-1 (6, 52) | 5 | m−1 | NotYetDue |
| TC-BVA-D03-2 | Penta-1 (6, 52) | 6 | m | Due |
| TC-BVA-D03-3 | Penta-1 (6, 52) | 10 | m+4 | Due |
| TC-BVA-D03-4 | Penta-1 (6, 52) | 11 | m+5 | Overdue |
| TC-BVA-D03-5 | Penta-1 (6, 52) | 52 | M | Overdue |
| TC-BVA-D03-6 | Penta-1 (6, 52) | 53 | M+1 | Missed |
| TC-BVA-D04-1 | OPV-1 (6, 260) | 5 | m−1 | NotYetDue |
| TC-BVA-D04-2 | OPV-1 (6, 260) | 6 | m | Due |
| TC-BVA-D04-3 | OPV-1 (6, 260) | 10 | m+4 | Due |
| TC-BVA-D04-4 | OPV-1 (6, 260) | 11 | m+5 | Overdue |
| TC-BVA-D04-5 | OPV-1 (6, 260) | 260 | M | Overdue |
| TC-BVA-D04-6 | OPV-1 (6, 260) | 261 | M+1 | Missed |
| TC-BVA-D05-1 | Penta-2 (10, 52) | 9 | m−1 | NotYetDue |
| TC-BVA-D05-2 | Penta-2 (10, 52) | 10 | m | Due |
| TC-BVA-D05-3 | Penta-2 (10, 52) | 14 | m+4 | Due |
| TC-BVA-D05-4 | Penta-2 (10, 52) | 15 | m+5 | Overdue |
| TC-BVA-D05-5 | Penta-2 (10, 52) | 52 | M | Overdue |
| TC-BVA-D05-6 | Penta-2 (10, 52) | 53 | M+1 | Missed |
| TC-BVA-D06-1 | OPV-2 (10, 260) | 9 | m−1 | NotYetDue |
| TC-BVA-D06-2 | OPV-2 (10, 260) | 10 | m | Due |
| TC-BVA-D06-3 | OPV-2 (10, 260) | 14 | m+4 | Due |
| TC-BVA-D06-4 | OPV-2 (10, 260) | 15 | m+5 | Overdue |
| TC-BVA-D06-5 | OPV-2 (10, 260) | 260 | M | Overdue |
| TC-BVA-D06-6 | OPV-2 (10, 260) | 261 | M+1 | Missed |
| TC-BVA-D07-1 | Penta-3 (14, 52) | 13 | m−1 | NotYetDue |
| TC-BVA-D07-2 | Penta-3 (14, 52) | 14 | m | Due |
| TC-BVA-D07-3 | Penta-3 (14, 52) | 18 | m+4 | Due |
| TC-BVA-D07-4 | Penta-3 (14, 52) | 19 | m+5 | Overdue |
| TC-BVA-D07-5 | Penta-3 (14, 52) | 52 | M | Overdue |
| TC-BVA-D07-6 | Penta-3 (14, 52) | 53 | M+1 | Missed |
| TC-BVA-D08-1 | OPV-3 (14, 260) | 13 | m−1 | NotYetDue |
| TC-BVA-D08-2 | OPV-3 (14, 260) | 14 | m | Due |
| TC-BVA-D08-3 | OPV-3 (14, 260) | 18 | m+4 | Due |
| TC-BVA-D08-4 | OPV-3 (14, 260) | 19 | m+5 | Overdue |
| TC-BVA-D08-5 | OPV-3 (14, 260) | 260 | M | Overdue |
| TC-BVA-D08-6 | OPV-3 (14, 260) | 261 | M+1 | Missed |
| TC-BVA-D09-1 | MR-1 (39, 260) | 38 | m−1 | NotYetDue |
| TC-BVA-D09-2 | MR-1 (39, 260) | 39 | m | Due |
| TC-BVA-D09-3 | MR-1 (39, 260) | 43 | m+4 | Due |
| TC-BVA-D09-4 | MR-1 (39, 260) | 44 | m+5 | Overdue |
| TC-BVA-D09-5 | MR-1 (39, 260) | 260 | M | Overdue |
| TC-BVA-D09-6 | MR-1 (39, 260) | 261 | M+1 | Missed |
| TC-BVA-D10-1 | MR-2 (69, 260) | 68 | m−1 | NotYetDue |
| TC-BVA-D10-2 | MR-2 (69, 260) | 69 | m | Due |
| TC-BVA-D10-3 | MR-2 (69, 260) | 73 | m+4 | Due |
| TC-BVA-D10-4 | MR-2 (69, 260) | 74 | m+5 | Overdue |
| TC-BVA-D10-5 | MR-2 (69, 260) | 260 | M | Overdue |
| TC-BVA-D10-6 | MR-2 (69, 260) | 261 | M+1 | Missed |
| TC-BVA-D11-1 | DPT Booster-1 (69, 260) | 68 | m−1 | NotYetDue |
| TC-BVA-D11-2 | DPT Booster-1 (69, 260) | 69 | m | Due |
| TC-BVA-D11-3 | DPT Booster-1 (69, 260) | 73 | m+4 | Due |
| TC-BVA-D11-4 | DPT Booster-1 (69, 260) | 74 | m+5 | Overdue |
| TC-BVA-D11-5 | DPT Booster-1 (69, 260) | 260 | M | Overdue |
| TC-BVA-D11-6 | DPT Booster-1 (69, 260) | 261 | M+1 | Missed |
| TC-BVA-D12-1 | OPV Booster (69, 260) | 68 | m−1 | NotYetDue |
| TC-BVA-D12-2 | OPV Booster (69, 260) | 69 | m | Due |
| TC-BVA-D12-3 | OPV Booster (69, 260) | 73 | m+4 | Due |
| TC-BVA-D12-4 | OPV Booster (69, 260) | 74 | m+5 | Overdue |
| TC-BVA-D12-5 | OPV Booster (69, 260) | 260 | M | Overdue |
| TC-BVA-D12-6 | OPV Booster (69, 260) | 261 | M+1 | Missed |

Age 261 exceeds M = 260 for the last doses, so the status rule gives Missed. It is also beyond programme scope (EC6) and such a child is not registered.

## 5. Decision table — dose-due and catch-up

**Conditions**
- C1: dose already administered?
- C2: age ≥ min age?
- C3: age ≤ max age?
- C4: series predecessor administered (or none required)?
- C5: ≥ 4 weeks since the predecessor (or none required)?
- C6: age ≤ min age + 4 weeks?

**Actions**
- A1: mark Administered, no reminder
- A2: NotYetDue; schedule the advance SMS for due − 3 days
- A3: Missed; refer to the medical officer, no SMS
- A4: blocked; schedule the predecessor dose first
- A5: wait; next due date = predecessor date + 4 weeks
- A6: Due; send the due-day SMS
- A7: Overdue; add to the overdue list, send the catch-up SMS and book a catch-up session

**Rules** (Y / N / –)

| | R1 | R2 | R3 | R4 | R5 | R6 | R7 |
|---|---|---|---|---|---|---|---|
| C1 | Y | N | N | N | N | N | N |
| C2 | – | N | Y | Y | Y | Y | Y |
| C3 | – | – | N | Y | Y | Y | Y |
| C4 | – | – | – | N | Y | Y | Y |
| C5 | – | – | – | – | N | Y | Y |
| C6 | – | – | – | – | – | Y | N |
| Action | A1 | A2 | A3 | A4 | A5 | A6 | A7 |

**Test cases**

| TC ID | Rule | Child (concrete) | Expected action |
|---|---|---|---|
| TC-DT-R1 | R1 | BCG already given at birth; child is now 20 weeks | A1: Administered, no reminder |
| TC-DT-R2 | R2 | Penta-1 not given; child is 3 weeks old (m = 6) | A2: NotYetDue; advance SMS scheduled for due − 3 days |
| TC-DT-R3 | R3 | OPV-0 not given; child is 5 weeks old (M = 2) | A3: Missed; refer to the medical officer, no SMS |
| TC-DT-R4 | R4 | Penta-2 not given; child is 11 weeks old; Penta-1 (D03) not given | A4: blocked; schedule Penta-1 first |
| TC-DT-R5 | R5 | Penta-2 not given; child is 10 weeks old; Penta-1 given at 8 weeks, a gap of 2 weeks < 4 | A5: wait; next due at 8 + 4 = 12 weeks |
| TC-DT-R6 | R6 | Penta-2 not given; child is 12 weeks old (≤ m+4 = 14); Penta-1 given at 6 weeks, a gap of 6 weeks | A6: Due; due-day SMS sent |
| TC-DT-R7 | R7 | Penta-2 not given; child is 20 weeks old (> m+4 = 14, ≤ M = 52); Penta-1 given at 6 weeks, a gap of 14 weeks | A7: Overdue; overdue list, catch-up SMS, catch-up session booked |

The rule set is complete and mutually exclusive: every combination of the six conditions reaches exactly one rule, because the conditions are evaluated in order and the first deciding answer (Y on C1, N on C2 to C5, or the final Y/N on C6) fixes the outcome.

## 6. Test log (Simulated for the case study)

All figures in this section are invented for the case study and are not measured results.

**6.1 Execution summary by level**

| Level | Run | Passed | Failed | Defects raised |
|---|---:|---:|---:|---:|
| Unit | 120 | 106 | 14 | 14 |
| Integration | 40 | 31 | 9 | 9 |
| System | 48 | 41 | 7 | 7 |
| UAT | 20 | 16 | 4 | 4 |
| **Total** | **228** | **194** | **34** | **34** |

Each failure is one unique defect. 100% of planned cases were executed.

**6.2 Defects by phase**

| Phase | Defects |
|---|---:|
| Requirements review | 6 |
| Design review | 5 |
| Unit | 14 |
| Integration | 9 |
| System | 7 |
| UAT | 4 |
| **Pre-release total** | **45** |
| Post-release (first 15 pilot days) | 3 |
| **Total** | **48** |

The 11 defects from requirements and design review were found by inspection, not by test execution, which is why test failures total 34.

**6.3 Defects by severity**

| Severity | Pre-release | Post-release | Total |
|---|---:|---:|---:|
| Critical | 2 | 0 | 2 |
| High | 8 | 1 | 9 |
| Medium | 19 | 2 | 21 |
| Low | 16 | 0 | 16 |
| **Total** | **45** | **3** | **48** |

**6.4 Representative defects (10 of 48)**

| ID | Phase | Module | Severity | Summary | Status |
|---|---|---|---|---|---|
| DEF-003 | Requirements review | Schedule generator | High | Max age for OPV-0 not stated in the SRS | Closed |
| DEF-009 | Design review | Auth/common | High | Supervisor post-scope check missing from report service | Closed |
| DEF-017 | Unit | Schedule generator | Critical | Penta-1 at exactly 10 weeks classed as Overdue (off-by-one at m+4) | Closed |
| DEF-024 | Unit | Schedule generator | Medium | Age computed as days ÷ 7 rounded, not floored | Closed |
| DEF-031 | Unit | Registration | Medium | Future date of birth accepted | Closed |
| DEF-038 | Integration | SMS reminders | Critical | Retry created a duplicate reminder job | Closed |
| DEF-046 | Integration | Registration | Low | Duplicate child not flagged for identity review | Closed |
| DEF-052 | System | Supervisor dashboard | Low | Overdue count excluded children at exactly m+5 weeks | Closed |
| DEF-058 | UAT | Registration | Low | Contact-number field label unclear to workers | Closed |
| DEF-061 | Post-release | SMS reminders | High | SMS delivery-receipt timeout not retried | Fixed in pilot patch |

**6.5 Module size and defects (module sizes assumed)**

| Module | KLOC | Defects |
|---|---:|---:|
| Registration | 3.0 | 12 |
| Schedule generator | 2.5 | 14 |
| SMS reminders | 2.0 | 10 |
| Supervisor dashboard | 3.5 | 9 |
| Auth/common | 1.0 | 3 |
| **Total** | **12.0** | **48** |

## 7. Calculations (Simulated for the case study)

The inputs come from the simulated log in §6.

| Measure | Formula and substitution | Result |
|---|---|---:|
| DRE | pre-release ÷ (pre-release + post-release) × 100 = 45 ÷ (45 + 3) × 100 | 93.75% |
| Test-phase DRE | (14 + 9 + 7 + 4) ÷ (34 + 3) = 34 ÷ 37 | 91.9% |
| Overall defect density | 48 ÷ 12.0 | 4.0 defects/KLOC |

**Per-module defect density**

| Module | Substitution | Density (defects/KLOC) |
|---|---|---:|
| Registration | 12 ÷ 3.0 | 4.0 |
| Schedule generator | 14 ÷ 2.5 | 5.6 |
| SMS reminders | 10 ÷ 2.0 | 5.0 |
| Supervisor dashboard | 9 ÷ 3.5 | 2.57 |
| Auth/common | 3 ÷ 1.0 | 3.0 |

**Interpretation**
- DRE of 93.75% (test-phase 91.9%) is at or above the 90% target, so the exit criterion is met.
- The schedule generator has the highest density (5.6), so it gets extra review before the 40-post rollout.
- The figures depend on the length of the post-release window: a longer window would likely reveal more escaped defects and lower the DRE.
