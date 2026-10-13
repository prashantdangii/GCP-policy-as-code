# gcs-bucket

Secure-by-default Cloud Storage bucket.

| Control | Default |
| --- | --- |
| Uniform bucket-level access | `true` (not configurable) |
| Public access prevention | `enforced` |
| Versioning | on |
| CMEK | optional `kms_key_name` |
| Labels | `owner`, `env`, `cost-center` required |
| Location | must be in `allowed_locations` |
| Retention | optional, lock requires a period |
| Access logs | optional `log_bucket` |

## Override

`allow_public_access = true` sets public access prevention to `inherited` and requires `justification`. CI policies still deny a bucket that is not `enforced`.

## Example

`examples/basic`.
