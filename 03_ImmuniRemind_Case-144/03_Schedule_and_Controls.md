# Project Plan — ImmuniRemind

## 1. Planning basis and dose volume

The case supplies 36,000 children under age five and approximately 12 scheduled doses per child: **36,000 × 12 = 432,000 doses to be tracked**.
This is a planning estimate conditioned on stated assumptions, not a promise. See `06_Estimation_Sheet.md` for every formula, assumption and the sensitivity range. The baseline problem is child-level: the case reports that 23% of children miss at least one scheduled vaccine, with a 10% target.

The case gives task durations and dependencies below. Durations are treated as working days for the exercise. No calendar start date, holidays, staffing availability, procurement lead time, or resource capacity is supplied, so the 51-day result is an elapsed working-day plan under those assumptions, not a committed calendar delivery date.

## 2. Work breakdown and dependency network

| ID | Work package | Duration (days) | Immediate predecessor(s) | Scope/result |
|---|---|---:|---|---|
| A | Requirements | 6 | — | Requirements baseline and approval inputs |
| B | Schedule rules | 4 | A | Authority-reviewed schedule rules |
| C | Registration module | 10 | A | Child registration capability |
| D | Schedule generator | 6 | B, C | Due-date generation using approved rules and registered records |
| E | SMS reminders | 5 | D | Reminder workflow and gateway integration/test |
| F | Supervisor dashboard | 7 | D | Due/overdue supervisor view |
| G | Testing | 7 | E, F | Integrated verification and defect correction |
| H | Pilot at 5 health posts | 15 | G | Controlled five-post pilot and evaluation |

```mermaid
flowchart LR
  A[Requirements<br/>6d] --> B[Schedule rules<br/>4d]
  A --> C[Registration module<br/>10d]
  B --> D[Schedule generator<br/>6d]
  C --> D
  D --> E[SMS reminders<br/>5d]
  D --> F[Supervisor dashboard<br/>7d]
  E --> G[Testing<br/>7d]
  F --> G
  G --> H[Pilot at 5 posts<br/>15d]
```

## 3. CPM forward/backward pass

Convention: day 0 is project start; early/late finish equals start plus duration. Float = LS − ES = LF − EF. The backward pass starts at day 51, the earliest finish of the final task.

| ID | Dur. | Pred. | ES | EF | LS | LF | Total float | Critical? |
|---|---:|---|---:|---:|---:|---:|---:|---|
| A Requirements | 6 | — | 0 | 6 | 0 | 6 | 0 | Yes |
| B Schedule rules | 4 | A | 6 | 10 | 12 | 16 | 6 | No |
| C Registration module | 10 | A | 6 | 16 | 6 | 16 | 0 | Yes |
| D Schedule generator | 6 | B, C | 16 | 22 | 16 | 22 | 0 | Yes |
| E SMS reminders | 5 | D | 22 | 27 | 24 | 29 | 2 | No |
| F Supervisor dashboard | 7 | D | 22 | 29 | 22 | 29 | 0 | Yes |
| G Testing | 7 | E, F | 29 | 36 | 29 | 36 | 0 | Yes |
| H Pilot at 5 posts | 15 | G | 36 | 51 | 36 | 51 | 0 | Yes |

**Critical path:** A → C → D → F → G → H = 6 + 10 + 6 + 7 + 7 + 15 = **51 working days**.  
**Noncritical float:** B has 6 days; E has 2 days. All other activities have zero total float.  
The `D` start is controlled by `C` (registration completes on day 16, later than `B` on day 10). The `G` start is controlled by `F` (dashboard completes day 29, later than `E` on day 27).

## 4. Gantt view (relative working days)

