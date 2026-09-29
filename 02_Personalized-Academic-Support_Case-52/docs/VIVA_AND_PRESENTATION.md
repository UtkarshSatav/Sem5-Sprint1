# Presentation and Viva — Case 52

## Seven-slide presentation

1. **Problem and stakeholders** — support students early; output is a human review prompt.
2. **Dataset and target** — UCI Portuguese course, 649 records; `G3 < 10` is the positive class.
3. **EDA** — 15.4% priority class, no missing selected values, earlier grades strongly related to final grade.
4. **Preprocessing** — stratified split; training-only imputation, scaling, and one-hot encoding.
5. **Models** — majority baseline, logistic regression, and a constrained decision tree.
6. **Results and errors** — logistic: 0.873 balanced accuracy, 0.840 recall, 0.712 F1; explain 13 FP and 4 FN.
7. **App, limits, and next step** — live profile demo, transparent resources, human oversight, local validation required.

## Two-minute explanation

“The problem is to identify a student situation that may benefit from an optional academic-support conversation. I formulated it as binary classification after the second grading period. I use the UCI Portuguese Student Performance dataset with 649 rows and define the target as final grade below 10 out of 20. I selected ten academic and access-related inputs and excluded demographic, health, family-background, relationship, and alcohol fields.

The positive class is only 15.4%, so I do not rely on accuracy. I use a stratified 75/25 holdout and five-fold cross-validation within the training partition. Numeric imputation and scaling plus categorical imputation and one-hot encoding are inside the model pipeline, which prevents preprocessing leakage.

I compare a majority baseline, class-weighted logistic regression, and a constrained decision tree. Logistic regression performs best on the holdout with 0.873 balanced accuracy, 0.840 recall, 0.712 F1, and 0.939 ROC AUC. Its confusion matrix has 125 true negatives, 13 false positives, 4 false negatives, and 21 true positives.

The Streamlit app shows an estimated review score and transparent support choices. A human makes the decision and support stays available to everyone. The main limitation is that the historical data comes from two Portuguese secondary schools and G1/G2 strongly predict G3, so this is a mid-year educational prototype, not a validated university system.”

## Application demonstration

1. Show dataset size, class balance, and the three-model comparison.
2. Explain why the baseline’s 84.7% accuracy is misleading: it has zero recall.
3. Open **Try a student situation** and enter a lower G2, low study time, and no internet.
4. Show the review score and the separate transparent resource suggestions.
5. Open **Method and limitations** and explain training-only preprocessing and human oversight.

## Likely viva questions

**Why classification?** The required operational output is whether to invite a support review, which has two classes. The probability also lets stakeholders study alternative thresholds.

**Why not accuracy?** With 84.6% routine cases, always predicting routine already gives 84.7% accuracy but misses all 25 positive holdout cases. Balanced accuracy, recall, precision, F1, ROC AUC, and the confusion matrix expose this failure.

**Why logistic regression?** It is explainable, supports probabilities and class weights, and outperforms the constrained tree on holdout balanced accuracy, recall, F1, and ROC AUC.

**How is leakage prevented?** `G3` creates the target and is removed from features. Split happens before fitting. Imputation, encoding, and scaling live inside the pipeline and fit only on training folds. G1 and G2 are legitimate earlier observations, but their strong relationship to G3 limits the task to mid-year use.

**What is overfitting?** It is learning training-specific noise rather than patterns that generalize. I constrain tree depth and leaf size, use five-fold training cross-validation, and report an untouched holdout result.

**What do false positives and false negatives mean?** A false positive can cause unnecessary outreach; a false negative may delay an offer. Neither should cause an automatic decision.

**What bias is possible?** Academic outcomes may reflect disability, health, work, care duties, transport, or unequal access. Even without demographic fields, inputs can reflect structural disadvantage. Real use requires student governance and subgroup error monitoring.

**What would you improve for production?** Collect current, consented, locally relevant data; define the outcome with students and advisors; validate across time and groups; calibrate probabilities; choose a reviewed threshold; secure data; monitor drift and impact; and retain a non-ML route to support.
