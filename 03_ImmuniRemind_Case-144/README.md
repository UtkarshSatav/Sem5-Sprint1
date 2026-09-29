# ImmuniRemind — Case 144 (SE/PM)

This folder contains the Software Engineering and Project Management deliverables for the assigned ImmuniRemind case. It is a project-analysis and documentation package, not a deployed health application.

## Deliverables

- [01 SRS](01_SRS_and_Priorities.md): IEEE-830-style Software Requirements Specification, with 12 functional requirements, 8 measurable non-functional requirements, and MoSCoW priorities.
- [02 UML package](02_Design_and_Test_Specification.md): the design specification, with use-case, class, sequence, activity, and state diagrams and a cohesion/coupling rationale.
- [03 Project plan](03_Schedule_and_Controls.md): dependency network, forward/backward pass, critical path, float, Gantt, milestones, resources, monitoring, and variance response.
- [04 Risk register](04_Risk_and_Quality.md): probability-impact matrix, exposure ranking, and RMMM plans for the top three risks.
- [05 Test plan and evidence](05_Test_Plan_and_Evidence.md): IEEE 829-lite test plan, equivalence-class, boundary-value and decision-table designs, and test evidence.
- [06 Estimation sheet](06_Estimation_Sheet.md): dose, SMS, coverage and pilot-effort estimates from the case facts.
- [07 Closure note and lessons learned](07_Closure_and_Lessons_Learned.md): closure note and lessons learned.

Deliverable map: SRS = 01; UML package = 02; Project plan = 03; Estimation sheet = 06; Test plan and evidence = 05; Risk register (with the P-I matrix, exposure ranking and RMMM) = 04; Closure note and lessons learned = 07.

## Case facts used

The case brief supplies 40 urban health posts, 36,000 children under age five, approximately 12 scheduled doses per child, about 23% of children miss at least one scheduled vaccine (a child-level rate), a target of 10% within one year, and task durations/dependencies documented in the schedule file. Derived volume: 36,000 × 12 ≈ 432,000 dose records. Any additional value used for sizing, service targets, sample data, or project dates is identified as an assumption or proposed acceptance target, not as a fact supplied by the case.

## Scope boundary

The deliverables cover requirements, design models, planning, test design, project controls, risk, and pilot evaluation for the case. No real child data, clinical schedule, live SMS integration, production application, credentials, or deployment configuration is included.

## Validation status

Arithmetic and requirement/diagram consistency were reviewed against the case facts. Diagram source is Mermaid text and can be rendered by a Mermaid-compatible Markdown viewer. The actual task durations, defect counts, workshop findings and pilot results are simulated for the case study; no real implementation, test execution or pilot was run. See each document for assumptions and evidence limits.
