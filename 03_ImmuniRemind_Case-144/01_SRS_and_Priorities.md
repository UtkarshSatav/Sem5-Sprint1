# Software Requirements Specification — ImmuniRemind

**Case:** 144 · **Style:** IEEE-830-style student SRS · **Version:** 1.0  
**System boundary:** registration, dose scheduling, reminders, and supervisor due/overdue lists for a municipal health department operating 40 urban health posts.

## 1. Purpose and scope

The proposed system is intended to help health-post staff register children, maintain dose records, generate due dates from authorized schedule rules, send SMS reminders, and let supervisors review due and overdue work. The case states a population of 36,000 children under five, about 12 scheduled doses per child, a current missed-dose level of approximately 23%, and a target of 10% within one year.

This document specifies requirements and constraints for the case study. It does not prescribe clinical dose intervals or claim that reminders alone will achieve the target. A municipal health authority must supply and approve the schedule rules, message text, consent/legal basis, retention policy, and operating procedures before implementation.

## 2. Stakeholders and user classes

| Stakeholder / user | Need in this case | Access boundary |
|---|---|---|
| Parent/guardian | Receive a reminder and contact the health post | No system account is specified by the case; messages contain only approved minimum information |
| Health-post worker | Register/update a child and record dose administration | Operates records for an assigned post |
| Supervisor | Review due/overdue lists and pilot measures | Views authorized posts and aggregate measures |
| Municipal health authority | Approve schedule rules, policy, targets, and rollout decision | Owns policy and approves cross-post access |
| System administrator | Manage accounts and operational configuration | Administrative access is controlled and audited |

Role enforcement and post-level authorization are security requirements; a screen or menu restriction alone is insufficient.

## 3. Operating context and constraints

- The case describes 40 urban health posts and paper-register-based work today.
- Planning volume is approximately 432,000 dose records (36,000 × approximately 12); actual growth, retention, and peak concurrency are not supplied.
- SMS gateway, handset coverage, connectivity, hosting, legal jurisdiction, consent rules, and exact clinical schedule are unspecified and require stakeholder decisions.
- Dates and due statuses must be computed using an approved, versioned schedule rule set. The system must not infer or invent clinical intervals.
- Personally identifying child and guardian data require role-based access, secure transport/storage, auditability, and approved retention/deletion rules.

## 4. Functional requirements

Priority uses MoSCoW: **M** Must, **S** Should, **C** Could, **W** Won't for this case scope. Each requirement has a testable outcome.

| ID | Requirement | Priority | Acceptance check |
|---|---|---|---|
| FR-01 | The system shall authenticate staff and assign a role and authorized health-post scope to each account. | M | Unauthenticated requests are rejected; a worker cannot access another post’s child record; supervisor access follows an approved scope. |
| FR-02 | The system shall create a child record with the required identity, date-of-birth, guardian contact, health-post, and consent/policy fields defined by the authority. | M | A valid record is saved once; missing mandatory fields are reported without saving an incomplete record. Exact fields are to be approved before build. |
| FR-03 | The system shall allow an authorized worker to find and view a child record within that worker’s permitted post scope. | M | Search returns only authorized matches and does not expose records from another post. |
| FR-04 | The system shall allow authorized staff to correct child/guardian registration data and retain an audit entry for each change. | M | A changed value records actor, time, record, and changed field; unauthorized edits are denied. |
| FR-05 | The system shall maintain dose events against a child, including dose identifier, administration date, and recording staff. | M | A valid administration event is saved once and appears in the child’s dose history; duplicate submissions do not create duplicate events. |
| FR-06 | The system shall store an authority-approved, versioned schedule-rule set with effective dates. | M | Only an authorized approver can publish a rule version; previous versions remain identifiable for audit. |
| FR-07 | The system shall generate planned dose due dates from the child’s approved rule version and relevant record data. | M | For a supplied test fixture and rule version, generated dates match the approved expected results; missing or incompatible inputs produce an explicit exception. |
| FR-08 | The system shall classify each incomplete dose as not yet due, due, overdue, or requiring staff review according to the approved rule policy and an explicit as-of date. | M | Boundary fixtures at before/on/after due date produce the documented states; an unknown rule or inconsistent history is not silently classified. |
| FR-09 | The system shall prepare SMS reminders for eligible upcoming/due doses using authority-approved text and the configured consent/contact rules. | M | Only eligible records create a queued message; message preview and eligibility reason are available to authorized staff. Timing window is a policy configuration to be approved. |
| FR-10 | The system shall record reminder attempt status, timestamp, destination reference, and gateway response where available. | S | A simulated success, failure, and retry response are distinguishable in the message history; full message contents are not exposed in general reports. |
| FR-11 | The system shall present supervisors with filterable due and overdue lists for their authorized post scope. | M | Filters for post, date, and status return matching authorized records; totals reconcile to the listed records for the same filter. |
| FR-12 | The system shall provide pilot monitoring summaries for agreed coverage, missed-dose, reminder, and data-quality measures by period and post. | S | A report displays metric definition, numerator, denominator, period, and post scope; it does not imply causal impact without evaluation evidence. |

