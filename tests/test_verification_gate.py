import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "scripts"))
from check_verification import validate_report


class VerificationGateTests(unittest.TestCase):
    def test_valid_report(self):
        self.assertEqual(validate_report("demo\t8.0.46\nrows\t5\t5\tPASS\n", 1), 1)

    def test_fail_result(self):
        with self.assertRaises(ValueError):
            validate_report("demo\t8.0.46\nrows\t5\t4\tFAIL\n", 1)

    def test_mislabelled_pass(self):
        with self.assertRaises(ValueError):
            validate_report("demo\t8.0.46\nrows\t5\t4\tPASS\n", 1)

    def test_missing_check(self):
        with self.assertRaises(ValueError):
            validate_report("demo\t8.0.46\nrows\t5\t5\tPASS\n", 2)

    def test_duplicate_check(self):
        with self.assertRaises(ValueError):
            validate_report("demo\t8.0.46\nrows\t5\t5\tPASS\nrows\t5\t5\tPASS\n", 2)

    def test_malformed_row(self):
        with self.assertRaises(ValueError):
            validate_report("demo\t8.0.46\nrows\tPASS\n", 1)

    def test_missing_database(self):
        with self.assertRaises(ValueError):
            validate_report("NULL\t8.0.46\nrows\t5\t5\tPASS\n", 1)

    def test_unknown_status(self):
        with self.assertRaises(ValueError):
            validate_report("demo\t8.0.46\nrows\t5\t5\tOK\n", 1)


if __name__ == "__main__":
    unittest.main()
