"""EDA evidence must record data-quality issues and subgroup rates."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

import eda  # noqa: E402


class EdaEvidence(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        eda.run()
        cls.summary = (ROOT / "outputs" / "eda_summary.md").read_text(encoding="utf-8")

    def test_new_charts_exist(self):
        for name in ["priority_by_school.svg", "priority_by_failures.svg"]:
            self.assertGreater((ROOT / "outputs" / name).stat().st_size, 100, name)

    def test_data_quality_section_records_issues(self):
        self.assertIn("## Data-quality issues", self.summary)
        self.assertIn("15 rows have G3 = 0", self.summary)
        self.assertIn("skew 2.02", self.summary)
        self.assertIn("n if 1<=n<3, else 4", self.summary)

    def test_subgroup_and_correlation_findings(self):
        self.assertIn("30.1%", self.summary)
        self.assertIn("7.6%", self.summary)
        self.assertIn("0.919", self.summary)


if __name__ == "__main__":
    unittest.main(verbosity=2)