## 5. Measurable non-functional requirements

These are **proposed acceptance targets** for the student design, not case-supplied service commitments. Stakeholders must ratify them after deployment context, connectivity, and privacy requirements are known.

| ID | Quality attribute | Proposed measurable requirement |
|---|---|---|
| NFR-01 | Performance | With a representative test dataset of 432,000 dose records and 40 posts, 95% of authorized list/search requests shall complete within 2 seconds and 99% within 5 seconds, excluding client network latency. |
| NFR-02 | Availability | During the agreed pilot operating window, monthly service availability shall be at least 99.5%, excluding announced maintenance; availability is measured by scheduled synthetic checks. |
| NFR-03 | Access control | 100% of automated authorization tests for unauthenticated access, wrong role, and wrong post scope shall deny access to protected records and actions. |
| NFR-04 | Confidentiality in transit | 100% of browser-to-service and service-to-gateway connections carrying personal data shall use TLS; cleartext endpoints shall be rejected in release configuration. |
| NFR-05 | Auditability | 100% of create, edit, dose-record, schedule-publication, reminder, and authorization-sensitive actions shall record actor, timestamp, action, and target identifier; audit records shall be append-only to ordinary application roles. |
| NFR-06 | Data integrity | In a repeatable test of 10,000 dose-event create/update submissions, there shall be zero duplicate dose events from retried submissions and zero lost acknowledged writes. |
| NFR-07 | Recovery | A documented backup restore exercise shall restore the latest successful backup within a proposed 4-hour RTO and lose no more than 24 hours of acknowledged updates (proposed RPO). |
| NFR-08 | Usability/accessibility | In a usability session with at least 5 representative health-post workers (sample proposed), at least 4 shall complete registration, record an administered dose, and locate an overdue record without facilitator intervention; core screens shall pass keyboard-only navigation review. |

## 6. Data and interface requirements

- Data concepts: Child, GuardianContact, HealthPost, DoseEvent, ScheduleRuleVersion, Reminder, StaffAccount, AuditEntry, and PilotMetric. These are logical concepts, not a mandated database schema.
- External interfaces: an SMS gateway and any identity provider are dependencies, but the provider/API is not specified in the case.
- Every date calculation uses an explicit timezone and as-of date. The authority must define timezone, local-day boundaries, date correction procedure, and rule-version transition behavior.
- Reports must expose definitions and denominators so users can interpret rates correctly. Aggregate outputs should avoid unnecessary personal identifiers.

## 7. Assumptions, dependencies, and unresolved decisions

1. The health authority supplies medically approved dose identifiers, intervals, catch-up rules, eligibility, consent, message wording, and retention requirements.
2. The stated population and doses are approximate planning figures; births, migration, missed records, and additional doses can change actual volume.
3. An SMS gateway and network access can be procured and approved; neither is guaranteed by the case.
4. Pilot baseline and outcome measurement methods must be agreed before comparing the 23% baseline with the 10% one-year target.
5. Stakeholders must define identity matching and duplicate child resolution. This SRS does not invent government identifiers or collect unnecessary sensitive data.

## 8. MoSCoW scope summary

- **Must:** FR-01 through FR-09 and FR-11; identity and scope control, records, dose events, approved schedules, due status, eligible reminder preparation, supervisor lists.
- **Should:** FR-10 and FR-12; delivery outcome history and explicit pilot summaries.
- **Could:** No additional functional feature is committed in this case package. Could items can be considered only if time permits and remain within these stated functions.
- **Won't for this case scope:** patient/guardian mobile app, online appointment booking, clinical decision support beyond the authority’s configured schedule, analytics or AI prediction, payments, external health-record integration, and live production deployment.

## 9. Acceptance approach

Acceptance is based on approved fixtures and policy rules, requirement-level test cases in the design/test specification, authorization tests for every protected function, a representative-volume performance test, and a pilot with a pre-agreed baseline and metric definitions. No clinical rules or pilot results are supplied here, so those acceptance inputs remain stakeholder dependencies.
