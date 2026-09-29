"""Generate reproducible EDA notes and SVG charts for the UCI dataset."""
from __future__ import annotations

from html import escape
from pathlib import Path

from modeling import FEATURES, ROOT, TARGET, load_dataset

OUT = ROOT / "outputs"
NUMERIC_COLUMNS = ["G1", "G2", "G3", "studytime", "failures", "absences", "traveltime"]


def write_bar_svg(
    path: Path,
    title: str,
    labels: list[str],
    values: list[float],
    y_label: str,
    color: str,
    suffix: str = "",
) -> None:
    width, height, left, bottom, top = 760, 420, 76, 325, 68
    plot_height = bottom - top
    maximum = max(values or [1]) or 1
    chart_width = 560
    bar_width = min(82, chart_width / max(len(values), 1) * 0.58)
    step = chart_width / max(len(values), 1)
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="white"/>',
        f'<text x="{left}" y="34" font-family="Arial" font-size="21" font-weight="bold">{escape(title)}</text>',
        f'<text x="19" y="205" transform="rotate(-90 19 205)" font-family="Arial" font-size="13">{escape(y_label)}</text>',
    ]
    for tick in range(5):
        y = bottom - tick * plot_height / 4
        value = maximum * tick / 4
        parts.append(f'<line x1="{left}" y1="{y:.1f}" x2="{left + chart_width}" y2="{y:.1f}" stroke="#e4e7ec"/>')
        parts.append(f'<text x="{left - 10}" y="{y + 4:.1f}" text-anchor="end" font-family="Arial" font-size="11">{value:.0f}</text>')
    for index, (label, value) in enumerate(zip(labels, values)):
        x = left + index * step + (step - bar_width) / 2
        bar_height = value / maximum * plot_height
        parts.append(f'<rect x="{x:.1f}" y="{bottom - bar_height:.1f}" width="{bar_width:.1f}" height="{bar_height:.1f}" rx="5" fill="{color}"/>')
        parts.append(f'<text x="{x + bar_width / 2:.1f}" y="{bottom - bar_height - 7:.1f}" text-anchor="middle" font-family="Arial" font-size="12">{value:.1f}{escape(suffix)}</text>')
        parts.append(f'<text x="{x + bar_width / 2:.1f}" y="{bottom + 22}" text-anchor="middle" font-family="Arial" font-size="11">{escape(label)}</text>')
    parts.append(f'<line x1="{left}" y1="{top}" x2="{left}" y2="{bottom}" stroke="#344054"/>')
    parts.append(f'<line x1="{left}" y1="{bottom}" x2="{left + chart_width}" y2="{bottom}" stroke="#344054"/>')
    parts.append('</svg>')
    path.write_text("\n".join(parts), encoding="utf-8")


