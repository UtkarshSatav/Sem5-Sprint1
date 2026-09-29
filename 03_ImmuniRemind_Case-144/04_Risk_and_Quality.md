# Risk and Quality Register — ImmuniRemind

## 1. Scoring method

Probability (P) and impact (I) use a proposed 1–5 ordinal scale: 1 = rare/very low, 2 = unlikely/low, 3 = possible/moderate, 4 = likely/high, 5 = almost certain/very high. Exposure = P × I (range 1–25). Scores prioritize review; they are not statistical probabilities. Impact considers child safety/continuity, privacy, service correctness, schedule, and public trust. The scores below are planning judgments to validate with stakeholders, not measured incident rates.

## 2. Risk register

| ID | Risk / cause | P | I | Exposure | Response | Owner (proposed) | Trigger / monitor |
|---|---|---:|---:|---:|---|---|---|
| R1 | Incorrect, incomplete, or unapproved dose/catch-up rules produce wrong due dates or messages | 3 | 5 | 15 | Avoid unsafe inference; require authority approval, versioning, expected-result fixtures, independent review, and staff-review path for ambiguous records | Health authority rule owner | Approval missing, fixture mismatch, or rule ambiguity |
| R2 | Unauthorized access or disclosure of child/guardian data through weak role/post checks, reports, or logs | 3 | 5 | 15 | Restrict by role and post at service layer; minimize fields; audit; test cross-post access; review logs and retention | Security/privacy owner | Any unauthorized read/write, scope-test failure, or sensitive data in logs |
| R3 | SMS gateway outage, delay, or incorrect delivery leads to reminders not reaching guardians or sent to wrong destination | 4 | 4 | 16 | Validate contacts; use approved text; queue/idempotency, retry caps, failure visibility, delivery status distinction, escalation to staff workflow | Integration owner | Error/unknown delivery rate above approved threshold or misdelivery report |
| R4 | Poor migration/registration data quality creates duplicates, missing dates, or incorrect child-dose associations | 4 | 4 | 16 | Define field/identity rules; validate at entry; reconcile source registers; quarantine ambiguous matches; sample and track completeness | Data lead / post supervisor | Duplicate/invalid rate above pilot gate; unresolved identity ambiguity |
| R5 | Staff adoption or training gaps lead to missed updates and continued parallel work in paper registers | 3 | 4 | 12 | Co-design workflow with workers, train before pilot, offer support, observe workload and record reconciliation | Pilot coordinator | Low completion, repeated workarounds, support requests, incomplete records |
| R6 | Schedule-rule approval, gateway procurement, or security/privacy decisions arrive late and extend the 51-day plan | 3 | 4 | 12 | Track decision owners/due dates; escalate before dependency dates; recalculate CPM; do not substitute guessed rules | Project lead | Decision overdue or critical-path forecast slip |
| R7 | Performance or availability degrades at approximately 432,000 dose records or intermittent post connectivity | 2 | 4 | 8 | Test representative data volume; measure response and availability; define offline/continuity procedure only if approved and designed | Technical lead | Proposed NFR threshold missed or repeated timeouts |
| R8 | Pilot results are misinterpreted because baseline, denominator, period, or eligibility differs from case target | 3 | 4 | 12 | Agree metric dictionary and cohort before pilot; reconcile denominators; report limits; avoid unsupported causal claims | Evaluation lead | Metric changes or unreconciled baseline/period |
| R9 | Backup/restore does not recover records within approved recovery needs | 2 | 5 | 10 | Select backup policy with authority, restrict backup access, and exercise restore before pilot | Operations owner | Failed restore test or backup age beyond approved limit |
| R10 | Reminder retries create duplicate messages or an unbounded send burst | 3 | 3 | 9 | Idempotency keys, bounded retries, rate controls, queue monitoring, test gateway failure/timeout cases | Integration owner | Duplicate logical job or retry threshold reached |

Highest initial exposure is R3 and R4 (16), then R1 and R2 (15). Scores must be revisited after mitigations and pilot evidence; no residual score is asserted before those controls are implemented and tested.

## 3. RMMM plans for the top three

### R3 — SMS delivery failure or misdelivery (exposure 16)

