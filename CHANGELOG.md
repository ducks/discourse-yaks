# Changelog

## Unreleased

### Added

- Member wallets now show their Yak-tive perks, where each perk applies, its
  purchased quantity, and its remaining duration.

## 20260808 — Alpha

This is the first release intended for testing outside the original development environment.

### Included

- Earn-only, non-monetary Yak wallets with an auditable transaction history.
- Configurable rewards for replies, topics, received likes, and accepted solutions.
- Daily event caps, trust-level requirements, minimum content lengths, and idempotent reward events.
- Server-priced post highlights, topic pins and boosts, custom titles, and custom avatar flair.
- Transactional spending with non-negative balances, target authorization, duplicate-use prevention, and expiration cleanup.
- Staff economy statistics, grants with staff-action logging, and controls for perk prices and earning rules.

### Alpha boundaries

- Install on a staging or test site first.
- Paid Yak packages are deferred until beta while the earned-currency economy is tuned.
- Post pinning and post boosting remain disabled because their effects are not implemented.
- HTTP endpoints and stored feature data are not stable APIs yet.
- Browser coverage and compatibility testing beyond a current Discourse checkout remain incomplete.

See [README.md](README.md) for installation and operation, and [TODO.md](TODO.md) for the roadmap.
