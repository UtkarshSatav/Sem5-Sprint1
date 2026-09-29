# Dataset card

## Source

- Dataset: **Student Performance**, Portuguese-language course file `student-por.csv`
- Creator/citation: Paulo Cortez, 2008
- Repository: UCI Machine Learning Repository
- DOI: https://doi.org/10.24432/C5TG7T
- License: Creative Commons Attribution 4.0 International (CC BY 4.0)
- Downloaded from the official UCI archive file `student.zip`

The source contains 649 records from two Portuguese secondary schools, collected from school reports and questionnaires. The original variable descriptions are preserved in `student.txt`.

## Task construction

The classification target is derived only for this case study:

```text
support_priority = 1 when G3 < 10
support_priority = 0 when G3 >= 10
```

`G3` is the final Portuguese-course grade on a 0–20 scale. Inputs are values available before that final grade: `G1`, `G2`, study-time band, previous failures, absences, travel-time band, existing school support, family support, internet access, and intention to pursue higher education.

## Data quality

- 649 rows and 33 source columns
- No missing values documented by UCI or present in the selected fields
- No exact duplicate rows
- 100 priority rows and 549 routine rows
- The positive class is imbalanced at 15.4%
- 15 rows have G3 = 0 (8 of them with G2 > 0). These look like students who left or missed the final assessment, so they are noisy positive labels; they are kept and flagged as a limitation.
- Absences are right-skewed (skew 2.02); 8 rows exceed 20 and the maximum is 32.
- G1 and G2 are strongly collinear (r = 0.865) and G2 correlates 0.919 with G3, so G1/G2 coefficients should not be read independently.
- `studytime` and `traveltime` are ordinal bands (1–4), not hours, and are scaled as ordered numbers.
- `student.txt` documents failures as `n if 1<=n<3, else 4`, but the maximum observed value is 3, so 3 is treated as "3 or more".
- G1 and G2 are quoted strings in the raw CSV but parse cleanly as integers.
- Priority rate differs by school: GP 7.6% (n = 423) vs MS 30.1% (n = 226).

## Exclusions

Demographic, parent/family background, health, relationship, and alcohol-use variables are present in the source but deliberately excluded from modelling. They are unnecessary for the demonstration and could enable intrusive profiling. `G3` is used only to derive the target and is never an input feature.

## Limitations

The dataset is historical, covers two schools in Portugal, and describes secondary students. Earlier-period grades strongly correlate with the final grade. Results therefore demonstrate a mid-year review pipeline and cannot be generalized to this university without a new governed study.

