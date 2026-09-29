# Software Requirements Specification: ImmuniRemind

**Case:** 144 · **Style:** IEEE 830-style student SRS · **Version:** 1.1 · **Date:** 2026-09-29  
**System boundary:** registration, dose scheduling, SMS reminders, and supervisor due/overdue lists for a municipal health department operating 40 urban health posts.

## Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-09-28 | Initial SRS |
| 1.1 | 2026-09-29 | Added elicitation appendix, revised NFRs (reminder reliability and privacy), added the 12-dose fixture wording to FR-07 to FR-09, added the Could backlog, corrected the 23% wording |

---

## 1 Introduction

### 1.1 Purpose

This SRS specifies the requirements of ImmuniRemind for the developers, testers, health-post staff, supervisors and the Municipal Health Officer who will approve it. It is the baseline for design, the test plan and the pilot.

### 1.2 Scope

ImmuniRemind helps health-post staff register children, record doses, generate due dates from a versioned schedule rule set, send SMS reminders to guardians, and give supervisors due and overdue lists. The case states a population of 36,000 children under five across 40 posts, 12 scheduled doses per child (432,000 dose records), and a problem: about 23% of children miss at least one scheduled dose (child-level rate). The target is to reduce this to 10% within one year.

The system does not prescribe clinical dose intervals and does not claim that reminders alone will reach the target. The 12-dose schedule used here is a teaching fixture aligned to India UIP timepoints, not clinical guidance.

### 1.3 Definitions and acronyms

| Term | Meaning |
|---|---|
| ANM | Auxiliary Nurse Midwife, the health worker who runs a post's immunisation sessions |
| UIP | Universal Immunisation Programme (India) |
| MoSCoW | Prioritisation classes: Must, Should, Could, Won't |
| NFR | Non-functional requirement |
| DLR | Delivery receipt returned by the SMS gateway |
| RTO | Recovery time objective: the longest acceptable time to restore service |
| RPO | Recovery point objective: the longest acceptable span of lost updates |
| PII | Personally identifiable information (child and guardian data) |
| As-of date | The explicit date against which age and dose status are computed |

### 1.4 References

1. Case 144 brief, ImmuniRemind (the source of the population, dose and target figures).
2. IEEE Std 830-1998, *Recommended Practice for Software Requirements Specifications*.
3. India UIP schedule, the source of the 12-dose fixture (used as teaching data, not clinical guidance).
4. `05_Test_Plan_and_Evidence.md` in this folder, section 2 (the dose fixture).

### 1.5 Overview

Section 2 describes the product, its users, constraints and assumptions. Section 3 lists the specific requirements: interfaces, 12 functional requirements, 8 non-functional requirements and the MoSCoW summary. Appendix A records how the requirements were elicited.

---

## 2 Overall description

### 2.1 Product perspective

ImmuniRemind replaces the paper immunisation registers used at the 40 posts today. It is a web application used by staff, backed by one central database. It depends on one external component, an SMS gateway, to send reminders and return delivery receipts (DLR). It has no parent-facing app; parents interact only through SMS and a visit to the post.

### 2.2 Product functions (summary)

- Authenticate staff and restrict each account to a role and health-post scope (FR-01).
- Register, find and correct child records (FR-02 to FR-04).
- Record doses and maintain versioned schedule rules (FR-05, FR-06).
- Generate the 12 planned doses, classify their status and send reminders (FR-07 to FR-09).
- Log reminder attempts (FR-10).
- Give supervisors due and overdue lists and pilot summaries (FR-11, FR-12).

### 2.3 User characteristics

| Stakeholder / user | Need in this case | Access boundary |
|---|---|---|
| Parent/guardian | Receive a reminder and contact the health post | No system account; messages contain only the minimum information in NFR-04 |
| Health-post worker | Register/update a child and record dose administration | Operates records for an assigned post |
| Supervisor | Review due/overdue lists and pilot measures | Views authorised posts and aggregate measures |
| Municipal Health Officer (authority) | Approve schedule rules, policy, targets and the rollout decision | Owns policy and approves cross-post access |
| System administrator | Manage accounts and operational configuration | Administrative access is controlled and audited |

Role enforcement and post-level authorisation are security requirements; a screen or menu restriction alone is not enough.

**Personas.** Three representative users are described in Appendix A.4 (Simulated for the case study).

