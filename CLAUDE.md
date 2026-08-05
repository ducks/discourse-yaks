# Development notes

Start with [README.md](README.md) for the supported behavior and [TODO.md](TODO.md) for the current roadmap. This file intentionally avoids duplicating implementation status so agent instructions do not drift from the public documentation.

Important invariants:

- Yaks are non-monetary and have no purchase endpoint.
- `YakFeature::IMPLEMENTED_FEATURE_KEYS` is the executable feature allowlist.
- Prices and feature options are validated on the server.
- Wallet mutations and their transaction records must commit atomically.
- Spending must lock both the wallet and the affected post, topic, or user.
- Earning events must remain idempotent under retries and concurrent delivery.
- A member may apply perks only to their own visible, eligible content.
- Expiration must not overwrite a later staff change to topic pin state.
- New endpoints require request specs covering authentication and authorization.

Use current Discourse plugin APIs and keep `plugin.rb`, settings, routes, README claims, and tests synchronized when behavior changes.
