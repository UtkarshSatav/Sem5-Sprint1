# ImmuniRemind — Case 144 (SE/PM)

This folder contains the Software Engineering and Project Management deliverables for the assigned ImmuniRemind case. It is a project-analysis and documentation package, not a deployed health application.

## Deliverables

- [SRS and priorities](01_SRS_and_Priorities.md): IEEE-830-style structure, 12 functional requirements, 8 measurable non-functional requirements, and MoSCoW priorities.
- [Design and test specification](02_Design_and_Test_Specification.md): consistent use-case, class, sequence, activity, and state diagrams; cohesion/coupling rationale; equivalence classes, boundary-value tests, and due/catch-up decision table.
- [Schedule and controls](03_Schedule_and_Controls.md): dependency network, forward/backward pass, critical path, float, Gantt, milestones, resource allocation, estimation assumptions, monitoring, pilot measures, variance response, and closure lessons.
- [Risk and quality register](04_Risk_and_Quality.md): probability-impact register, exposure ranking, top-three RMMM actions, DRE and defect-density formulas with a clearly hypothetical worked example.

## Case facts used

The case brief supplies 40 urban health posts, 36,000 children under age five, approximately 12 scheduled doses per child, a current missed-dose figure of about 23%, a target of 10% within one year, and task durations/dependencies documented in the schedule file. Derived volume: 36,000 × 12 ≈ 432,000 dose records. Any additional value used for sizing, service targets, sample data, or project dates is identified as an assumption or proposed acceptance target, not as a fact supplied by the case.

## Scope boundary

The deliverables cover requirements, design models, planning, test design, project controls, risk, and pilot evaluation for the case. No real child data, clinical schedule, live SMS integration, production application, credentials, or deployment configuration is included.

## Validation status

Arithmetic and requirement/diagram consistency were reviewed against the case facts. Diagram source is Mermaid text and can be rendered by a Mermaid-compatible Markdown viewer. Any DRE/defect-density figures are illustrative only; no implementation or actual test execution is claimed. See each document for assumptions and evidence limits.