### 2.4 Constraints

- 40 urban health posts; paper registers are the current process.
- Planning volume is 432,000 dose records (36,000 children × 12 doses), about 900 children per post.
- Dates and statuses are computed from a versioned schedule rule set. The system does not invent clinical intervals.
- Child and guardian data need role-based access, encrypted transport and storage, an audit trail and a retention limit (NFR-03 to NFR-05).
- Reminders go through an external SMS gateway; delivery depends on handset coverage.
- Every date calculation uses an explicit timezone (India Standard Time) and an explicit as-of date.

### 2.5 Assumptions and dependencies

This is the single place for items that need an external decision or are taken as given for the case.

1. The Municipal Health Officer approves the schedule rule version, SMS wording, consent basis and retention policy before go-live. Until then the fixture in `05_Test_Plan_and_Evidence.md` section 2 is used.
2. The population and dose counts are planning figures; births, migration and added doses change actual volume.
3. An SMS gateway can be procured, and a secondary gateway route can be added if needed.
4. The 23% baseline and the 10% target are both child-level rates, measured with the same definition before and after.
5. Retention ends 12 months after the child turns 5 (assumed).
6. Duplicate children are resolved by matching name, date of birth and guardian phone at registration. No government ID is collected.

---

## 3 Specific requirements

### 3.1 External interfaces

- **User interface:** a browser-based web application for workers, supervisors and administrators. Core screens are registration, child record and dose entry, and due/overdue list.
- **SMS gateway interface:** ImmuniRemind sends a message with an idempotency key and receives a delivery receipt (DLR). All traffic uses TLS 1.2 or higher.
- **Data concepts:** Child, GuardianContact, HealthPost, DoseEvent, ScheduleRuleVersion, Reminder, StaffAccount, AuditEntry, PilotMetric. These are logical concepts, not a mandated schema.
- **Reports:** every rate shows its definition, numerator and denominator. Aggregate outputs avoid personal identifiers.

### 3.2 Functional requirements

Priority uses MoSCoW: **M** Must, **S** Should. Each requirement has a testable outcome.

**Dose status rule** (used by FR-07 and FR-08). Age `a` is in completed weeks, `floor(days_since_birth / 7)`. For a dose with minimum age `m` (which is also its due age) and maximum age `M`, when the dose is not yet administered:

- `a < 0`: Invalid (a future date of birth); the record is rejected at registration
- `a < m`: NotYetDue
- `m ≤ a ≤ m+4` and `a ≤ M`: Due
- `m+4 < a ≤ M`: Overdue (catch-up allowed)
- `a > M`: Missed (no longer eligible; refer to the medical officer)
- `a > 260`: out of programme scope (the child is over 5 and is not registered)

A dose with a series predecessor is due no earlier than 4 weeks after the predecessor was given.

