# EarlyNudge: Mid-Semester Academic Support Triage from Grade and Engagement Signals (proposed title)

Presentation and Viva — Case 52

## Eight-slide presentation

1. **Title** — EarlyNudge: Mid-Semester Academic Support Triage from Grade and Engagement Signals (proposed title); Case 52.
2. **Problem and output** — support students early; output is a human review prompt (classification plus transparent rules).
3. **Dataset and data-quality issues** — UCI Portuguese course, 649 records; `G3 < 10` is the positive class; 15 rows with G3 = 0, skewed absences, G1/G2 collinearity, failures documentation mismatch.
4. **EDA, including the school bias finding** — 15.4% priority class; GP 7.6% vs MS 30.1%; failures raise the rate from 9.3% to 64.3%.
5. **Preprocessing and validation** — stratified split; training-only imputation, scaling and one-hot encoding; 5-fold CV plus untouched holdout.
6. **Models and results (4 models)** — baseline, logistic regression (0.8729 balanced accuracy), decision tree, early-warning logistic without G1/G2 (0.6439).
7. **Overfitting and errors** — train–validation gaps and depth curve; 13 FP and 4 FN; the false negatives all had a passing G2.
8. **App demo flow, limitations and next steps** — live profile demo using the saved model, transparent resources, human oversight, per-school error checks, local validation.

## Two-minute explanation

“The problem is to identify a student situation that may benefit from an optional academic-support conversation. I formulated it as binary classification after the second grading period. I use the UCI Portuguese Student Performance dataset with 649 rows and define the target as final grade below 10 out of 20. I selected ten academic and access-related inputs and excluded demographic, health, family-background, relationship, and alcohol fields.

The positive class is only 15.4%, so I do not rely on accuracy. I use a stratified 75/25 holdout and five-fold cross-validation within the training partition. Numeric imputation and scaling plus categorical imputation and one-hot encoding are inside the model pipeline, which prevents preprocessing leakage.

I compare a majority baseline, class-weighted logistic regression, and a constrained decision tree. Logistic regression performs best on the holdout with 0.873 balanced accuracy, 0.840 recall, 0.712 F1, and 0.939 ROC AUC. Its confusion matrix has 125 true negatives, 13 false positives, 4 false negatives, and 21 true positives.

I also ran an early-warning experiment that removes G1 and G2. Balanced accuracy falls from 0.8729 to 0.6439 and recall from 0.84 to 0.44, so most of the signal is earlier grades. Looking at the four false negatives, all had a passing G2 of at least 10 and no previous failures, while true positives average G2 7.38: students who decline after a passing mid-year grade are the blind spot. Overfitting gaps between training and validation are small, at most 0.0399 for logistic regression.

The Streamlit app shows an estimated review score and transparent support choices. A human makes the decision and support stays available to everyone. The main limitation is that the historical data comes from two Portuguese secondary schools and G1/G2 strongly predict G3, so this is a mid-year educational prototype, not a validated university system.”

## Application demonstration

1. Show dataset size, class balance, and the four-model comparison with its train–validation gap column.
2. Explain why the baseline’s 84.7% accuracy is misleading: it has zero recall.
3. Open **Try a student situation** and enter a lower G2, low study time, and no internet.
4. Show the review score and the separate transparent resource suggestions.
5. Open **Method and limitations** and explain training-only preprocessing and human oversight.

## Likely viva questions

**Why classification?** The required operational output is whether to invite a support review, which has two classes. The probability also lets stakeholders study alternative thresholds.

**Why not accuracy?** With 84.6% routine cases, always predicting routine already gives 84.7% accuracy but misses all 25 positive holdout cases. Balanced accuracy, recall, precision, F1, ROC AUC, and the confusion matrix expose this failure.

**Why logistic regression?** It is explainable, supports probabilities and class weights, and outperforms the constrained tree on holdout balanced accuracy, recall, F1, and ROC AUC.

**How is leakage prevented?** `G3` creates the target and is removed from features. Split happens before fitting. Imputation, encoding, and scaling live inside the pipeline and fit only on training folds. G1 and G2 are legitimate earlier observations, but their strong relationship to G3 limits the task to mid-year use.

**What did the early-warning experiment show?** Without G1 and G2 the logistic model has holdout balanced accuracy 0.6439, recall 0.44 and ROC AUC 0.6907, against 0.8729, 0.84 and 0.9391 with them. It beats the baseline but misses more than half the priority cases, so an enrolment-time tool would need better signals than these.

**How did you check overfitting?** I compared training and validation balanced accuracy inside five-fold CV: gaps are 0.0346 for the tree and 0.0399 for logistic regression. I also plotted a depth 1 to 10 curve for the tree: the gap grows to 0.0346 by depth 4 and then plateaus because of the minimum leaf size. The untouched holdout gives a second check.

**What data-quality issues did you find?** 15 rows with G3 = 0 (likely dropouts, so noisy labels), right-skewed absences (skew 2.02, max 32), collinear G1/G2 (r = 0.865), ordinal study-time and travel-time bands, a failures field whose documentation says "n if 1<=n<3, else 4" while the maximum is 3, and a school gap in priority rate (GP 7.6% vs MS 30.1%).

**What is overfitting?** It is learning training-specific noise rather than patterns that generalize. I constrain tree depth and leaf size, use five-fold training cross-validation, and report an untouched holdout result.

**What do false positives and false negatives mean?** A false positive can cause unnecessary outreach; a false negative may delay an offer. Neither should cause an automatic decision.

**What bias is possible?** Academic outcomes may reflect disability, health, work, care duties, transport, or unequal access. Even without demographic fields, inputs can reflect structural disadvantage. Real use requires student governance and subgroup error monitoring.

**What would you improve for production?** Collect current, consented, locally relevant data; define the outcome with students and advisors; validate across time and groups; calibrate probabilities; choose a reviewed threshold; secure data; monitor drift and impact; and retain a non-ML route to support.
