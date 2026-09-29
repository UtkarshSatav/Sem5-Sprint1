# Personalized Academic Support — Case 52

Project title: **PASS**.

This project implements the assigned end-to-end machine-learning case study: problem definition, documented dataset, EDA, preprocessing, a baseline and two model approaches, evaluation and error analysis, a working Streamlit interface, and viva/report material.

## Deliverables map

| Required item | Evidence |
| --- | --- |
| Problem definition | `docs/PROJECT_REPORT.md`, section 1 |
| Dataset and documentation | `data/student-por.csv`, `data/student.txt`, `data/README.md` |
| EDA and visualisations | `src/eda.py`, `outputs/eda_summary.md` (including a data-quality section), five SVG charts including `outputs/priority_by_school.svg` and `outputs/priority_by_failures.svg` |
| Preprocessing | `src/modeling.py` and report section 4 |
| Two modelling approaches | Logistic regression and depth-limited decision tree, plus majority baseline, and an early-warning experiment without G1/G2 |
| Evaluation and error analysis | `outputs/model_comparison.json` (train-vs-validation gaps and the `tree_depth_curve` overfitting check), `outputs/holdout_error_analysis.csv` |
| Streamlit application | `app.py`, which loads the trained model from `outputs/logistic_model.joblib` |
| Final report and presentation | `docs/PROJECT_REPORT.md`, `docs/VIVA_AND_PRESENTATION.md`, `docs/Case52_Presentation.pptx` |
| Source code | `src/` and `app.py` |

## Run

```sh
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
python3 src/eda.py
python3 src/train_evaluate.py
streamlit run app.py
```

The app opens locally at the URL printed by Streamlit, normally `http://localhost:8501`.

## What the system does

The system uses information available after the second grading period to estimate whether a fictional student situation should receive a voluntary human review. `support_priority = 1` when the final Portuguese-course grade `G3` is below 10/20. The output is an offer of support choices, never an automatic diagnosis, sanction, or denial of services.

The app uses logistic regression as its explainable demonstration model and generates transparent support ideas from the submitted situation. Ordinary resources remain available regardless of the score.

## Reproducibility

- Source data: UCI Student Performance, Portuguese course, 649 rows.
- Citation: Cortez, P. (2008), DOI `10.24432/C5TG7T`.
- License: CC BY 4.0.
- Split: stratified 75/25 holdout, random state 52.
- Validation: five-fold stratified cross-validation on the training partition only.
- Leakage control: every imputer, encoder, and scaler is inside the model pipeline.

## Scope boundary

This is an educational prototype using historical secondary-school data from two Portuguese schools. It is not validated for this university, current cohorts, or operational student decisions. It does not establish causation or intervention effectiveness.

