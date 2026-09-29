# EarlyNudge: Mid-Semester Academic Support Triage from Grade and Engagement Signals (proposed title)

Case 52 — Personalized Academic Support · Final Report

## 1. Problem definition

A university wants a data-driven way to identify student situations that may benefit from timely academic support. This project frames the task as **binary classification** after the second grading period:

- `1 — support priority`: invite a human review and offer voluntary support choices.
- `0 — routine`: keep ordinary support visible and available.

The prototype never diagnoses a student, allocates punishment, removes access, or makes a final decision. Students and advisors are the main stakeholders. The model output supports a conversation; transparent rules generate the resource suggestions shown in the interface.

### Why classification plus transparent rules

The brief allows prediction, classification, clustering, recommendation or a similar output. Recommending support *types* would need labelled outcomes of past interventions (which support helped which student), and this dataset has none. The ML task is therefore binary classification of support priority, which is the step the labelled data can genuinely support. A transparent rule layer then maps the submitted situation (low G2, low study time, failures, absences, travel time, no internet, no school support) to the support options shown in the app. This keeps every suggestion explainable and avoids inventing labels.

## 2. Dataset and provenance

The project uses the Portuguese-course portion of the UCI **Student Performance** dataset: 649 records, 33 source columns, no documented missing values. It was collected from school reports and questionnaires at two Portuguese secondary schools. Citation: Cortez, P. (2008), DOI `10.24432/C5TG7T`, CC BY 4.0.

The target is `G3 < 10`, representing a final grade below the usual passing point. It is renamed `support_priority` so the interface communicates the intended supportive action. `G3` is excluded from all model inputs.

Selected inputs are G1 and G2 earlier-period grades, weekly study-time band, previous failures, absences, travel-time band, current school support, family support, home internet, and intention to pursue higher education. Demographic, parent, health, relationship, and alcohol fields are excluded to reduce unnecessary and intrusive profiling.

### Data-quality issues recorded

- 15 rows have G3 = 0 (8 of them with G2 > 0). They look like students who left or missed the final assessment, so they are noisy positive labels. They are kept, because excluding them would hide real disengagement, and flagged as a limitation.
- Absences are right-skewed (skew 2.02); 8 rows exceed 20 and the maximum is 32.
- G1 and G2 are strongly collinear (r = 0.865) and G2 correlates 0.919 with G3, so G1/G2 coefficients should not be read independently.
- `studytime` and `traveltime` are ordinal bands (1–4), not hours; scaling them as numbers assumes equal spacing.
- `student.txt` documents failures as "n if 1<=n<3, else 4", but the maximum observed value is 3, so 3 is treated as "3 or more".
- G1 and G2 are quoted strings in the raw CSV but parse cleanly as integers.

## 3. Exploratory data analysis

The selected dataset has 549 routine rows and 100 priority rows, so only 15.4% of records are positive. There are no missing selected values or exact duplicate rows. The generated EDA report and charts are in `outputs/eda_summary.md`.

Two subgroup findings shape the interpretation (charts `priority_by_school.svg` and `priority_by_failures.svg`):

- **School:** the priority rate is 7.6% at GP (n = 423) and 30.1% at MS (n = 226).
- **Previous failures:** the priority rate is 9.3% with 0 failures (n = 549), 45.7% with 1 (n = 70), 50.0% with 2 (n = 16) and 64.3% with 3 (n = 14).
- **Correlations with G3:** G1 0.826, G2 0.919, failures −0.393, studytime 0.250.

The imbalance explains why the majority baseline achieves 84.7% accuracy while finding zero priority cases. G1 and G2 are strongly related to G3, as UCI explicitly documents. The system is therefore presented as a mid-year review demonstration, not an enrolment-time predictor.

## 4. Preprocessing and validation design

The data is split into a stratified 75% training partition and a 25% untouched holdout using random state 52. Five-fold stratified cross-validation runs only within the training partition.

Numeric columns use median imputation and standard scaling. Categorical yes/no fields use most-frequent imputation and one-hot encoding with unknown-category handling. These steps are inside a scikit-learn `Pipeline`, so each transform is fitted only on its training fold and cannot learn from holdout rows.

Although the supplied data is complete, explicit imputers document how missing inputs would be handled. A real deployment would first decide whether an absent value should be imputed, requested again, or treated as “unknown.”

## 5. Model development

Four experiments are compared:

1. **Majority baseline:** establishes the result of always predicting the common class and demonstrates why accuracy is misleading.
2. **Logistic regression:** uses class weighting, provides an explainable probability, and is the app’s primary demonstration model.
3. **Decision tree:** captures non-linear thresholds. Depth 4 and a minimum leaf size of 10 constrain complexity and reduce overfitting.
4. **Logistic regression without G1/G2 (early warning):** the same pipeline using only study time, failures, absences, travel time and the four yes/no fields. It shows how much the model depends on earlier grades, and what could be flagged before any grade exists.

## 6. Evaluation results

| Model | Accuracy | Balanced accuracy | Precision | Recall | F1 | ROC AUC |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Majority baseline | 0.8466 | 0.5 | 0.0 | 0.0 | 0.0 | 0.5 |
| Logistic regression | 0.8957 | 0.8729 | 0.6176 | 0.84 | 0.7119 | 0.9391 |
| Decision tree | 0.865 | 0.8384 | 0.5405 | 0.8 | 0.6452 | 0.8923 |
| Logistic regression — no G1/G2 (early warning) | 0.7853 | 0.6439 | 0.3438 | 0.44 | 0.386 | 0.6907 |

