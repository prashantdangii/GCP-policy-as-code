# drift_scanner

Offline mode reads a JSON inventory (`--input`) so tests never call Google. Live mode uses Cloud Asset Inventory `search_all_resources` and `search_all_iam_policies` when you pass `--scope`. Findings carry a catalog id. `preventive_gap` is true only when no plan-time or org-policy control exists yet. NET-002 is that gap. IAM-003 is the closed loop.
