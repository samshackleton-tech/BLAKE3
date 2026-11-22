"""One mutation run at a time holds the worktrees, and one the target directory."""
import os
import tempfile
import unittest
from unittest.mock import patch

import check


class OneRun(unittest.TestCase):
    def test_a_second_run_stops_and_names_the_worktrees_and_a_later_one_runs(self):
        with tempfile.TemporaryDirectory() as d, patch.object(check, "WORKTREES", d + "/trees"), patch.object(check, "TARGET_DIR", d + "/target"):
            first = check.one_run_at_a_time()
            with self.assertRaises(SystemExit) as stopped:
                check.one_run_at_a_time()
            self.assertIn("another run is using " + d + "/trees", str(stopped.exception))
            self.assertIn("TMPDIR", str(stopped.exception))
            first.close()
            check.one_run_at_a_time().close()

    def test_a_second_run_with_worktrees_of_its_own_stops_at_a_shared_target_directory(self):
        """Two linked worktrees build in the main checkout's target/ (#453): a
        TMPDIR of its own gives a second run other worktrees and the same
        builds and same-code records."""
        with tempfile.TemporaryDirectory() as d, patch.object(check, "TARGET_DIR", d + "/target"):
            with patch.object(check, "WORKTREES", d + "/one/trees"):
                os.makedirs(d + "/one")
                first = check.one_run_at_a_time()
            with patch.object(check, "WORKTREES", d + "/two/trees"):
                os.makedirs(d + "/two")
                with self.assertRaises(SystemExit) as stopped:
                    check.one_run_at_a_time()
                self.assertIn("another run is building in " + d + "/target", str(stopped.exception))
                self.assertIn(d + "/target/mutants.lock", str(stopped.exception))
                self.assertIn("CARGO_TARGET_DIR", str(stopped.exception))
                # the stopped run gave its own worktrees up again: a third run there gets as far
                with self.assertRaises(SystemExit) as again:
                    check.one_run_at_a_time()
                self.assertIn("building in", str(again.exception))
                first.close()
                check.one_run_at_a_time().close()

    def test_a_run_with_a_target_directory_of_its_own_runs_beside_another(self):
        with tempfile.TemporaryDirectory() as d:
            os.makedirs(d + "/one"), os.makedirs(d + "/two")
            with patch.object(check, "WORKTREES", d + "/one/trees"), patch.object(check, "TARGET_DIR", d + "/one/target"):
                first = check.one_run_at_a_time()
            with patch.object(check, "WORKTREES", d + "/two/trees"), patch.object(check, "TARGET_DIR", d + "/two/target"):
                second = check.one_run_at_a_time()
            first.close(), second.close()


if __name__ == "__main__":
    unittest.main()
