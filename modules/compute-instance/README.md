# compute-instance

Secure-by-default VM.

| Control | Default |
| --- | --- |
| External IP | none |
| Shielded VM | secure boot, vTPM, integrity monitoring |
| OS Login | `enable-oslogin=TRUE` |
| Project-wide SSH keys | blocked |
| Serial port | off |
| Service account | required, and the default Compute SA is rejected |
| Boot disk CMEK | optional |
| Labels | `owner`, `env`, `cost-center` |

## Override

`allow_external_ip = true` requires `justification`. Org policy `compute.vmExternalIpAccess` and the Sentinel rule still deny a public IP unless an approved exception exists.

Cloud-platform scope is set because the instance uses a dedicated service account. Privilege is limited by the IAM roles on that account, not by the legacy scope list.
