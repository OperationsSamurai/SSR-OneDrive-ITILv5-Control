# Security Policy

Co-authored by Microsoft 365 Copilot - Derek's Subscription

## Rules

Do not commit:

- GitHub tokens
- passwords
- OneDrive authentication tokens
- app passwords
- private keys
- environment secrets
- credential exports

## If a Secret Is Exposed

1. Revoke it immediately.
2. Rotate the credential.
3. Remove the exposure.
4. Commit the correction.
5. Document the correction in CHANGELOG.md.

## Incident Rule

If any check reports:

```text
FAIL > 0
```

treat it as an incident.

Co-authored by Microsoft 365 Copilot - Derek's Subscription
