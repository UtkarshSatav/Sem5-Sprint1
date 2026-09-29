"""Validation checks for the documented dataset and generated evidence."""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from modeling import FEATURES, TARGET, load_dataset  # noqa: E402


class DeliverableValidation(unittest.TestCase):
    def test_dataset_schema_and_target(self):
        frame = load_dataset()
        self.assertEqual(len(frame), 649)
        self.assertTrue(set(FEATURES + ["G3", TARGET]).issubset(frame.columns))
        self.assertEqual(set(frame[TARGET].unique()), {0, 1})
        self.assertEqual(int(frame[TARGET].sum()), 100)

    def test_generated_evidence_is_complete(self):
        expected = [
            "eda_summary.md",
            "target_balance.svg",
            "g2_distribution.svg",
            "priority_by_studytime.svg",
            "model_comparison.json",
            "holdout_error_analysis.csv",
            "logistic_model.joblib",
        ]
        for name in expected:
            path = ROOT / "outputs" / name
            self.assertTrue(path.exists(), name)
            self.assertGreater(path.stat().st_size, 100, name)

    def test_model_comparison_contains_experiments(self):
        result = json.loads(
            (ROOT / "outputs" / "model_comparison.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            set(result["models"]),
            {
                "Majority baseline",
                "Logistic regression",
                "Decision tree",
                "Logistic regression — no G1/G2 (early warning)",
            },
        )
        for values in result["models"].values():
            self.assertIn("confusion_matrix_tn_fp_fn_tp", values)
            self.assertIn("cv_mean_train_balanced_accuracy", values)
            self.assertIn("overfit_gap_balanced_accuracy", values)
        early = result["models"]["Logistic regression — no G1/G2 (early warning)"]
        self.assertNotIn("G1", early["features"])
        self.assertNotIn("G2", early["features"])
        self.assertLess(
            early["holdout_balanced_accuracy"],
            result["models"]["Logistic regression"]["holdout_balanced_accuracy"],
        )
        self.assertEqual([p["depth"] for p in result["tree_depth_curve"]], list(range(1, 11)))
        self.assertEqual(result["logistic_error_profile"]["false_negative"]["count"], 4)

    def test_saved_model_loads_and_predicts(self):
        import joblib
        import pandas as pd

        model = joblib.load(ROOT / "outputs" / "logistic_model.joblib")
        row = pd.DataFrame([{
            "G1": 8, "G2": 8, "studytime": 1, "failures": 1, "absences": 10,
            "traveltime": 3, "schoolsup": "no", "famsup": "no",
            "internet": "no", "higher": "yes",
        }])
        probability = float(model.predict_proba(row)[0, 1])
        self.assertGreater(probability, 0.5)


if __name__ == "__main__":
    unittest.main(verbosity=2)