def run() -> None:
    frame = load_dataset()
    OUT.mkdir(parents=True, exist_ok=True)
    class_counts = frame[TARGET].value_counts().sort_index()
    grade_bands = [(-1, 4, "0–4"), (4, 9, "5–9"), (9, 14, "10–14"), (14, 20, "15–20")]
    grade_counts = [int(frame["G2"].between(low + 1, high).sum()) for low, high, _ in grade_bands]
    study_rates = [
        100 * float(frame.loc[frame["studytime"] == value, TARGET].mean())
        for value in range(1, 5)
    ]

    write_bar_svg(
        OUT / "target_balance.svg",
        "Support-priority target balance",
        ["Routine", "Priority"],
        [float(class_counts.get(0, 0)), float(class_counts.get(1, 0))],
        "Students",
        "#3559C7",
    )
    write_bar_svg(
        OUT / "g2_distribution.svg",
        "Second-period grade distribution",
        [item[2] for item in grade_bands],
        [float(value) for value in grade_counts],
        "Students",
        "#1B8A73",
    )
    write_bar_svg(
        OUT / "priority_by_studytime.svg",
        "Support-priority rate by weekly study-time band",
        ["<2h", "2–5h", "5–10h", ">10h"],
        study_rates,
        "Priority rate (%)",
        "#D97732",
        "%",
    )

    school_rates = frame.groupby("school")[TARGET].mean().mul(100)
    school_sizes = frame["school"].value_counts()
    write_bar_svg(
        OUT / "priority_by_school.svg",
        "Support-priority rate by school",
        [f"{s} (n={int(school_sizes[s])})" for s in ["GP", "MS"]],
        [float(school_rates[s]) for s in ["GP", "MS"]],
        "Priority rate (%)",
        "#7A4CC2",
        "%",
    )
    failure_rates = frame.groupby("failures")[TARGET].mean().mul(100)
    write_bar_svg(
        OUT / "priority_by_failures.svg",
        "Support-priority rate by previous class failures",
        [str(v) for v in failure_rates.index],
        [float(v) for v in failure_rates.values],
        "Priority rate (%)",
        "#C2413B",
        "%",
    )
    corr = frame[NUMERIC_COLUMNS].corr().round(3)
    zero_g3 = int((frame["G3"] == 0).sum())
    zero_g3_with_g2 = int(((frame["G3"] == 0) & (frame["G2"] > 0)).sum())
    absences_skew = float(frame["absences"].skew())
    high_absence = int((frame["absences"] > 20).sum())

    missing = int(frame[FEATURES + ["G3"]].isna().sum().sum())
    duplicates = int(frame.duplicated().sum())
    numeric = frame[NUMERIC_COLUMNS].describe().round(2)
    lines = [
        "# Exploratory data analysis",
        "",
        "Dataset: UCI Student Performance, Portuguese-language course (Cortez, 2008).",
        f"Rows: {len(frame)}; source columns: 33; modelling features: {len(FEATURES)}.",
        f"Missing cells in modelling fields and target: {missing}; exact duplicate rows: {duplicates}.",
        f"Target counts: routine={int(class_counts.get(0, 0))}, priority={int(class_counts.get(1, 0))} ({frame[TARGET].mean():.1%} priority).",
        "",
        "## Numeric summary",
        "",
        "| Statistic | " + " | ".join(numeric.columns) + " |",
        "| --- | " + " | ".join("---:" for _ in numeric.columns) + " |",
        *[
            f"| {index} | " + " | ".join(f"{value:.2f}" for value in row) + " |"
            for index, row in numeric.iterrows()
        ],
        "",
        "## Data-quality issues",
        "",
        f"- {zero_g3} rows have G3 = 0 ({zero_g3_with_g2} of them with G2 > 0). These look like students who left or missed the final assessment rather than true zero attainment, so they are noisy positive labels. They are kept, because excluding them would hide real disengagement, and flagged as a limitation.",
        f"- Absences are right-skewed (skew {absences_skew:.2f}); {high_absence} rows exceed 20 and the maximum is {int(frame['absences'].max())}. Standard scaling keeps them, and logistic regression is sensitive to such outliers.",
        f"- G1 and G2 are strongly collinear (r = {corr.loc['G1', 'G2']:.3f}) and G2 correlates {corr.loc['G2', 'G3']:.3f} with G3, so coefficients for G1 and G2 should not be read independently.",
        "- `studytime` and `traveltime` are ordinal bands (1–4), not hours. They are scaled as ordered numbers, which assumes equal spacing between bands.",
        f"- `student.txt` documents failures as `n if 1<=n<3, else 4`, but the maximum observed value is {int(frame['failures'].max())}. Value 3 is therefore treated as '3 or more'.",
        "- G1 and G2 are quoted strings in the raw CSV, but they parse cleanly as integers. No missing values or exact duplicates are present.",
        "",
        "## Correlation with final grade G3",
        "",
        "| Feature | r with G3 |",
        "| --- | ---: |",
        *[f"| {c} | {corr.loc[c, 'G3']:.3f} |" for c in NUMERIC_COLUMNS if c != "G3"],
        "",
        "## Observations",
        "",
        "- The positive class is the minority, so accuracy alone is unsuitable. Balanced accuracy, positive-class precision, recall, F1, ROC AUC, and a confusion matrix are reported.",
        "- G1 and G2 are earlier-period grades. UCI documents their strong correlation with final grade G3; this makes the prototype a mid-year review tool, not an enrolment-time prediction.",
        "- The source contains demographic, family, health, and alcohol-use fields. They are excluded from this model because they are unnecessary for the classroom objective and could create intrusive or discriminatory profiling.",
        "- The supplied dataset has no documented missing values. The pipeline still includes training-fitted imputers so its preprocessing steps are explicit and robust to future missing inputs.",
        "- Records come from two Portuguese secondary schools and cannot be assumed to represent another institution, country, age group, or current cohort.",
        f"- Priority rate differs sharply by school: GP {school_rates['GP']:.1f}% vs MS {school_rates['MS']:.1f}%. `school` is not a model input, but any input correlated with school can carry this gap, so errors must be checked per school (see the report's bias section).",
        f"- Priority rate rises with previous failures: {', '.join(f'{int(k)} → {v:.1f}%' for k, v in failure_rates.items())}.",
        "",
        "![Target balance](target_balance.svg)",
        "",
        "![Second-period grades](g2_distribution.svg)",
        "",
        "![Priority rate by study time](priority_by_studytime.svg)",
        "",
        "![Priority rate by school](priority_by_school.svg)",
        "",
        "![Priority rate by failures](priority_by_failures.svg)",
    ]
    (OUT / "eda_summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote EDA for {len(frame)} rows to {OUT}")


if __name__ == "__main__":
    run()
