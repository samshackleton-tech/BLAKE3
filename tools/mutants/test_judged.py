"""judged.py's join, on lists made here (no cargo, no build)."""
import importlib.util, os, tempfile, unittest

spec = importlib.util.spec_from_file_location("judged", os.path.join(os.path.dirname(os.path.abspath(__file__)), "judged.py"))
judged = importlib.util.module_from_spec(spec)
spec.loader.exec_module(judged)

SAME = "same code: every test binary hashes as the unmutated build's here (tools/mutants/code_hash.py)"


def lists(**rows):
    """{arch: (files, known, timed)} from arch=(files, [(file, mutant, places, reason)], [time-out rows])."""
    out = {}
    for arch, (files, known, timed) in rows.items():
        k, t = {}, {}
        for table, source in ((k, known), (t, timed)):
            for file, mutant, n, reason in source:
                m = judged.CONDITION.match(reason)
                table.setdefault((file, mutant), []).append((n, (m.group(1), m.group(2)) if m else None, m.group(3) if m else reason))
        out[arch] = (files, k, t)
    return out


def listed(*names):
    return [f"{file}:{10 + i}:5: {mutant}" for i, (file, mutant) in enumerate(names)]


class Judged(unittest.TestCase):
    def nowhere(self, names, ls):
        return judged.join(listed(*names), ls)[2]

    def test_a_mutant_no_list_names_is_caught_where_its_file_is_mutated(self):
        ls = lists(x86_64=(["src/a.rs"], [], []), aarch64=(["src/a.rs"], [("src/a.rs", "m", 1, SAME)], []))
        self.assertEqual(self.nowhere([("src/a.rs", "m")], ls), [])

    def test_the_same_code_on_every_platform_is_judged_nowhere(self):
        ls = lists(x86_64=(["src/a.rs"], [("src/a.rs", "m", 1, SAME)], []), aarch64=(["src/a.rs"], [("src/a.rs", "m", 1, SAME)], []),
                   arm64=(["src/b.rs"], [], []))                                          # the Mac does not mutate the file at all
        places, says, nowhere = judged.join(listed(("src/a.rs", "m")), ls)
        self.assertEqual(nowhere, [("src/a.rs", "m")])
        self.assertEqual(says[("src/a.rs", "m")], {"x86_64": "same code", "aarch64": "same code", "arm64": "not mutated"})

    def test_a_reason_on_one_platform_is_a_judgement(self):
        ls = lists(x86_64=(["src/a.rs"], [("src/a.rs", "m", 1, SAME)], []), aarch64=(["src/a.rs"], [("src/a.rs", "m", 1, "equivalent: | and ^ agree on bits that never overlap")], []))
        self.assertEqual(self.nowhere([("src/a.rs", "m")], ls), [])

    def test_a_row_written_from_another_platforms_is_what_that_one_says(self):
        as_same = f"as on x86_64: survives (known-x86_64.txt): {SAME}"
        ls = lists(x86_64=(["src/a.rs"], [("src/a.rs", "m", 1, SAME)], []), aarch64=(["src/a.rs"], [("src/a.rs", "m", 1, as_same)], []))
        self.assertEqual(self.nowhere([("src/a.rs", "m")], ls), [("src/a.rs", "m")])
        as_reasoned = "as on x86_64: survives (known-x86_64.txt): test-only code (cfg(test))"
        self.assertEqual(judged.kind_of(as_reasoned), "reasoned")
        self.assertEqual(judged.kind_of(as_same + "; on arm64: survives (known-arm64.txt): " + SAME), "same")

    def test_unclassified_and_open_rows_judge_nothing(self):
        for reason in ("UNCLASSIFIED", "OPEN: the pool's scheduling under interleavings the tests leave to chance (#103)", "UNCLASSIFIED (the clock stopped: a_test)"):
            ls = lists(x86_64=(["src/a.rs"], [("src/a.rs", "m", 1, reason)], []))
            self.assertEqual(self.nowhere([("src/a.rs", "m")], ls), [("src/a.rs", "m")], reason)

    def test_a_time_out_with_its_reason_is_a_judgement_and_one_without_is_not(self):
        why = "a worker spins while a stream is open: the tests that wait for every worker parked never end"
        ls = lists(x86_64=(["src/a.rs"], [], [("src/a.rs", "m", 1, why)]))
        self.assertEqual(self.nowhere([("src/a.rs", "m")], ls), [])
        ls = lists(x86_64=(["src/a.rs"], [], [("src/a.rs", "m", 1, "UNCLASSIFIED (the clock stopped: a_test)")]))
        self.assertEqual(self.nowhere([("src/a.rs", "m")], ls), [("src/a.rs", "m")])

    def test_a_place_the_list_does_not_count_is_caught(self):
        # the change is at three places of the function; the list knows two as the same code: the third is caught
        names = [("src/a.rs", "m")] * 3
        ls = lists(x86_64=(["src/a.rs"], [("src/a.rs", "m", 2, SAME)], []))
        self.assertEqual(self.nowhere(names, ls), [])
        ls = lists(x86_64=(["src/a.rs"], [("src/a.rs", "m", 3, SAME)], []))
        self.assertEqual(self.nowhere(names, ls), [("src/a.rs", "m")])

    def test_rows_for_some_cpus_leave_the_others_to_catch_it(self):
        ls = lists(x86_64=(["src/a.rs"], [("src/a.rs", "m", 1, "[cpu lacks avx512f] " + SAME)], []))
        self.assertEqual(self.nowhere([("src/a.rs", "m")], ls), [])                       # with AVX-512 no row: caught there
        ls = lists(x86_64=(["src/a.rs"], [("src/a.rs", "m", 1, "[cpu lacks avx512f] " + SAME), ("src/a.rs", "m", 1, "[cpu has avx512f] " + SAME)], []))
        self.assertEqual(self.nowhere([("src/a.rs", "m")], ls), [("src/a.rs", "m")])      # the same code with and without

    def test_a_file_no_platform_mutates(self):
        ls = lists(x86_64=(["src/a.rs"], [], []), aarch64=(["src/a.rs"], [], []))
        out = []
        n = judged.report("", listed(("src/a.rs", "m"), ("src/gone.rs", "p"), ("src/gone.rs", "q")), ls, out=out.append)
        self.assertEqual(n, 2)
        self.assertTrue(any("NO PLATFORM MUTATES src/gone.rs: its 2 mutants" in line for line in out), out)

    def test_the_lists_as_files(self):
        with tempfile.TemporaryDirectory() as d:
            with open(os.path.join(d, "known-x86_64.txt"), "w") as f:
                f.write("# a comment\nfiles: src/a.rs src/b.rs\nmodel files: src/b.rs\nsrc/a.rs\treplace + with - in f\t2\t" + SAME + "\n")
            with open(os.path.join(d, "timeouts-x86_64.txt"), "w") as f:
                f.write("files: src/a.rs\nsrc/b.rs\treplace g with ()\t1\tthe wait never returns\n")
            ls = judged.lists_of(d)
            self.assertEqual(sorted(ls), ["x86_64"])
            self.assertEqual(ls["x86_64"][0], ["src/a.rs", "src/b.rs"])
            self.assertEqual(self.nowhere([("src/a.rs", "replace + with - in f")] * 2 + [("src/b.rs", "replace g with ()")], ls), [("src/a.rs", "replace + with - in f")])


if __name__ == "__main__":
    unittest.main()