| ID | Requirement | Priority | Acceptance check |
|---|---|---|---|
| FR-01 | The system shall authenticate staff and assign a role and authorized health-post scope to each account. | M | Unauthenticated requests are rejected; a worker cannot access another post’s child record; supervisor access follows the approved scope. |
| FR-02 | The system shall create a child record with the required identity, date-of-birth, guardian contact, health-post, and consent/policy fields defined by the authority. | M | A valid record is saved once; missing mandatory fields are reported without saving an incomplete record. |
| FR-03 | The system shall allow an authorized worker to find and view a child record within that worker’s permitted post scope. | M | Search returns only authorized matches and does not expose records from another post. |
| FR-04 | The system shall allow authorized staff to correct child/guardian registration data and retain an audit entry for each change. | M | A changed value records actor, time, record, and changed field; unauthorized edits are denied. |
| FR-05 | The system shall maintain dose events against a child, including dose identifier, administration date, and recording staff. | M | A valid administration event is saved once and appears in the child’s dose history; duplicate submissions do not create duplicate events. |
| FR-06 | The system shall store an authority-approved, versioned schedule-rule set with effective dates. | M | Only an authorized approver can publish a rule version; previous versions remain identifiable for audit. |
| FR-07 | The system shall generate the 12 planned doses (D01 to D12) of a child from the date of birth using the approved rule version. The fixture is in the test plan, `05_Test_Plan_and_Evidence.md` section 2. | M | For the fixture and rule version, the 12 generated due ages and dates match the expected results; a missing or incompatible input produces an explicit exception. |
| FR-08 | The system shall classify each dose as NotYetDue, Due, Overdue, Missed or NeedsReview using the dose status rule in section 3.2 and an explicit as-of date. NeedsReview is used when the rule version is unknown or the dose history is inconsistent. | M | Boundary fixtures at `m-1`, `m`, `m+4`, `m+5`, `M` and `M+1` weeks produce NotYetDue, Due, Due, Overdue, Overdue and Missed; an inconsistent history gives NeedsReview and is never silently classified (values below 0 are dropped and m+4 is clamped to M, as in 05 §4; for example OPV-0 gives Due, Due, Missed at 0, 2 and 3 weeks). |
| FR-09 | The system shall send an advance SMS 3 days before the due date at 09:00 local time, a due-day SMS at 09:00, and, when a dose becomes Overdue, a catch-up SMS repeated after 14 days (at most 2 catch-ups). Reminders are sent only where consent is recorded and the guardian contact is valid. | M | For a dose due on day D, messages are queued for D-3 and D at 09:00; an Overdue dose gets catch-ups at overdue day 0 and day 14 and no third; a child without consent gets none; a message preview and the eligibility reason are visible to authorized staff. |
| FR-10 | The system shall record reminder attempt status, timestamp, destination reference, and gateway response where available. | S | A simulated success, failure, and retry response are distinguishable in the message history; full message contents are not exposed in general reports. |
| FR-11 | The system shall present supervisors with filterable due and overdue lists for their authorized post scope. | M | Filters for post, date, and status return matching authorized records; totals reconcile to the listed records for the same filter. |
| FR-12 | The system shall provide pilot monitoring summaries for agreed coverage, children-missing-a-dose, reminder, and data-quality measures by period and post. | S | A report displays metric definition, numerator, denominator, period, and post scope; it does not imply causal impact without evaluation evidence. |

### 3.3 Non-functional requirements

Each NFR has a measurable target and a way to measure it. The targets are the acceptance criteria for the pilot.

| ID | Name | Requirement (measurable target) | Measured by |
|---|---|---|---|
| NFR-01 | Reminder reliability: dispatch | At least 99% of eligible reminders are handed to the gateway within 60 minutes of their scheduled 09:00 send time. A failed hand-off is retried up to 3 times within 2 hours. There are 0 duplicate SMS per reminder in a 10,000-message test (an idempotency key is sent with every message). | Queue logs and the load test |
| NFR-02 | Reminder reliability: delivery | At least 95% of dispatched reminders are delivery-confirmed (DLR) within 24 hours. Every undelivered reminder appears on the worker's follow-up list by 09:00 the next working day. | Gateway DLR reports |
| NFR-03 | Privacy: access control | 100% of automated authorization tests for unauthenticated access, wrong role, and wrong post scope deny access to protected records and actions. | Automated authorization test suite (pass rate) |
| NFR-04 | Privacy: data protection | (a) TLS 1.2 or higher for 100% of connections carrying personal data; (b) AES-256 encryption at rest for child and guardian PII; (c) SMS content limited to the child's first name, dose name, due date and health post, with no ID numbers or health details; (d) PII purged within 30 days of the retention end, which is 12 months after the child turns 5 (assumed). | Configuration review and a template audit |
| NFR-05 | Auditability | 100% of create, edit, dose-record, schedule-publication, reminder, and authorization-sensitive actions record actor, timestamp, action, and target identifier; audit records are append-only to ordinary application roles. | Audit-log inspection in the system test |
| NFR-06 | Performance | With a representative test dataset of 432,000 dose records and 40 posts, 95% of authorized list/search requests complete within 2 seconds and 99% within 5 seconds, excluding client network latency. | Load test at 432,000 records |
| NFR-07 | Availability & recovery | Monthly availability of at least 99.5%, excluding announced maintenance. RTO 4 hours and RPO 24 hours, proven by a restore exercise before the pilot. | Scheduled synthetic checks and the restore exercise report |
| NFR-08 | Usability | (a) At least 4 of 5 representative health workers complete registration, dose recording and finding an overdue child without help; (b) median registration time of 4 minutes or less per child (this matches the estimation assumption); (c) SMS text is readable at a Class-5 reading level, checked by 3 parents in the workshop. | Usability session, timed registration trials, and parent read-back check |

