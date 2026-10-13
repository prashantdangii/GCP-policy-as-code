# 30-logging

Aggregated audit export plus Data Access audit logs.

## Destinations

- BigQuery dataset `audit_logs` in `logging-hub`. `default_table_expiration_ms` defaults to 365 days. Logging creates partitioned destination tables when it writes the sink; the dataset expiration is the cost cap if a table is abandoned.
- Cloud Storage archive with a retention policy. `lock_retention` defaults to false because locking cannot be undone.
- `_Default` log bucket retention defaults to 30 days. That bucket is the in-project copy, not the archive.

The sink resource follows `scope_type`. Organization and folder sinks set `include_children = true`. Project sinks cannot.

## Audit logs

`allServices` gets `ADMIN_READ`, `DATA_READ`, and `DATA_WRITE`. Admin Activity logs are already on and cannot be disabled. Data Access logs are off until this config exists, and they are the expensive ones.

`audit_exempted_members` drops DATA_READ and DATA_WRITE for those members only. Use it for a noisy system identity after you know which method dominates the bill. Do not exempt humans to hide activity.

## Exclusions

`exclusion_filters` is empty by default. An exclusion is invisible later. Add one only with a name, a filter, and a description of the cost you measured. The queries in `queries/bigquery` assume the export is complete unless you document an exclusion.

## Writer identity

The sink's writer identity receives `roles/bigquery.dataEditor` on the dataset and `roles/storage.objectCreator` on the archive. It does not get project Editor.
