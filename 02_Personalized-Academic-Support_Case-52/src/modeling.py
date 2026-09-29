"""Shared data, preprocessing, modelling, and recommendation helpers."""
from __future__ import annotations

from pathlib import Path

import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.tree import DecisionTreeClassifier

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "student-por.csv"
TARGET = "support_priority"
NUMERIC_FEATURES = ["G1", "G2", "studytime", "failures", "absences", "traveltime"]
CATEGORICAL_FEATURES = ["schoolsup", "famsup", "internet", "higher"]
FEATURES = NUMERIC_FEATURES + CATEGORICAL_FEATURES

FIELD_LABELS = {
    "G1": "First-period grade (0–20)",
    "G2": "Second-period grade (0–20)",
    "studytime": "Weekly study-time band (1–4)",
    "failures": "Previous class failures",
    "absences": "Recorded absences",
    "traveltime": "Home-to-school travel band (1–4)",
    "schoolsup": "Currently receives school support",
    "famsup": "Currently receives family support",
    "internet": "Internet available at home",
    "higher": "Intends to pursue higher education",
}


def load_dataset(path: Path = DATA) -> pd.DataFrame:
    """Load the UCI Portuguese-course file and derive the review target."""
    frame = pd.read_csv(path, sep=";")
    missing = [column for column in FEATURES + ["G3"] if column not in frame]
    if missing:
        raise ValueError(f"Dataset is missing required columns: {missing}")
    frame = frame.copy()
    frame[TARGET] = (frame["G3"] < 10).astype(int)
    return frame


def make_preprocessor() -> ColumnTransformer:
    numeric = Pipeline([
        ("impute", SimpleImputer(strategy="median")),
        ("scale", StandardScaler()),
    ])
    categorical = Pipeline([
        ("impute", SimpleImputer(strategy="most_frequent")),
        ("encode", OneHotEncoder(handle_unknown="ignore")),
    ])
    return ColumnTransformer([
        ("numeric", numeric, NUMERIC_FEATURES),
        ("categorical", categorical, CATEGORICAL_FEATURES),
    ])


def make_logistic_model() -> Pipeline:
    return Pipeline([
        ("preprocess", make_preprocessor()),
        ("model", LogisticRegression(
            max_iter=2000,
            class_weight="balanced",
            random_state=52,
        )),
    ])


def make_tree_model() -> Pipeline:
    return Pipeline([
        ("preprocess", make_preprocessor()),
        ("model", DecisionTreeClassifier(
            max_depth=4,
            min_samples_leaf=10,
            class_weight="balanced",
            random_state=52,
        )),
    ])


def support_recommendations(profile: dict[str, object]) -> list[str]:
    """Turn the submitted situation into transparent, non-ML resource ideas."""
    suggestions: list[str] = []
    if float(profile["G2"]) < 10:
        suggestions.append("Offer a subject tutor or faculty office-hours check-in.")
    if int(profile["studytime"]) <= 1:
        suggestions.append("Create a short weekly study plan with the learning-skills team.")
    if int(profile["failures"]) > 0:
        suggestions.append("Review prerequisite topics and agree a recovery plan with an advisor.")
    if int(profile["absences"]) >= 10:
        suggestions.append("Invite a non-judgmental attendance check-in and share catch-up materials.")
    if int(profile["traveltime"]) >= 3:
        suggestions.append("Offer flexible office hours and asynchronous learning materials.")
    if profile["internet"] == "no":
        suggestions.append("Provide offline materials and information about campus computer access.")
    if profile["schoolsup"] == "no":
        suggestions.append("Explain available school-based academic support and how to opt in.")
    if not suggestions:
        suggestions.append("Keep routine resources visible and let the student request support at any time.")
    return suggestions
