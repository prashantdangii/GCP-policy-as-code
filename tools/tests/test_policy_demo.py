"""Assert the committed plan fixtures keep the documented violation set."""

from policy_demo import COMPLIANT, EXPECTED_BAD, NONCOMPLIANT, pairs


def test_committed_plans_match_the_demo_contract() -> None:
    assert pairs(COMPLIANT) == set()
    assert pairs(NONCOMPLIANT) == EXPECTED_BAD
