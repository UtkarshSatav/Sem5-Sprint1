# Exploratory data analysis

Dataset: UCI Student Performance, Portuguese-language course (Cortez, 2008).
Rows: 649; source columns: 33; modelling features: 10.
Missing cells in modelling fields and target: 0; exact duplicate rows: 0.
Target counts: routine=549, priority=100 (15.4% priority).

## Numeric summary

| Statistic | G1 | G2 | G3 | studytime | failures | absences | traveltime |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| count | 649.00 | 649.00 | 649.00 | 649.00 | 649.00 | 649.00 | 649.00 |
| mean | 11.40 | 11.57 | 11.91 | 1.93 | 0.22 | 3.66 | 1.57 |
| std | 2.75 | 2.91 | 3.23 | 0.83 | 0.59 | 4.64 | 0.75 |
| min | 0.00 | 0.00 | 0.00 | 1.00 | 0.00 | 0.00 | 1.00 |
| 25% | 10.00 | 10.00 | 10.00 | 1.00 | 0.00 | 0.00 | 1.00 |
| 50% | 11.00 | 11.00 | 12.00 | 2.00 | 0.00 | 2.00 | 1.00 |
| 75% | 13.00 | 13.00 | 14.00 | 2.00 | 0.00 | 6.00 | 2.00 |
| max | 19.00 | 19.00 | 19.00 | 4.00 | 3.00 | 32.00 | 4.00 |

## Observations

- The positive class is the minority, so accuracy alone is unsuitable. Balanced accuracy, positive-class precision, recall, F1, ROC AUC, and a confusion matrix are reported.
- G1 and G2 are earlier-period grades. UCI documents their strong correlation with final grade G3; this makes the prototype a mid-year review tool, not an enrolment-time prediction.
- The source contains demographic, family, health, and alcohol-use fields. They are excluded from this model because they are unnecessary for the classroom objective and could create intrusive or discriminatory profiling.
- The supplied dataset has no documented missing values. The pipeline still includes training-fitted imputers so its preprocessing steps are explicit and robust to future missing inputs.
- Records come from two Portuguese secondary schools and cannot be assumed to represent another institution, country, age group, or current cohort.

![Target balance](target_balance.svg)

![Second-period grades](g2_distribution.svg)

![Priority rate by study time](priority_by_studytime.svg)
