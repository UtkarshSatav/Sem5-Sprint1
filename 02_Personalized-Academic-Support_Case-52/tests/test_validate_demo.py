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
        ]
        for name in expected:
            path = ROOT / "outputs" / name
            self.assertTrue(path.exists(), name)
            self.assertGreater(path.stat().st_size, 100, name)

    def test_model_comparison_contains_two_models_and_baseline(self):
        result = json.loads(
            (ROOT / "outputs" / "model_comparison.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            set(result["models"]),
            {"Majority baseline", "Logistic regression", "Decision tree"},
        )
        for values in result["models"].values():
            self.assertIn("confusion_matrix_tn_fp_fn_tp", values)
            self.assertIn("cv_mean_f1_priority", values)


if __name__ == "__main__":
    unittest.main(verbosity=2)
