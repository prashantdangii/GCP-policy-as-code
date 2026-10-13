# bigquery-dataset

Secure-by-default BigQuery dataset.

Access is granted only to Google groups you list in `authorized_groups`. `allUsers` and `allAuthenticatedUsers` fail validation. CMEK and default table expiration are optional inputs. Required labels match the other modules.

Do not add owner or editor roles through this module. Use a dataset role such as `roles/bigquery.dataViewer`.
