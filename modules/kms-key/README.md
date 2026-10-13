# kms-key

Key ring and crypto key with a 90-day rotation ceiling and `prevent_destroy`.

`admin_member` receives `roles/cloudkms.admin`. `user_member` receives `roles/cloudkms.cryptoKeyEncrypterDecrypter`. Validation rejects using the same principal for both, so a key administrator cannot also be the workload that encrypts data.

Rotation faster than one day is rejected because KMS will not accept it. Rotation slower than 90 days is rejected by this module.
