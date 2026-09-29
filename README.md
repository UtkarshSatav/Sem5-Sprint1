# Sem 5 · Sprint 1 — Case Study Submission

This repository holds my Semester 5, Sprint 1 case-study submission. It contains three assigned case studies across three subjects. Each one is a self-contained project with its own documentation.

| | |
|---|---|
| **Student** | Utkarsh Satav |
| **Sprint** | Sprint 1, Semester 5 |
| **Assigned cases** | #10 CampusShuttle · #52 Personalized Academic Support · #144 ImmuniRemind |

---

## Where to find the submission

The `main` branch introduces the repository. **The submission itself is in a separate branch:**

| Branch | Contents |
|---|---|
| [`sprint1-submission`](../../tree/sprint1-submission) | **The final submission.** All three case studies with their complete deliverables, tests and documentation. |
| `main` | This overview. |

To get the submission locally:

```sh
git clone https://github.com/UtkarshSatav/Sem5-Sprint1.git
cd Sem5-Sprint1
git checkout sprint1-submission
```

---

## Case studies

### Case #10 — CampusShuttle
**Subject:** Cross Platform Application Development
**Folder:** `01_CampusShuttle_Case-10/`

**What it does:** students can view campus shuttle timings between stops, reserve a seat on a trip, and watch the seat count update live as other students book.

- **Technology:** Flutter (Dart), Material 3, Provider for shared state, `shared_preferences` for storing bookings on the device.
- **Screens:** Route Timetable, Trip Detail and My Bookings, built from `ListView`, `Card` and `Icon` widgets. Each shuttle line has its own colour.
- **Core logic:** a single Provider `ChangeNotifier` owns every seat count. Reserving a seat decreases availability and cancelling restores it, on every screen at the same moment. Live bookings by other students are simulated.
- **Deliverables:** a Figma design with a guided four-step prototype, the working web app, an automated test suite, and app-flow and data-model documentation.
- **Live demo:** https://campusshuttle-1be8c.web.app

### Case #52 — Personalized Academic Support
**Subject:** Machine Learning Fundamentals
**Folder:** `02_Personalized-Academic-Support_Case-52/`

**What it does:** identifies student situations that may benefit from an optional academic-support conversation, then suggests clear support options.

- **Formulation:** binary classification after the second grading period, followed by a transparent rule layer that maps each situation to support options.
- **Dataset:** UCI Student Performance, Portuguese course (Cortez, 2008), 649 records, licensed CC BY 4.0. It is fully documented, including data-quality issues.
- **Pipeline:**
  - **EDA:** findings recorded with each chart, including a per-school bias analysis.
  - **Preprocessing:** leakage-safe; imputation, scaling and one-hot encoding are fitted on the training folds only.
  - **Validation:** a stratified 75/25 holdout plus 5-fold cross-validation.
- **Models compared:** a majority baseline, logistic regression, a depth-limited decision tree, and an early-warning variant without prior grades.
- **Evaluation:** balanced accuracy, precision, recall, F1 and ROC AUC, a confusion matrix, an overfitting check, and error analysis.
- **Deliverables:** a Streamlit application, the final report, a presentation deck, viva material, source code and tests.

### Case #144 — ImmuniRemind
**Subject:** Software Engineering & Project Management
**Folder:** `03_ImmuniRemind_Case-144/`

**What it does:** a municipal system for 40 urban health posts. It registers children, generates immunisation schedules, sends SMS reminders to parents, and gives supervisors lists of due and overdue doses. The goal is to cut the share of children who miss at least one dose from 23% to 10% within a year.

- **Requirements:** an IEEE 830-style SRS with 12 functional and 8 measurable non-functional requirements, MoSCoW prioritisation, and a record of how requirements were elicited.
- **Design:** a consistent UML package (use-case, class, sequence, activity and state diagrams) with a justification of cohesion and loose coupling.
- **Planning:** dependency network, CPM forward and backward pass, a 51-day critical path, float, Gantt chart, pilot milestones and resource allocation.
- **Estimation:** 36,000 children × 12 doses = **432,000 doses tracked**, with every assumption and sensitivity shown.
- **Quality:** a test plan with boundary value analysis by child age in weeks, equivalence classes, a dose-due and catch-up decision table, a test log, DRE and defect density.
- **Control and risk:** plan vs actual variance, corrective action and who approves it, a probability × impact risk register, RMMM plans, and a closure note with lessons learned.

---

## Repository structure (`sprint1-submission` branch)

```text
01_CampusShuttle_Case-10/                  Flutter app, tests, Figma design, docs
02_Personalized-Academic-Support_Case-52/  ML pipeline, Streamlit app, data, outputs, report, slides
03_ImmuniRemind_Case-144/                  SRS, UML, project plan, estimation, test plan, risk, closure
```

Each case folder has its own `README.md`, with detailed run instructions and a map of its deliverables.

## Running the projects

**CampusShuttle** (requires the Flutter SDK):

```sh
cd 01_CampusShuttle_Case-10
flutter pub get
flutter run -d chrome
flutter test
```

**Personalized Academic Support** (requires Python 3):

```sh
cd 02_Personalized-Academic-Support_Case-52
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/streamlit run app.py
```

**ImmuniRemind** is a documentation package. Open the Markdown files in order, `01` to `07`. The diagrams are written in Mermaid and render directly on GitHub.
