"""Train, compare, and document Case 52 classification models."""
from __future__ import annotations

import json

import joblib
import pandas as pd
from sklearn.dummy import DummyClassifier
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    confusion_matrix,
    f1_score,
    make_scorer,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_validate, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.tree import DecisionTreeClassifier

from modeling import (
    CATEGORICAL_FEATURES,
    EARLY_NUMERIC_FEATURES,
    FEATURES,
    MODEL_PATH,
    NUMERIC_FEATURES,
    ROOT,
    TARGET,
    load_dataset,
    make_logistic_model,
    make_preprocessor,
    make_tree_model,
)

OUT = ROOT / "outputs" / "model_comparison.json"
ERRORS = ROOT / "outputs" / "holdout_error_analysis.csv"


def _dummy_model() -> Pipeline:
    return Pipeline([
        ("preprocess", make_preprocessor()),
        ("model", DummyClassifier(strategy="most_frequent")),
    ])


def train() -> dict[str, object]:
    frame = load_dataset()
    x_data = frame[FEATURES]
    target = frame[TARGET]
    x_train, x_test, y_train, y_test = train_test_split(
        x_data,
        target,
        test_size=0.25,
        random_state=52,
        stratify=target,
    )
    early_features = EARLY_NUMERIC_FEATURES + CATEGORICAL_FEATURES
    models = {
        "Majority baseline": ("majority_baseline", FEATURES, _dummy_model()),
        "Logistic regression": ("logistic_regression", FEATURES, make_logistic_model()),
        "Decision tree": ("decision_tree", FEATURES, make_tree_model()),
        "Logistic regression — no G1/G2 (early warning)": (
            "logistic_no_grades",
            early_features,
            make_logistic_model(EARLY_NUMERIC_FEATURES, CATEGORICAL_FEATURES),
        ),
    }
    folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=52)
    scoring = {
        "balanced_accuracy": "balanced_accuracy",
        "precision": make_scorer(precision_score, zero_division=0),
        "recall": make_scorer(recall_score, zero_division=0),
        "f1": make_scorer(f1_score, zero_division=0),
        "roc_auc": "roc_auc",
    }
    result: dict[str, object] = {
        "dataset": "UCI Student Performance — Portuguese course",
        "doi": "10.24432/C5TG7T",
        "license": "CC BY 4.0",
        "rows": int(len(frame)),
        "features": FEATURES,
        "target": "support_priority = 1 when final grade G3 < 10/20",
        "positive_rows": int(target.sum()),
        "test_fraction": 0.25,
        "random_state": 52,
        "cross_validation": "5-fold stratified CV on the 75% training partition",
        "models": {},
    }
    error_frame = x_test.copy()
    error_frame["actual_support_priority"] = y_test

    for name, (key, features, model) in models.items():
        cv = cross_validate(
            model, x_train[features], y_train, cv=folds, scoring=scoring, return_train_score=True
        )
        model.fit(x_train[features], y_train)
        predicted = model.predict(x_test[features])
        probabilities = model.predict_proba(x_test[features])[:, 1]
        matrix = confusion_matrix(y_test, predicted, labels=[0, 1])
        result["models"][name] = {
            "features": features,
            "holdout_accuracy": round(float(accuracy_score(y_test, predicted)), 4),
            "holdout_balanced_accuracy": round(float(balanced_accuracy_score(y_test, predicted)), 4),
            "holdout_precision_priority": round(float(precision_score(y_test, predicted, zero_division=0)), 4),
            "holdout_recall_priority": round(float(recall_score(y_test, predicted, zero_division=0)), 4),
            "holdout_f1_priority": round(float(f1_score(y_test, predicted, zero_division=0)), 4),
            "holdout_roc_auc": round(float(roc_auc_score(y_test, probabilities)), 4),
            "confusion_matrix_tn_fp_fn_tp": {
                "tn": int(matrix[0, 0]),
                "fp": int(matrix[0, 1]),
                "fn": int(matrix[1, 0]),
                "tp": int(matrix[1, 1]),
            },
            "cv_mean_balanced_accuracy": round(float(cv["test_balanced_accuracy"].mean()), 4),
            "cv_mean_train_balanced_accuracy": round(float(cv["train_balanced_accuracy"].mean()), 4),
            "overfit_gap_balanced_accuracy": round(
                float(cv["train_balanced_accuracy"].mean() - cv["test_balanced_accuracy"].mean()), 4
            ),
            "cv_mean_precision_priority": round(float(cv["test_precision"].mean()), 4),
            "cv_mean_recall_priority": round(float(cv["test_recall"].mean()), 4),
            "cv_mean_f1_priority": round(float(cv["test_f1"].mean()), 4),
            "cv_mean_roc_auc": round(float(cv["test_roc_auc"].mean()), 4),
        }
        error_frame[f"{key}_prediction"] = predicted
        error_frame[f"{key}_probability"] = probabilities.round(6)

    logistic_prediction = error_frame["logistic_regression_prediction"]
    error_frame["logistic_error_type"] = "correct"
    error_frame.loc[(y_test == 1) & (logistic_prediction == 0), "logistic_error_type"] = "false_negative"
    error_frame.loc[(y_test == 0) & (logistic_prediction == 1), "logistic_error_type"] = "false_positive"

    depth_curve = []
    for depth in range(1, 11):
        tree = Pipeline([
            ("preprocess", make_preprocessor()),
            ("model", DecisionTreeClassifier(
                max_depth=depth, min_samples_leaf=10,
                class_weight="balanced", random_state=52,
            )),
        ])
        scores = cross_validate(
            tree, x_train, y_train, cv=folds,
            scoring="balanced_accuracy", return_train_score=True,
        )
        depth_curve.append({
            "depth": depth,
            "train_balanced_accuracy": round(float(scores["train_score"].mean()), 4),
            "validation_balanced_accuracy": round(float(scores["test_score"].mean()), 4),
        })
    result["tree_depth_curve"] = depth_curve

    profile = {}
    for label in ["false_negative", "false_positive"]:
        rows = error_frame[error_frame["logistic_error_type"] == label]
        profile[label] = {
            "count": int(len(rows)),
            "mean": {c: round(float(rows[c].mean()), 2) for c in NUMERIC_FEATURES},
        }
    true_pos = error_frame[(y_test == 1) & (error_frame["logistic_regression_prediction"] == 1)]
    profile["true_positive"] = {
        "count": int(len(true_pos)),
        "mean": {c: round(float(true_pos[c].mean()), 2) for c in NUMERIC_FEATURES},
    }
    result["logistic_error_profile"] = profile

    joblib.dump(models["Logistic regression"][2], MODEL_PATH)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    error_frame.sort_index().to_csv(ERRORS, index_label="source_row")
    return result


if __name__ == "__main__":
    print(json.dumps(train(), indent=2))
