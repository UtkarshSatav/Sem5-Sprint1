"""Streamlit interface for Case 52 — Personalized Academic Support."""
from __future__ import annotations

import json
from pathlib import Path

import pandas as pd
import streamlit as st

from src.modeling import (
    FEATURES,
    ROOT,
    TARGET,
    load_dataset,
    make_logistic_model,
    support_recommendations,
)

METRICS = ROOT / "outputs" / "model_comparison.json"


@st.cache_data
def data() -> pd.DataFrame:
    return load_dataset()


@st.cache_resource
def fitted_model():
    frame = data()
    model = make_logistic_model()
    model.fit(frame[FEATURES], frame[TARGET])
    return model


def load_metrics() -> dict[str, object] | None:
    if not METRICS.exists():
        return None
    return json.loads(METRICS.read_text(encoding="utf-8"))


st.set_page_config(
    page_title="Academic Support Explorer",
    page_icon="🎓",
    layout="wide",
)

st.title("Personalized Academic Support")
st.caption("Case 52 · Explainable mid-year review prototype")
st.info(
    "This classroom prototype estimates whether a student situation should be reviewed for an optional support conversation. "
    "It must not diagnose, punish, deny services, or replace a student or advisor decision."
)

frame = data()
metrics = load_metrics()
overview_tab, profile_tab, method_tab = st.tabs(
    ["Project overview", "Try a student situation", "Method and limitations"]
)

with overview_tab:
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Dataset rows", f"{len(frame):,}")
    c2.metric("Model inputs", len(FEATURES))
    c3.metric("Support-priority cases", f"{int(frame[TARGET].sum())} ({frame[TARGET].mean():.1%})")
    c4.metric("Missing input cells", int(frame[FEATURES].isna().sum().sum()))

    st.subheader("Problem and output")
    st.write(
        "The model performs binary classification after the second grading period. "
        "A positive output means **invite a human review and offer support options**; a negative output means keep routine resources available. "
        "The target is final grade below 10/20 in the UCI Portuguese-course data."
    )
    st.caption(
        "Source: Cortez, P. (2008), UCI Student Performance, DOI 10.24432/C5TG7T, CC BY 4.0."
    )

    st.subheader("Target balance")
    counts = frame[TARGET].value_counts().sort_index()
    st.bar_chart(
        pd.DataFrame(
            {"Students": [int(counts.get(0, 0)), int(counts.get(1, 0))]},
            index=["Routine", "Support priority"],
        )
    )

    st.subheader("Model comparison")
    if metrics is None:
        st.warning("Run `python3 src/train_evaluate.py` to generate the reproducible evaluation output.")
    else:
        rows = []
        for name, result in metrics["models"].items():
            rows.append({
                "Model": name,
                "Balanced accuracy": result["holdout_balanced_accuracy"],
                "Precision": result["holdout_precision_priority"],
                "Recall": result["holdout_recall_priority"],
                "F1": result["holdout_f1_priority"],
                "ROC AUC": result["holdout_roc_auc"],
            })
        st.dataframe(
            pd.DataFrame(rows).set_index("Model").style.format("{:.3f}"),
            use_container_width=True,
        )
        st.caption(
            "Stratified 75/25 holdout with random state 52. Five-fold cross-validation is performed only on the training partition. "
            "Recall matters because a false negative misses a possible offer; precision matters because unwanted outreach can burden students."
        )

with profile_tab:
    st.subheader("Enter an illustrative situation")
    st.write(
        "The values match the documented UCI fields. Do not enter a real student's information into this classroom demo."
    )
    with st.form("student_situation"):
        left, middle, right = st.columns(3)
        with left:
            g1 = st.slider("First-period grade", 0, 20, 11)
            g2 = st.slider("Second-period grade", 0, 20, 11)
            absences = st.number_input("Recorded absences", 0, 100, 4)
        with middle:
            studytime = st.select_slider(
                "Weekly study time",
                options=[1, 2, 3, 4],
                value=2,
                format_func=lambda value: {
                    1: "<2 hours",
                    2: "2–5 hours",
                    3: "5–10 hours",
                    4: ">10 hours",
                }[value],
            )
            failures = st.number_input("Previous class failures", 0, 4, 0)
            traveltime = st.select_slider(
                "Travel time to school",
                options=[1, 2, 3, 4],
                value=2,
                format_func=lambda value: {
                    1: "<15 minutes",
                    2: "15–30 minutes",
                    3: "30–60 minutes",
                    4: ">60 minutes",
                }[value],
            )
        with right:
            schoolsup = st.radio("Current school support", ["yes", "no"], horizontal=True)
            famsup = st.radio("Current family support", ["yes", "no"], horizontal=True)
            internet = st.radio("Internet at home", ["yes", "no"], horizontal=True)
            higher = st.radio("Plans higher education", ["yes", "no"], horizontal=True)
        submitted = st.form_submit_button("Review this situation", type="primary")

    if submitted:
        profile = {
            "G1": int(g1),
            "G2": int(g2),
            "studytime": int(studytime),
            "failures": int(failures),
            "absences": int(absences),
            "traveltime": int(traveltime),
            "schoolsup": schoolsup,
            "famsup": famsup,
            "internet": internet,
            "higher": higher,
        }
        probability = float(
            fitted_model().predict_proba(pd.DataFrame([profile]))[0, 1]
        )
        result_left, result_right = st.columns([1, 2])
        with result_left:
            st.metric("Estimated review score", f"{probability:.0%}")
            if probability >= 0.5:
                st.warning("Invite a human review and offer support choices.")
            else:
                st.success("Keep routine resources available; no targeted review signal.")
        with result_right:
            st.markdown("#### Transparent support ideas")
            for suggestion in support_recommendations(profile):
                st.markdown(f"- {suggestion}")
        st.caption(
            "The 50% display threshold is for demonstration. A real threshold must be chosen with students and advisors using workload, false-negative, and false-positive costs."
        )

with method_tab:
    st.subheader("Reproducible pipeline")
    st.code(
        "UCI CSV → target derivation → stratified split → training-only preprocessing\n"
        "→ baseline + logistic regression + shallow decision tree\n"
        "→ cross-validation + untouched holdout → error analysis → Streamlit output",
        language="text",
    )
    st.markdown(
        """
**Preprocessing.** Numeric fields use median imputation and standard scaling. Categorical yes/no fields use most-frequent imputation and one-hot encoding. Every transformation sits inside a scikit-learn pipeline and is fitted on training folds only.

**Why these models.** The majority baseline exposes the effect of class imbalance. Logistic regression is the primary app model because it is compact and explainable. A depth-limited decision tree provides a meaningful non-linear comparison while limiting overfitting.

**Error interpretation.** A false negative may delay a useful offer. A false positive can create unwanted contact or stigma. Neither error should trigger an automatic decision, and ordinary support remains available to everyone.

**Limitations.** The data covers two Portuguese secondary schools and was donated in 2014 from an earlier study. Earlier grades strongly predict the final grade, so the app is a mid-year review demonstration. It is not validated for this university or for current students. No causal, fairness, calibration, drift, security, or user-impact study has been completed.

**Excluded data.** The source includes demographic, family, health, relationship, and alcohol-use attributes. This prototype deliberately excludes them from modelling to reduce intrusive profiling and because they are unnecessary for the case-study objective.
"""
    )

st.divider()
st.caption(
    "Educational prototype · Human review required · Services remain available regardless of score"
)
