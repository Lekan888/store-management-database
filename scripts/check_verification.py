"""Turn the read-only MySQL verification report into a failing process exit."""
import argparse
import sys


def validate_report(text, expected_count):
    rows = [line.split("\t") for line in text.splitlines() if line.strip()]
    if not rows or len(rows[0]) != 2 or rows[0][0] in ("", "NULL") or not rows[0][1]:
        raise ValueError("Missing selected-database/server-version row")
    checks = rows[1:]
    if len(checks) != expected_count:
        raise ValueError(f"Expected {expected_count} checks, received {len(checks)}")
    names = set()
    failed = []
    for row in checks:
        if len(row) != 4:
            raise ValueError("Malformed verification row")
        name, expected, actual, result = row
        if not name or name in names:
            raise ValueError(f"Missing or duplicate check name: {name}")
        names.add(name)
        if result not in ("PASS", "FAIL"):
            raise ValueError(f"Unknown result for {name}: {result}")
        if result != "PASS" or expected != actual:
            failed.append(f"{name}: expected {expected}, received {actual} ({result})")
    if failed:
        raise ValueError("; ".join(failed))
    return len(checks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expected-count", required=True, type=int)
    args = parser.parse_args()
    if args.expected_count <= 0:
        parser.error("--expected-count must be positive")
    try:
        count = validate_report(sys.stdin.read(), args.expected_count)
    except ValueError as exc:
        print(f"Verification failed: {exc}", file=sys.stderr)
        return 1
    print(f"All {count} verification checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
