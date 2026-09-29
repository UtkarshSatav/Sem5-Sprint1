# Closure Note and Lessons Learned — ImmuniRemind

*Simulated for the case study — based on the simulated actuals in 03 §7 and the defect log in 05.*

## 1. Closure note

### Project summary

ImmuniRemind is a vaccination reminder system for 36,000 children under five across 40 health posts, tracking 36,000 × 12 = 432,000 doses (see `06_Estimation_Sheet.md`). The project delivered the registration, schedule generation, SMS reminder and supervisor dashboard modules, and ran a 15-day pilot at 5 posts covering 4,500 children.

### Planned vs actual finish

| Point | Finish (working days) |
|---|---:|
| Baseline plan | 51 |
| Forecast at day 32 (B +1, C +2, F +1; C and F critical) | 54 (+3 days, +5.9%) |
| After corrective action (Testing crashed 7 → 5, 1 day of training overlapped) | 51 |

The corrective action was proposed by the project manager, confirmed by the QA lead and approved by the Project Sponsor (Municipal Health Officer) via the change control board.

### Scope delivered

FR-01 to FR-12 were delivered. The C-items were not started.

### Quality summary

48 defects were found in total: 45 before release and 3 after release (in the first 15 pilot days). DRE = 45 ÷ (45 + 3) = 93.75%. The 3 post-release defects were 0 critical, 1 high (SMS delivery-receipt timeout not retried) and 2 medium.

### Pilot result

**Conditional go.** Registration completeness (97.2% vs 98%) and SMS delivery-confirmed within 24 h (93.1% vs 95%) missed their thresholds, each by less than 3 pp. Corrective actions are phone-number verification at registration and a secondary gateway route. Approved by the Municipal Health Officer and the steering committee.

### Open risks

- R3 (exposure 16)
- R4 (exposure 16)

Both carry into the 40-post rollout with their RMMM plans (see the risk register).

### Handover items

- Source code, configuration and the schedule-rule fixture (12 doses)
- Test suite and defect log
- Gateway configuration, including the planned secondary route
- Operations and support runbook and worker training material
- Pilot metric results and the estimation sheet
- Removal of pilot personal data under the approved retention policy

### Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Project manager | | | |
| QA lead | | | |
| Municipal Health Officer | | | |

## 2. Lessons learned

*Simulated for the case study.*

| # | What happened | Root cause | Lesson | Action for the 40-post rollout | Owner |
|---:|---|---|---|---|---|
| 1 | Registration ran 12 days against 10 planned (+2) | Identity-duplicate rules were defined late | Data-matching rules are requirements and must be baselined before build | Agree duplicate-matching rules at the requirements gate | Project manager |
| 2 | Dashboard ran 8 days against 7 planned (+1) | Report filters changed after the workshop | Late filter changes hit a critical-path task | Freeze report filters at the workshop sign-off; changes go through change control | Business analyst |
| 3 | SMS delivery-confirmed within 24 h was 93.1% against a 95% threshold | Invalid phone numbers were captured at registration | Delivery quality depends on input data quality | Add phone-number verification at registration; add a secondary gateway route | Integration engineer |
| 4 | A post-release defect: SMS delivery-receipt (DLR) timeout not retried | The retry path was not covered by integration tests | Failure and retry paths need explicit integration cases | Add DLR-timeout and retry cases to the integration suite | QA lead |
| 5 | Registration completeness was 97.2% against a 98% threshold | Optional fields were skipped by workers | Optional fields are skipped under time pressure | Make key fields mandatory or prompt at save; review completeness at mid-pilot | Pilot coordinator |
| 6 | What went well: B's 1-day overrun was absorbed by its float, and the gateway fix shipped without touching the schedule generator | Float was tracked on non-critical tasks; the event-queue design decouples the gateway from the schedule generator | Track float and keep modules loosely coupled | Keep float reporting in weekly reviews; keep the event-queue design | Project manager |
