# Personalized Academic Support — Final Report

## 1. Problem definition

A university wants a data-driven way to identify student situations that may benefit from timely academic support. This project frames the task as **binary classification** after the second grading period:

- `1 — support priority`: invite a human review and offer voluntary support choices.
- `0 — routine`: keep ordinary support visible and available.

The prototype never diagnoses a student, allocates punishment, removes access, or makes a final decision. Students and advisors are the main stakeholders. The model output supports a conversation; transparent rules generate the resource suggestions shown in the interface.

## 2. Dataset and provenance

The project uses the Portuguese-course portion of the UCI **Student Performance** dataset: 649 records, 33 source columns, no documented missing values. It was collected from school reports and questionnaires at two Portuguese secondary schools. Citation: Cortez, P. (2008), DOI `10.24432/C5TG7T`, CC BY 4.0.

The target is `G3 < 10`, representing a final grade below the usual passing point. It is renamed `support_priority` so the interface communicates the intended supportive action. `G3` is excluded from all model inputs.

Selected inputs are G1 and G2 earlier-period grades, weekly study-time band, previous failures, absences, travel-time band, current school support, family support, home internet, and intention to pursue higher education. Demographic, parent, health, relationship, and alcohol fields are excluded to reduce unnecessary and intrusive profiling.

## 3. Exploratory data analysis

The selected dataset has 549 routine rows and 100 priority rows, so only 15.4% of records are positive. There are no missing selected values or exact duplicate rows. The generated EDA report and charts are in `outputs/eda_summary.md`.

The imbalance explains why the majority baseline achieves 84.7% accuracy while finding zero priority cases. G1 and G2 are strongly related to G3, as UCI explicitly documents. The system is therefore presented as a mid-year review demonstration, not an enrolment-time predictor.

## 4. Preprocessing and validation design

The data is split into a stratified 75% training partition and a 25% untouched holdout using random state 52. Five-fold stratified cross-validation runs only within the training partition.

Numeric columns use median imputation and standard scaling. Categorical yes/no fields use most-frequent imputation and one-hot encoding with unknown-category handling. These steps are inside a scikit-learn `Pipeline`, so each transform is fitted only on its training fold and cannot learn from holdout rows.

Although the supplied data is complete, explicit imputers document how missing inputs would be handled. A real deployment would first decide whether an absent value should be imputed, requested again, or treated as “unknown.”

## 5. Model development

Three methods are compared:

1. **Majority baseline:** establishes the result of always predicting the common class and demonstrates why accuracy is misleading.
2. **Logistic regression:** uses class weighting, provides an explainable probability, and is the app’s primary demonstration model.
3. **Decision tree:** captures non-linear thresholds. Depth 4 and a minimum leaf size of 10 constrain complexity and reduce overfitting.

## 6. Evaluation results

| Model | Accuracy | Balanced accuracy | Precision | Recall | F1 | ROC AUC |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Majority baseline | 0.847 | 0.500 | 0.000 | 0.000 | 0.000 | 0.500 |
| Logistic regression | 0.896 | 0.873 | 0.618 | 0.840 | 0.712 | 0.939 |
| Decision tree | 0.865 | 0.838 | 0.541 | 0.800 | 0.645 | 0.892 |

Logistic regression is selected for the app because it has the strongest holdout balanced accuracy, recall, F1, and ROC AUC of the two meaningful models. On the 163-row holdout it produces 125 true negatives, 13 false positives, 4 false negatives, and 21 true positives.

Its mean five-fold training-partition scores are 0.902 balanced accuracy, 0.636 precision, 0.907 recall, 0.742 F1, and 0.977 ROC AUC. Cross-validation and holdout results are both reported to avoid presenting a single split without context.

## 7. Error analysis

A **false negative** misses a situation that later ended below 10/20; four occur in the logistic holdout results. This may delay a useful offer. A **false positive** invites a review for a student who later passes; thirteen occur. This can create unnecessary contact, workload, or stigma.

The row-level holdout evidence is saved in `outputs/holdout_error_analysis.csv`. Before any real pilot, students and advisors must decide the relative cost of these errors and choose a threshold. Calibration, subgroup error analysis, confidence intervals, and temporal validation are still required.

## 8. Streamlit application

The Streamlit app presents the source, target balance, model comparison, and an input form using the ten documented features. It returns an estimated review score plus situation-based resource ideas such as tutoring, study planning, catch-up material, flexible access, or campus internet access. The recommendations are explicit rules and are not generated from hidden model logic.

## 9. Limitations, bias, and safeguards

- The records are historical observations from two Portuguese secondary schools and are not representative of this university.
- Strong G1/G2 correlation makes the model useful only after those grades exist.
- Prediction does not prove that any suggested intervention will help.
- Academic records can reflect illness, disability, work, caregiving, transport, and unequal access. A score may reproduce these disadvantages.
- No fairness, calibration, causal-impact, privacy, security, drift, or user study has been performed.

A future pilot requires institutional approval, student participation, data minimisation, access control, retention rules, an appeal/correction route, human review, subgroup monitoring, and stop criteria. Support must remain available to all students regardless of score.

## 10. Conclusion

The project demonstrates a complete, reproducible ML workflow with a documented public dataset, EDA, leakage-resistant preprocessing, a baseline, two meaningful models, cross-validation, holdout evaluation, row-level error analysis, and a working Streamlit interface. The evidence supports the classroom pipeline only; local validation and governance are prerequisites for real use.

