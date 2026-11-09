"""Compile disabled model targets once; never omit an executable test target."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import check


class Targets(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def target(self, name, source, required=()):
        path = self.root / (name + ".rs")
        path.write_text(source)
        return {"name": name, "kind": ["test"], "src_path": str(path), "required-features": list(required)}

    def test_only_recognized_whole_crate_gates_are_candidates(self):
        targets = [self.target("ordinary", "#[test]\nfn example() {}\n"),
                   self.target("model", "//! Schedules.\n\n#![cfg(shuttle)]\n#[test]\nfn schedules() {}\n"),
                   self.target("admission", '#![cfg(all(shuttle, feature = "std"))]\n')]
        self.assertEqual(check.model_target_candidates(targets), ["model", "admission"])

    def test_comment_string_nested_or_unfamiliar_attribute_is_not_a_candidate(self):
        texts = ['// #![cfg(shuttle)]\n#[test]\nfn example() {}\n',
                 'const NOTE: &str = "#![cfg(shuttle)]";\n',
                 'mod nested {\n#![cfg(shuttle)]\n}\n',
                 '/* comment */\n#![cfg(shuttle)]\n',
                 '#![allow(dead_code)]\n#![cfg(shuttle)]\n',
                 '#![cfg(any(shuttle, unix))]\n']
        for i, text in enumerate(texts):
            with self.subTest(text=text):
                self.assertEqual(check.model_target_candidates([self.target(f"case{i}", text)]), [])

    def test_feature_gated_candidates_are_kept_without_probing(self):
        self.assertEqual(check.model_target_candidates([self.target("model", "#![cfg(shuttle)]\n", ["new_feature"])]), [])

    def test_only_a_listed_zero_case_suite_is_empty(self):
        suites = {"a": {"binary-name": "model", "status": "listed", "testcases": {}},
                  "b": {"binary-name": "active", "status": "listed", "testcases": {"case": {}}}}
        self.assertEqual(check.empty_model_targets(suites, ["model", "active"]), {"model"})
        self.assertEqual(check.empty_model_targets(suites, ["active"]), set())

    def test_missing_or_skipped_listing_is_a_failure_not_an_empty_suite(self):
        with self.assertRaises(RuntimeError):
            check.empty_model_targets({}, ["model"])
        with self.assertRaises(RuntimeError):
            check.empty_model_targets({"a": {"binary-name": "model", "status": "skipped", "testcases": {}}}, ["model"])

    def test_every_other_target_is_kept_and_cargo_required_features_respected(self):
        targets = [self.target("model", "#![cfg(shuttle)]\n"),
                   self.target("ordinary", "#[test]\nfn example() {}\n"),
                   self.target("future", "#[test]\nfn example() {}\n"),
                   self.target("optional", "", ["zeroize"])]
        self.assertEqual(check.plain_test_targets(targets, {"std"}, {"model"}), ["--lib", "--test", "ordinary", "--test", "future"])
        self.assertIn("optional", check.plain_test_targets(targets, {"std", "zeroize"}, {"model"}))

    def test_target_dependent_compiler_wrappers_keep_the_original_plan(self):
        with patch.dict(os.environ, RUSTC_WORKSPACE_WRAPPER="custom-wrapper"), patch.object(check.subprocess, "run") as run:
            self.assertEqual(check.tests_to_build(False), ["--lib", "--tests"])
            run.assert_not_called()

    def test_failed_probe_is_not_accepted_as_zero_tests(self):
        model = self.target("model", "#![cfg(shuttle)]\n")
        metadata = {"packages": [{"id": "fixture", "manifest_path": str(self.root / "Cargo.toml"), "targets": [model]}]}
        failure = subprocess.CompletedProcess(["cargo", "nextest", "list"], 1)
        with patch.object(check, "ROOT", str(self.root)), patch.object(check, "TARGET_DIR", str(self.root)), \
             patch.dict(os.environ, RUSTC_WRAPPER="", RUSTC_WORKSPACE_WRAPPER=""), \
             patch.object(check.subprocess, "run", side_effect=[subprocess.CompletedProcess([], 0, json.dumps(metadata), ""), failure]):
            with self.assertRaises(subprocess.CalledProcessError):
                check.tests_to_build(False)
        self.assertFalse((self.root / "mutants/model-only-targets.json").exists())
        self.assertTrue((self.root / "mutants/model-only-targets.stdout.json").exists())
        self.assertTrue((self.root / "mutants/model-only-targets.stderr.log").exists())

    def test_model_plan_is_unchanged(self):
        with patch.object(check.subprocess, "run") as run:
            self.assertEqual(check.tests_to_build(True), ["--test", "shuttle_finish", "--test", "shuttle_park"])
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
