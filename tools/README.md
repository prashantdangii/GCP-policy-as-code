# Tools

| Package | Command |
|---|---|
| `plan_checker` | `python -m plan_checker.cli tfplan.json --fail-on high` |
| `drift_scanner` | `python -m drift_scanner.cli --input fixture.json --format md` |
| `policy_demo` | `python -m policy_demo` |

Install from `requirements.txt`. Tests live next to each package. Coverage on both `rules.py` files is required to stay at or above 90%.