```mermaid
gantt
  title ImmuniRemind case plan (relative working days, day 0 start)
  dateFormat  YYYY-MM-DD
  axisFormat  %d
  section Definition and build
  Requirements (A, 6d)          :crit, a, 2026-01-01, 6d
  Schedule rules (B, 4d)         :b, after a, 4d
  Registration module (C, 10d)  :crit, c, after a, 10d
  Schedule generator (D, 6d)    :crit, d, after b c, 6d
  SMS reminders (E, 5d)         :e, after d, 5d
  Supervisor dashboard (F, 7d)  :crit, f, after d, 7d
  section Verification and pilot
  Testing (G, 7d)               :crit, g, after f, 7d
  Pilot at 5 posts (H, 15d)     :crit, h, after g, 15d
```

The Gantt uses an arbitrary anchor date solely to render relative durations; it is not a real approved calendar. Its dependency sequencing follows the critical path. `B` and `E` have schedule slack and may run in parallel with other work where their dependencies allow.

## 5. Milestones and gates

| Milestone | Planned point | Entry/exit evidence |
|---|---:|---|
| M1 Requirements baseline | End day 6 | FR/NFR baseline reviewed; health authority decisions/dependencies listed; no unapproved clinical schedule assumed |
| M2 Rules and registration ready | End day 16 | Schedule rules approved by authority; registration module passes agreed functional and authorization checks |
| M3 Schedule generation ready | End day 22 | Expected-result fixtures for approved rule version match generated plans; exceptions route to staff review |
| M4 Reminders and dashboard ready | End day 29 | Reminder eligibility and status handling reviewed; dashboard scope and due/overdue totals reconcile |
| M5 Test exit / pilot go-no-go | End day 36 | Critical defects closed or formally accepted; security, data quality, operational readiness, training, gateway, and rollback checks approved |
| M6 Five-post pilot complete | End day 51 | Pilot measures collected and reconciled; authority records continue/adjust/stop decision and owner |

### Pilot milestones (inside task H, days 36–51)

| Milestone | Day | Entry/exit evidence |
|---|---:|---|
| P1 Go-live at 5 posts | 36 | Entry: M5 test exit approved. Exit: training completed for the workers at all 5 posts and the system live at those posts |
| P2 Registration complete, first reminder batch sent | 41 | Entry: go-live at P1. Exit: all 4,500 children registered (5 × 900) and the first reminder batch sent. Registration effort: 4,500 × 4 min = 18,000 min = 300 h = 37.5 staff-days at 8 h/day; with 10 workers (2 per post), 37.5 ÷ 10 = 3.75 days, so registration completes by pilot day 4 (project day 40). See `06_Estimation_Sheet.md`, rows 16, 18 and 19 |
| P3 Mid-pilot metric review | 46 | Entry: reminders running for 5 days. Exit: interim values of the section 8 metrics reviewed against thresholds; any early corrective action logged |
| P4 Pilot close and scale decision | 51 | Entry: all pilot metrics collected and reconciled. Exit: scale decision (Go, Conditional go or No-go) recorded with its approver |

Pilot authorization is a decision gate; the schedule does not imply automatic deployment to all 40 posts. Expansion requires a separately approved scale decision and operational plan.

## 6. Resource allocation and estimate assumptions

The case gives task duration but no staffing, cost, or named owners. The table below proposes role allocation only; it does not invent staff identities or claim resource availability. Roles may be combined in a student exercise, subject to independent review for clinical rules and security.

| Work | Accountable role (proposed) | Supporting roles (proposed) | Planning note |
|---|---|---|---|
| Requirements | Project lead / business analyst | Health authority representative, health-post worker, supervisor | Authority participation is a dependency, not confirmed availability. |
| Schedule rules | Health authority rule owner | Business analyst, QA | Rule owner approval required before generator acceptance. |
| Registration | Application engineer | UX, security reviewer, health-post representative | Access-scope and data-quality cases included. |
| Schedule generator | Application engineer | Rule owner, QA | Expected dates come from approved test fixtures. |
| SMS reminders | Integration engineer | Privacy/security reviewer, gateway contact, QA | Gateway access, cost, sender identity, and delivery receipts remain assumptions. |
| Supervisor dashboard | Application engineer / analyst | Supervisor, QA | Filter scope and metric definitions must be approved. |
| Testing | QA lead | Engineers, security reviewer, user representatives | Independent test review recommended for authorization and rule calculations. |
| Pilot | Pilot coordinator | Five-post workers, supervisor, support, analyst | Site selection, training, support rota, baseline, and consent operations require approval. |