- **Mitigation:** normalize and validate destination according to approved numbering rules; check consent/policy; preview only approved templates; use an idempotent queue with bounded retries; track gateway accepted, failed, unknown, and delivery-confirmed states separately.
- **Monitoring:** review delivery status and error rate by post and period; monitor queue age, retry counts, and complaints. Set numeric thresholds with the gateway owner before pilot.
- **Management/contingency:** stop automatic sends if misdelivery is suspected; quarantine affected jobs, alert the responsible supervisor, correct contact/policy data, and use an approved manual follow-up process. Resume only after reconciliation and authorization.
- **Owner:** integration owner with privacy/security review.

### R4 — Registration and migration data quality (exposure 16)

- **Mitigation:** approve minimum required fields and matching process; validate date/contact formats; prevent duplicate submissions; reconcile pilot entries against source registers using an approved sample and procedure; route ambiguous identities to human review.
- **Monitoring:** track missing/invalid fields, suspected duplicates, unmatched records, and correction audit events by post. Agree go/no-go thresholds before pilot.
- **Management/contingency:** pause affected imports or registration flow when records cannot be safely matched; correct under supervisor oversight, retain audit trail, repeat reconciliation, and restart only after gate approval.
- **Owner:** data lead and health-post supervisor.

### R1 — Incorrect schedule or catch-up rules (exposure 15)

- **Mitigation:** obtain signed health-authority rule approval and effective dates; keep rule versions immutable and attributable; test dates against independently reviewed expected results including boundary and exception cases; block sending where rule evaluation is ambiguous.
- **Monitoring:** review rule-version use, exceptions, fixture results, and staff corrections; audit any rule publication and subsequent recalculation.
- **Management/contingency:** suspend schedule calculations/reminders for affected rule version, notify the authority and posts, identify impacted records from audit data, correct only under approved instructions, rerun fixtures, and obtain written release approval.
- **Owner:** authority-appointed rule owner; QA verifies evidence.

## 4. Test quality and defect measures

### Defect Removal Efficiency (DRE)

`DRE = defects found before release / (defects found before release + defects found after release) × 100%`.

Count defects for a defined release and observation window, count unique defects once, and classify discovery phase consistently. DRE is meaningful only if the post-release observation window and channels are defined; a short window can understate escaped defects.

### Defect density

`Defect density = confirmed defects / delivered software size (KLOC)`.

Define the size measure (for example, non-generated source lines) and defect inclusion rules before comparing components or releases. Since this case package contains no implemented code or observed defect data, actual density cannot be calculated.

### Clearly hypothetical worked example

The following numbers are invented only to demonstrate the formula and are **not ImmuniRemind test results**:

- Assumed pre-release confirmed defects: 38.
- Assumed post-release confirmed defects during a specified example window: 2.
- Example DRE = 38 / (38 + 2) × 100% = **95%**.
- Assumed delivered size: 20 KLOC; assumed total confirmed defects: 40.
- Example defect density = 40 / 20 = **2 defects/KLOC**.

The team should replace these example values with actual, traceable test/production evidence after implementation. DRE and density should be interpreted alongside severity, escaped-defect impact, test coverage, and observation duration; a high DRE alone does not prove safety.

## 5. Quality gates

| Gate | Evidence required | Decision owner (proposed) |
|---|---|---|
| Requirements baseline | Approved rules owner, consent/privacy/retention decisions, FR/NFR acceptance criteria, metric definitions | Sponsor and health authority |
| Schedule generator verification | Versioned rule fixture, expected/actual date comparison, BVA and exception-path results | Rule owner and QA lead |
| Security/privacy verification | Role and post-scope tests, audit/log review, TLS configuration review, remediation record | Security/privacy owner |
| Integration verification | Success/failure/timeout/retry and duplicate-job evidence from test gateway or approved simulator | QA and integration owner |
| Test exit / pilot go-no-go | No open unaccepted critical/high defect, data reconciliation, training/support/rollback readiness, metric baseline and pilot guardrails | Sponsor, authority, QA, pilot coordinator |
| Pilot close / scale decision | Reconciled five-post measures, deviations, residual risks, operating support and documented decision | Health authority and sponsor |

No gate is marked passed in this planning package. Evidence must be produced during implementation and testing.