Logistic regression is selected for the app because it has the strongest holdout balanced accuracy, recall, F1, and ROC AUC of the meaningful models that use the grades. On the 163-row holdout it produces 125 true negatives, 13 false positives, 4 false negatives, and 21 true positives.

Its mean five-fold validation-fold scores (training partition) are 0.902 balanced accuracy, 0.636 precision, 0.907 recall, 0.742 F1, and 0.977 ROC AUC. Cross-validation and holdout results are both reported to avoid presenting a single split without context.

The early-warning model (no G1/G2) drops to holdout balanced accuracy 0.6439, recall 0.44 and ROC AUC 0.6907 (confusion matrix: 117 TN, 21 FP, 14 FN, 11 TP), with five-fold CV balanced accuracy 0.7526. It still beats the baseline, so non-grade signals carry some information, but it misses more than half of the priority cases. Most of the accuracy of the main model comes from G1/G2. Earlier grades are what make the tool useful, and without them it is weak.

### 6.1 Overfitting check

Overfitting is detected by comparing training scores with validation scores: a large gap means the model has memorised the training folds. Training balanced accuracy is measured inside each cross-validation fold on the 75% training partition.

| Model | CV train BA | CV validation BA | Gap |
| --- | ---: | ---: | ---: |
| Majority baseline | 0.5 | 0.5 | 0.0 |
| Logistic regression | 0.9423 | 0.9023 | 0.0399 |
| Decision tree | 0.9321 | 0.8975 | 0.0346 |
| Logistic regression — no G1/G2 (early warning) | 0.7812 | 0.7526 | 0.0287 |

Decision-tree depth curve (min leaf size 10, five-fold CV on the training partition):

| Depth | Train BA | Validation BA |
| ---: | ---: | ---: |
| 1 | 0.9168 | 0.9168 |
| 2 | 0.9177 | 0.9156 |
| 3 | 0.9271 | 0.8992 |
| 4 | 0.9321 | 0.8975 |
| 5 | 0.9321 | 0.8975 |
| 6 | 0.9321 | 0.8975 |
| 7 | 0.9321 | 0.8975 |
| 8 | 0.9321 | 0.8975 |
| 9 | 0.9321 | 0.8975 |
| 10 | 0.9321 | 0.8975 |

Interpretation: depth 4 was fixed in advance; the curve shows it is not the best on validation (depths 1–2 validate best: 0.9168 and 0.9156, against 0.8975 at depth 4) but it is not materially overfitting either (gap 0.0346, about 0.035). The gap widens from 0.0000 at depth 1 to 0.0346 at depth 4. Beyond depth 4 the curve is flat because a minimum leaf size of 10 stops further splits. Validation balanced accuracy is in fact highest for the shallowest trees (0.9168 at depth 1), so the extra depth buys no generalisation. The unconstrained-tree risk is therefore controlled, and the shallow-tree result is a reminder that G2 alone carries most of the signal. All gaps are small (at most 0.0399), so no model shows serious overfitting.

## 7. Error analysis

A **false negative** misses a situation that later ended below 10/20; four occur in the logistic holdout results. This may delay a useful offer. A **false positive** invites a review for a student who later passes; thirteen occur. This can create unnecessary contact, workload, or stigma.

The row-level holdout evidence is saved in `outputs/holdout_error_analysis.csv`. Before any real pilot, students and advisors must decide the relative cost of these errors and choose a threshold. Calibration, subgroup error analysis, confidence intervals, and temporal validation are still required.

### What the false negatives have in common

- All 4 missed cases had a passing G2 (≥ 10; mean 10.5) and 0 previous failures.
- 3 of the 4 were in study time band 1.
- The model relies on G2. The true positives average G2 7.38 (from `logistic_error_profile`), so students who decline *after* a passing mid-year grade are the blind spot.
- For contrast, the 13 false positives average G2 9.15: they may be struggling students who then recovered.

## 8. Streamlit application

The Streamlit app presents the source, target balance, model comparison, and an input form using the ten documented features. It returns an estimated review score plus situation-based resource ideas such as tutoring, study planning, catch-up material, flexible access, or campus internet access. The recommendations are explicit rules and are not generated from hidden model logic. The app loads the saved, evaluated logistic-regression pipeline (`outputs/logistic_model.joblib`, trained on the 75% partition) rather than retraining it.

## 9. Limitations, bias, and safeguards

- The records are historical observations from two Portuguese secondary schools and are not representative of this university.
- **School bias risk:** priority rates are GP 7.6% vs MS 30.1%. `school` is excluded from the inputs, but proxies (for example failures, support and study-time patterns) may carry it. The next step is per-school error rates, which have not been computed.
- The 15 rows with G3 = 0 are noisy labels and may reflect dropout rather than attainment.
- Strong G1/G2 correlation makes the model useful only after those grades exist.
- Prediction does not prove that any suggested intervention will help.
- Academic records can reflect illness, disability, work, caregiving, transport, and unequal access. A score may reproduce these disadvantages.
- No fairness, calibration, causal-impact, privacy, security, drift, or user study has been performed.

A future pilot requires institutional approval, student participation, data minimisation, access control, retention rules, an appeal/correction route, human review, subgroup monitoring, and stop criteria. Support must remain available to all students regardless of score.

## 10. Conclusion

The project demonstrates a complete, reproducible ML workflow with a documented public dataset, EDA, leakage-resistant preprocessing, a baseline, two meaningful models, an early-warning ablation, an overfitting check, cross-validation, holdout evaluation, row-level error analysis, and a working Streamlit interface. The evidence supports the classroom pipeline only; local validation and governance are prerequisites for real use.