Estimation assumptions: tasks are sequential within each work package; dependencies are finish-to-start; scope is stable; approvals arrive without additional wait time; resources are available when scheduled; no rework or external procurement delay is included. These assumptions make 51 days an optimistic CPM baseline. A schedule reserve must be set after resource availability and authority approval timing are known; no reserve is invented here.

## 7. Monitoring and control

At each weekly review (proposed cadence), the project lead records planned/actual start and finish, remaining duration, dependency status, open defects by severity, approvals due, risks, and estimate-to-complete. Recalculate the critical path whenever actual duration or dependency changes. Report both task-level variance and effect on the day-51 pilot milestone.

| Trigger (proposed control threshold) | Corrective response | Approval / record |
|---|---|---|
| Any critical-path task forecasts >1 working day late | Re-estimate affected chain; identify scope, resource, and dependency options; protect testing and pilot-readiness exit criteria | Project lead proposes recovery; sponsor/authority approves baseline change or resources; log decision and revised CPM |
| Any noncritical float is consumed by 50% or more | Review remaining float weekly and identify whether a dependency can be cleared; escalate before it moves onto critical path | Project lead updates risk/action log |
| Schedule rule approval not available by day 10 | Stop due-date acceptance work; request decision/owner/date; replan D and downstream dates rather than use guessed rules | Health authority owns rule decision; sponsor accepts schedule impact |
| Any unresolved critical/high defect at test exit | Block pilot go decision until fixed and retested, or document formal risk acceptance where legally and clinically permitted | QA lead recommends; authority/sponsor decides; signed test-exit record |
| Data completeness or authorization pilot gate fails | Pause affected post/workflow, investigate and correct, revalidate synthetic and pilot records before resuming | Pilot coordinator and privacy/security owner approve restart |
| Missed-dose metric worsens or exceeds agreed guardrail | Check denominators, data quality, workflow, and access first; adjust operations/reminders only with approved policy; consider pause | Authority reviews evidence and records continue/adjust/stop decision |

Thresholds above are proposed project controls, not supplied targets. Exact severity definitions, stop guardrails, baseline and measurement window are approval items before pilot.

### 7.1 Actual vs plan

*Simulated for the case study: the actual durations below are invented to demonstrate variance analysis; they are not observed project data.*

| Task | Planned dur | Actual dur | Variance (days) | Planned ES–EF | Actual ES–EF | On critical path? |
|---|---:|---:|---:|---|---|---|
| A Requirements | 6 | 6 | 0 | 0–6 | 0–6 | Yes |
| B Schedule rules | 4 | 5 | +1 | 6–10 | 6–11 | No (float 6 → 5) |
| C Registration | 10 | 12 | +2 | 6–16 | 6–18 | Yes |
| D Schedule generator | 6 | 6 | 0 | 16–22 | 18–24 | Yes |
| E SMS reminders | 5 | 5 | 0 | 22–27 | 24–29 | No |
| F Supervisor dashboard | 7 | 8 | +1 | 22–29 | 24–32 | Yes |
| G Testing | 7 | 7 | 0 | 29–36 | 32–39 | Yes |
| H Pilot | 15 | 15 | 0 | 36–51 | 39–54 | Yes |

### 7.2 Variance calculation

*Simulated for the case study.*

1. Task variance = actual − planned duration: B = 5 − 4 = +1; C = 12 − 10 = +2; F = 8 − 7 = +1; all other tasks 0.
2. B is not critical. Its overrun is absorbed by its float, which falls from 6 to 5 days (B now finishes at day 11 against a late finish of 16). It does not move the finish date.
3. C and F are on the critical path, so their overruns propagate: 2 + 1 = 3 days.
4. Forecast finish = 51 + 3 = 54 days against a plan of 51.
5. Schedule variance at completion, SV = 54 − 51 = **+3 days**, or 3 ÷ 51 = **+5.9%** late.
6. Status is taken at day 32, when F finishes. The work completed by then was planned to finish at day 29, so SV(t) = 29 − 32 = **−3 days**.
7. SPI(t) = 29 ÷ 32 = **0.906**.

