# Discourse Yaks

Discourse Yaks is an experimental, non-monetary community currency plugin. Members earn Yaks through participation and spend them on temporary forum perks. Yaks cannot be purchased with real money.

> **Alpha software:** test this plugin on a staging site before enabling it in production. Economy defaults and compatibility may change as the plugin is exercised by more communities.

## Features

Members can:

- earn Yaks by creating posts and topics, receiving likes, and having solutions accepted when discourse-solved is installed;
- view their balance, lifetime totals, and recent transactions at `/yaks`;
- highlight one of their posts;
- temporarily pin or globally boost one of their topics;
- apply a temporary custom title or avatar flair.

Staff can:

- view economy statistics;
- grant Yaks to a member, with the grant recorded by `StaffActionLogger`;
- change the cost, duration, and availability of implemented perks;
- configure earning amounts, daily event caps, and minimum trust levels.

Post pinning and post boosting are present as disabled data records but are not implemented. Arbitrary custom feature keys are not supported.

## Installation

Add the plugin to your container's `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/ducks/discourse-yaks.git
```

Rebuild the container, then enable `yaks_enabled` in Admin → Settings → Plugins. Automatic earning can be independently disabled with `yaks_earning_enabled`.

The plugin declares Discourse 3.4.0 as its minimum version. Alpha development and verification are performed against a current Discourse checkout.

## How it works

Earning events are idempotent and serialized per wallet. Each earning rule can require a trust level and content length and can cap the number of rewarded events per day. A new topic is rewarded only through the topic rule; its first post does not also receive the ordinary post reward.

Spending is performed inside database transactions with wallet and target locking. The server owns feature prices, validates target ownership and visibility, allowlists feature options, and prevents concurrent duplicate applications. Temporary effects are removed by scheduled jobs. Topic expiration restores the prior pin state when it has not subsequently been changed by staff.

Quantity purchases extend duration at the same multiple of the feature cost, up to 12 units. The custom-title and custom-flair interfaces expose quantity selection; contextual post and topic controls currently apply one unit at a time.

## HTTP endpoints

These endpoints are used by the plugin UI. They are not a stable public API during alpha.

Member endpoints, requiring login:

- `GET /yaks.json` — wallet, transaction history, and profile perks
- `GET /yaks/catalog.json` — enabled server-priced perk catalog
- `POST /yaks/spend.json` — validate, purchase, and apply a perk

Staff endpoints:

- `GET /admin/plugins/yaks/stats.json`
- `POST /admin/plugins/yaks/give.json`
- `GET /admin/plugins/yaks/transactions.json`
- `GET /admin/plugins/yaks/features.json`
- `PUT /admin/plugins/yaks/features/:id.json`
- `GET /admin/plugins/yaks/earning_rules.json`
- `PUT /admin/plugins/yaks/earning_rules/:id.json`

## Development

Install this repository at `plugins/discourse-yaks` in a Discourse development checkout, then run:

```bash
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec
```

Standalone formatting and frontend checks are available after installing the repository dependencies:

```bash
bundle exec rubocop
pnpm lint
```

See [SETUP.md](SETUP.md) for local setup notes and [TODO.md](TODO.md) for the alpha roadmap.

## Alpha limitations

- Economy defaults need community testing and tuning.
- Browser-level tests and broader version compatibility testing remain to be added.
- Rewards are not clawed back when previously rewarded content is later removed.
- Post pinning and post boosting remain disabled until their effects are implemented.
- HTTP endpoints and stored feature data may change before a stable release.

Please report reproducible problems through [GitHub Issues](https://github.com/ducks/discourse-yaks/issues).

## License

GNU General Public License version 2.0 or later (`GPL-2.0-or-later`). See [LICENSE](LICENSE) and [LICENSE-NOTICE](LICENSE-NOTICE).
