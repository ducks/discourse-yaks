# Roadmap

## Alpha feedback

- Tune default earning amounts, daily event caps, and perk costs using real community behavior.
- Add browser tests for the wallet, contextual spend controls, admin forms, and expiration-visible UI changes.
- Exercise clean installation and upgrades on supported Discourse versions.
- Decide whether rewarded content deletion should trigger a clawback or retain the historical reward.
- Add explicit HTTP throttling if production traffic shows a need beyond transactional wallet locking.

## Candidate features

- Implement the currently disabled post pin and post boost records, or remove them permanently.
- Add admin transaction browsing and filtering to the UI; the read endpoint already exists.
- Add member-facing active-perk status and remaining duration.
- Improve live balance and perk updates without full-page reloads.
- Consider additional earning events only after abuse and idempotency rules are defined.

## Before stable release

- Publish a compatibility matrix.
- Stabilize the HTTP and stored-data contracts.
- Add upgrade tests for historical feature-key and cached-balance migrations.
- Complete an accessibility and localization pass.
- Document backup, uninstall, and data-retention behavior.