### 3.4 MoSCoW summary

- **Must:** FR-01 to FR-09 and FR-11. These cover access control, records, dose events, schedule rules, the 12-dose plan, status classification, reminders and supervisor lists.
- **Should:** FR-10 and FR-12 (reminder history and pilot summaries).
- **Could (backlog, outside the 12 FRs):**
  - C-01 multilingual SMS templates (Marathi / Hindi / English)
  - C-02 a voice-call (IVR) fallback when an SMS is undelivered
  - C-03 bulk CSV import of existing paper-register entries
- **Won't for this case scope:** parent/guardian mobile app, online appointment booking, clinical decision support beyond the configured schedule, analytics or AI prediction, payments, external health-record integration, and live production deployment.

**How priorities were set:** Priorities are set by dependency on the 23%→10% goal (a function is Must if the goal cannot be met or measured without it) and are to be confirmed by dot-voting at the planned workshop (Appendix A.2).

---

## Appendix A: Requirements elicitation

> **Simulated for the case study: workshop not yet held; findings derived from the case brief.** The document list, workshop plan, findings and personas below are illustrative. They show the elicitation method, not real field data.

### A.1 Document analysis

| Document | What it told us | Requirements |
|---|---|---|
| Paper immunisation registers | Records are per post, per child, kept by hand; doses and dates are written by the worker | FR-02, FR-05, NFR-08 |
| Mother & Child Protection (MCP) card | The family holds its own dose record; the child's date of birth and given doses are the starting data | FR-05, FR-07 |
| India UIP schedule | Dose names, due ages and catch-up limits that define the 12-dose fixture | FR-06, FR-07, FR-08 |
| Monthly immunisation report format | Supervisors need counts of due and overdue children per post each month | FR-11, FR-12 |
| SMS consent form | A guardian must agree to SMS and give a phone number; messages must stay minimal | FR-09, NFR-04 |

### A.2 Stakeholder workshop plan

One 2-hour session.

**Participants:** 4 parents, 6 health workers from 3 posts, 2 supervisors, 1 medical officer, a facilitator and a scribe.

| # | Agenda item | Time |
|---|---|---|
| 1 | Current process walk-through | 20 min |
| 2 | Pain points | 30 min |
| 3 | Reminder timing and content preferences | 20 min |
| 4 | Supervisor reporting needs | 20 min |
| 5 | MoSCoW dot-voting | 20 min |
| 6 | Wrap-up | 10 min |

### A.3 Findings to requirements

| Finding | Stakeholder | Requirement ID |
|---|---|---|
| Parents forget dates | Parent | FR-09, NFR-01 |
| Workers re-count registers every month | Health worker | FR-11 |
| SMS must not reveal health details | Parent, medical officer | NFR-04 |
| A worker cannot tell which children are overdue without paging through the register | Health worker | FR-08, FR-11, NFR-08 |
| Registration must be quick or the queue at the post grows | Health worker | FR-02, NFR-08 |
| A reminder that arrives late in the day is missed; morning is preferred | Parent | FR-09, NFR-01 |
| Undelivered messages go unnoticed | Supervisor | FR-10, NFR-02 |
| Workers must see only their own post's children | Supervisor, medical officer | FR-01, FR-03, NFR-03 |

### A.4 Personas

**Sunita, parent (basic SMS-only phone).** Mother of a 5-month-old, keeps the MCP card at home, reads simple Hindi and Marathi, has no smartphone. She needs a short SMS with the child's name, the dose and the date. She acts on the message the same week if it arrives in the morning. Drives FR-09, NFR-02, NFR-04, NFR-08(c) and Could item C-01.

**Meena, health worker responsible for 900 children.** ANM at one post, registers children at the counter and gives doses at weekly sessions. She has about 4 minutes per registration and today re-counts the register every month. She needs fast registration, an overdue list she can act on, and a follow-up list for undelivered SMS. Drives FR-02, FR-05, FR-08, FR-11, NFR-02, NFR-08.

**Rakesh, supervisor covering 8 posts.** Reviews due and overdue children across his posts and reports monthly to the Municipal Health Officer. He needs filters by post and status, totals that reconcile, and pilot summaries with clear denominators. Drives FR-11, FR-12, NFR-03, NFR-06.
