# Development setup

Discourse Yaks must be loaded from a Discourse development checkout. Clone or symlink this repository as `plugins/discourse-yaks`, prepare the parent Discourse application normally, and migrate its development and test databases.

Enable `yaks_enabled` from the site settings UI. Default feature and earning-rule records are created by plugin migrations; enabling the plugin also ensures its base feature records exist.

Run the backend suite from the Discourse root:

```bash
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec
```

Run standalone repository checks after installing `Gemfile` and `package.json` dependencies:

```bash
bundle exec rubocop
pnpm lint
```

For a manual smoke test:

1. Enable Yaks and automatic earning.
2. Create a TL1 test member and a post long enough for the configured rule.
3. Confirm the wallet appears at `/yaks` and the earning transaction is listed.
4. Grant enough Yaks from the admin interface to exercise each enabled perk.
5. Apply perks only to content owned by the test member.
6. Verify another member cannot apply a perk to that content.
7. Shorten a perk duration in development and confirm its effect expires cleanly.

The endpoints used by the UI are listed in the README. They are intentionally unstable during alpha.
