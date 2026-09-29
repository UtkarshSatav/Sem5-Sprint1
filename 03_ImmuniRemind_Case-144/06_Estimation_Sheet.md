# Estimation Sheet — ImmuniRemind

## 1. Inputs (given)

| Input | Value | Source |
|---|---|---|
| Children under age five | 36,000 | Case brief (given) |
| Scheduled doses per child | approximately 12 | Case brief (given) |
| Health posts | 40 | Case brief (given) |
| Pilot posts | 5 | Case brief (given) |
| Pilot length | 15 days | Plan, task H |
| Children missing at least one scheduled vaccine, now | 23% (child-level rate) | Case brief (given) |
| Target for children missing at least one dose | 10% | Case brief (given) |

## 2. Assumptions

| ID | Assumption |
|---|---|
| A1 | The under-5s are evenly spread over 5 years, so each annual birth cohort is 36,000 ÷ 5 = 7,200 children; doses fall due at a steady rate |
| A2 | Each dose generates 2 routine SMS (advance and due-day) |
| A3 | 10% of doses become overdue, and each gets 2 catch-up SMS |
| A4 | Registering a child takes 4 minutes |
| A5 | 2 workers are available per pilot post (10 in total) |
| A6 | A staff day is 8 hours |

## 3. Calculations

| # | Quantity | Formula | Working | Result | Uses assumption |
|---:|---|---|---|---:|---|
| 1 | Total doses tracked | children × doses per child | 36,000 × 12 | **432,000** | given |
| 2 | Children per post | children ÷ posts | 36,000 ÷ 40 | 900 | given |
| 3 | Doses per post | doses ÷ posts | 432,000 ÷ 40 | 10,800 | given |
| 4 | Annual birth cohort | children ÷ 5 years | 36,000 ÷ 5 | 7,200 | A1 |
| 5 | Doses falling due per year (steady state) | cohort × 12 | 7,200 × 12 | 86,400 | A1 |
| 6 | Doses per month | yearly doses ÷ 12 | 86,400 ÷ 12 | 7,200 | A1 |
| 7 | Doses per post per month | monthly doses ÷ posts | 7,200 ÷ 40 | 180 | A1 |
| 8 | Routine SMS per year | doses due × 2 | 86,400 × 2 | 172,800 | A2 |
| 9 | Catch-up SMS per year | doses due × 10% × 2 | 86,400 × 0.10 × 2 | 17,280 | A3 |
| 10 | Total SMS per year | routine + catch-up | 172,800 + 17,280 | 190,080 | A2, A3 |
| 11 | Total SMS per month | yearly ÷ 12 | 190,080 ÷ 12 | 15,840 | A2, A3 |
| 12 | Total SMS per post per month | monthly ÷ posts | 15,840 ÷ 40 | 396 | A2, A3 |
| 13 | Children missing at least one dose now | children × 23% | 36,000 × 0.23 | 8,280 | given |
| 14 | Children missing at least one dose at target | children × 10% | 36,000 × 0.10 | 3,600 | given |
| 15 | Reduction | now − target; ÷ now | 8,280 − 3,600 = 4,680; 4,680 ÷ 8,280 | 4,680 children; 56.5% relative | given |
| 16 | Pilot children and doses tracked (5 posts) | posts × children per post; × 12 | 5 × 900 = 4,500; 4,500 × 12 | 4,500 children; 54,000 doses | given |
| 17 | Doses falling due during the 15-day pilot | posts × doses per post per month × 15/30 | 5 × 180 × 15/30 | 450 | A1 |
| 18 | Pilot registration effort | children × minutes; ÷ 60; ÷ 8 h | 4,500 × 4 = 18,000 min = 300 h; 300 ÷ 8 | 37.5 staff-days | A4, A6 |
| 19 | Registration time with 10 workers | staff-days ÷ workers | 37.5 ÷ 10 | 3.75 days: registration completes by pilot day 4 (project day 40) | A4, A5, A6 |

Note: 23% is a child-level rate (23% of children miss at least one scheduled vaccine), not a dose-level rate.

## 4. Headline result

**36,000 × 12 = 432,000 doses to be tracked.**

## 5. Sensitivity

The case says "approximately 12" doses per child.

- 11 doses per child: 36,000 × 11 = 396,000
- 13 doses per child: 36,000 × 13 = 468,000

The range is 432,000 ± 36,000 (36,000 ÷ 432,000 = ±8.3%).

## 6. Why an estimate is not a promise

An estimate is a forecast conditioned on assumptions A1 to A6 and on the "approximately 12" doses-per-child input. If those change, the number changes: births, migration, catch-ups and schedule changes all move it. An estimate should therefore be presented as a range together with its assumptions, and re-estimated at each milestone as facts replace assumptions. A commitment is a separate management decision. It takes the estimate and adds a reserve for uncertainty, and it is made by the people accountable for delivery, not read directly off the calculation.