SPI(t) < 1 means the project reached this amount of planned work later than planned: here, only about 0.91 days of planned progress are earned per elapsed day, so without action the schedule slips.

### 7.3 Corrective action

*Simulated for the case study.* The approved option has two actions:

1. Crash Testing (G) from 7 to 5 days by adding one QA tester from the department IT cell. This recovers 2 days.
2. Overlap 1 day of pilot training with the last day of Testing. This recovers 1 day.

Recovery = 2 + 1 = 3 days, so the forecast finish returns from 54 to 54 − 3 = **51 days**.

| Role | Responsibility |
|---|---|
| Proposed by: Project manager | Analyses the variance, prepares the recovery option and submits the change request |
| Confirmed by: QA lead | Checks that the Testing exit criteria are unchanged after crashing and overlap |
| Approved by: Project Sponsor (Municipal Health Officer), via the change control board | Approves the baseline change and the added resource; the decision and revised CPM are logged |

### 7.4 Pilot metrics: plan vs actual

*Simulated for the case study: pilot results are invented to demonstrate the scale rule.*

| Metric | Plan | Actual | Variance |
|---|---|---|---|
| Registration completeness | ≥ 98% | 97.2% | −0.8 pp |
| SMS delivery-confirmed within 24 h | ≥ 95% | 93.1% | −1.9 pp |
| Doses due in the pilot given within 7 days of the due date | ≥ 80% | 84.0% | +4.0 pp |
| Overdue doses among doses due during the pilot | ≤ 16% | 14.2% | −1.8 pp (better) |
| Worker usability task success | ≥ 4 of 5 | 4 of 5 | 0 |
| Privacy incidents | 0 | 0 | 0 |

## 8. Pilot measures and scale decision

Before pilot, agree a baseline period, cohort inclusion, dose denominator, exclusion handling, post-level reporting, and privacy controls. The case gives a child-level baseline (23% of children miss at least one scheduled vaccine) and a 10% one-year goal; it does not specify measurement definitions. The pilot results in 7.4 are simulated.

| Measure | Definition to approve | Use |
|---|---|---|
| Missed-dose proportion | Children/doses meeting authority-defined missed-dose outcome divided by eligible cohort/dose denominator for a named period | Compare consistently with case baseline/target; do not claim causal effect from before/after alone |
| On-time completion | Due doses recorded within the authority-defined window divided by doses due in the same cohort and period | Assess timeliness and workflow |
| Reminder process rate | Eligible reminders queued, gateway accepted, and delivery-confirmed, each divided by eligible reminder attempts | Separate system processing from confirmed delivery |
| Record completeness | Records with required approved fields populated divided by records reviewed | Detect onboarding and data quality gaps |
| Due/overdue list reconciliation | Number of list rows reconciled against source records for selected sample | Verify dashboard correctness |
| Access-control failures | Count and severity of unauthorized attempts detected in test/pilot monitoring | Verify scope enforcement and response |
| Operational burden | Staff time or workload measure using an agreed collection method | Check feasibility at five pilot posts |

**Scale rule** (decision at P4, day 51):

- **Go** if every threshold is met.
- **Conditional go** if at most 2 thresholds are missed, each by 3 pp or less, and each has a corrective action.
- **No-go** if there is any privacy incident or more than 2 misses.

*Simulated for the case study.* **Outcome: Conditional go.** Two thresholds are missed: registration completeness by 0.8 pp and SMS delivery by 1.9 pp, both within 3 pp; the other four are met and there are no privacy incidents. The corrective actions are phone-number verification at registration and a secondary gateway route. The decision is approved by the Municipal Health Officer and the steering committee. Expansion to all 40 posts still needs its own operational plan.

## 9. Closure and lessons learned

See `07_Closure_and_Lessons_Learned.md` for the closure note and lessons-learned page.
