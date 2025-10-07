# Claude Context for Discourse Yaks

Context and important decisions for AI assistants working on this project.

## Project Overview

This is a Discourse plugin implementing a virtual currency system called "Yaks" (a playful pun on "yakking" and "yak shaving"). Users earn and spend Yaks on premium features like post highlighting, pinning, custom flair, and post boosting.

**Core concept**: Virtual currency stored in user wallets, spent through a service layer that applies visual/functional effects to posts. All transactions are logged for complete audit trail.

## Key Design Decisions

### Why a Service Layer?

Business logic for applying features is extracted to `YakFeatureService` instead of living in models or controllers:
- Validates user can afford feature
- Handles atomic wallet debit + feature application
- Calculates expiration times
- Updates post custom fields
- Returns structured result (success/error)

This keeps controllers thin and makes testing easier.

### Transaction Types

Five transaction types tracked in `YakTransaction`:
1. **earn** - User earns Yaks (quality posts, admin grants)
2. **spend** - User spends Yaks on features
3. **purchase** - User buys Yaks with real money
4. **refund** - Refund of previous spend
5. **admin_grant** - Admin manually gives Yaks

Each transaction stores:
- Amount (negative for debits)
- Source (e.g., "feature_post_highlight", "stripe_purchase")
- Description (human-readable)
- Metadata (JSON for flexible data)
- Related post/topic IDs (optional)

### Custom Fields Pattern

Feature state stored in `post.custom_fields["yak_features"]` as JSON:

```ruby
{
  "highlight" => {
    "enabled" => true,
    "color" => "gold",
    "applied_at" => 1704672000
  },
  "pinned" => {
    "enabled" => true,
    "applied_at" => 1704672000
  }
}
```

**CRITICAL**: Custom fields MUST be registered in `plugin.rb` or they won't save:

```ruby
register_post_custom_field_type("yak_features", :json)
```

Forgot to register? Data silently won't persist. Always check `plugin.rb` first when custom fields don't work.

### Modern Discourse API Pattern

**ALWAYS use modern APIs**. The plugin now uses `api.decorateCookedElement()` for applying CSS classes to posts:

```javascript
api.decorateCookedElement(
  (element, helper) => {
    const post = helper.getModel();
    const yakFeatures = post.yak_features;
    if (!yakFeatures) return;

    // CRITICAL: element.closest("article") often returns null!
    // The .cooked div isn't attached to the article yet when decorator runs
    let article = element.closest("article");

    if (!article) {
      // Wait for DOM to be ready, then query by data-post-id
      requestAnimationFrame(() => {
        article = document.querySelector(`article[data-post-id="${post.id}"]`);
        if (!article) return;

        // Apply classes here
        article.classList.add("yak-highlighted-post");
      });
      return;
    }

    // If article found immediately, apply classes
    article.classList.add("yak-highlighted-post");
  },
  { id: "yak-post-decorations" }
);
```

**DO NOT** use deprecated patterns:
- ❌ `api.decorateWidget()` - Old widget API (causes deprecation warnings)
- ❌ `api.modifyClass()` - Avoid unless absolutely necessary
- ✅ `api.decorateCookedElement()` - Modern, recommended approach

**CRITICAL DOM Timing Issue**: The `element` passed to `decorateCookedElement` is the `.cooked` div, but it's not yet attached to the `<article>` element when the callback runs. Always use the pattern above with `requestAnimationFrame` + `document.querySelector` to find the article by `data-post-id`.

### Denormalized Balance

User balance stored in TWO places:
1. **`yak_wallets.balance`** - Source of truth
2. **`users.yak_balance`** (via method) - Cached for quick lookups

Pattern for accessing balance:
```ruby
# Fast (cached)
current_user.yak_balance

# Always accurate
YakWallet.for_user(current_user).balance
```

Update both when balance changes (wallet handles this automatically).

### Atomic Transactions

Wallet operations use database transactions to ensure consistency:

```ruby
def spend_yaks(amount, feature_key, description, options = {})
  transaction do
    decrement!(:balance, amount)
    increment!(:lifetime_spent, amount)
    yak_transactions.create!(...)
  end
end
```

If ANY step fails, entire operation rolls back. No partial debits.

## Architecture

### Models

**YakWallet** (`app/models/yak_wallet.rb`)
- One per user
- Tracks: balance, lifetime_earned, lifetime_spent
- Methods: `add_yaks`, `spend_yaks`, `refund_transaction`
- Validation: Balance cannot go negative

**YakTransaction** (`app/models/yak_transaction.rb`)
- Immutable audit log
- Every balance change creates a transaction
- Scopes: `by_type`, `by_user`, `recent_first`
- Links to related posts/topics when applicable

**YakFeature** (`app/models/yak_feature.rb`)
- Defines available features (highlight, pin, flair, boost)
- Cost, category, settings (duration, defaults)
- Seeded on plugin enable via `seed_default_features`
- Scope: `enabled`, `by_category`

**YakFeatureUse** (`app/models/yak_feature_use.rb`)
- Tracks applied features
- Links: user, feature, transaction, post, topic
- Expiration tracking
- Scopes: `active`, `expired`, `for_post`, `by_feature`

### Service Layer

**YakFeatureService** (`app/services/yak_feature_service.rb`)

Single entry point for applying features. Handles:
1. Feature lookup and validation
2. Affordability check
3. Duplicate prevention (one highlight per user per post)
4. Wallet debit
5. Feature effect application (update post custom fields)
6. Expiration calculation

**Always use the service** - Don't directly manipulate wallets or custom fields from controllers.

### Controllers

**YaksController** (`app/controllers/yaks_controller.rb`)
- User-facing endpoints
- `/yaks` - View balance and features
- `POST /yaks/spend` - Purchase and apply feature
- `POST /yaks/purchase` - Buy Yaks (stub for now)

**Admin::YaksController** (`app/controllers/admin/yaks_controller.rb`)
- Admin-only endpoints
- `GET /admin/plugins/yaks/stats` - System stats
- `POST /admin/plugins/yaks/give` - Grant Yaks to users
- `GET /admin/plugins/yaks/transactions` - Transaction history
- `POST/PUT /admin/plugins/yaks/features` - Manage features

Both inherit from `ApplicationController`, use Guardian for permissions.

## Important Patterns

### Custom Field Registration

All custom fields declared in `plugin.rb`:

```ruby
# 1. Register the type
register_post_custom_field_type("yak_features", :json)

# 2. Allow field in topic view (REQUIRED for serialization)
topic_view_post_custom_fields_allowlister do |user, topic|
  ["yak_features"]
end

# 3. Expose to serializer with include condition
add_to_serializer(
  :post,
  :yak_features,
  include_condition: -> { object.custom_fields["yak_features"].present? }
) do
  object.custom_fields["yak_features"]
end
```

**CRITICAL**: Without `topic_view_post_custom_fields_allowlister`, the custom field won't be loaded in topic view context and the serializer won't include it in JSON responses. This is the #1 reason custom fields don't appear in the frontend.

**DO NOT** try to use `add_preloaded_post_custom_field` - this method doesn't exist in modern Discourse.

### Frontend Decoration

JavaScript files under `assets/javascripts/discourse/initializers/` are auto-included. No need to call `register_asset`.

Pattern for initializers:

```javascript
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.14.0", (api) => {
  api.decorateCookedElement(
    (element, helper) => {
      // Your decoration logic
    },
    { id: "unique-decorator-id" }
  );
});
```

### Spending Flow

1. User clicks "Spend Yaks" button (frontend, TODO)
2. POST to `/yaks/spend` with `feature_key`, `post_id`, `feature_data`
3. Controller calls `YakFeatureService.apply_feature`
4. Service validates, debits wallet, applies effects
5. Returns success + new balance OR error message
6. Frontend updates UI (decorators pick up custom field changes)

## Testing

### Running Tests

```bash
# All plugin tests
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec

# Specific test file
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec/models/yak_wallet_spec.rb

# Specific test
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec/models/yak_wallet_spec.rb:42
```

### Test Patterns

**Models**: Focus on business logic, validations, scopes
```ruby
fab!(:user) { Fabricate(:user) }
fab!(:wallet) { Fabricate(:yak_wallet, user: user) }

it "debits wallet when spending" do
  expect { wallet.spend_yaks(10, "highlight", "Test") }
    .to change { wallet.balance }.by(-10)
end
```

**Services**: Test full flows, edge cases, atomicity
```ruby
it "applies highlight feature to post" do
  result = YakFeatureService.apply_feature(
    user,
    "post_highlight",
    related_post: post,
    feature_data: { color: "gold" }
  )

  expect(result[:success]).to be true
  expect(post.reload.custom_fields["yak_features"]["highlight"]).to be_present
end
```

**Controllers**: Request specs (TODO)
```ruby
it "spends Yaks on feature" do
  post "/yaks/spend.json", params: {
    feature_key: "post_highlight",
    post_id: post.id,
    color: "gold"
  }

  expect(response.status).to eq(200)
  expect(user.reload.yak_balance).to eq(975)
end
```

### Fabricators

Located in `spec/fabricators/yak_fabricators.rb`:

```ruby
fab!(:wallet) { Fabricate(:yak_wallet, user: user, balance: 1000) }
fab!(:feature) { Fabricate(:yak_feature, feature_key: "post_highlight", cost: 25) }
fab!(:transaction) { Fabricate(:yak_transaction, user: user, wallet: wallet) }
```

Use `fab!()` over `let()` for performance (CLAUDE.md guideline).

## Gotchas and Sharp Edges

### JavaScript Auto-Include

**Error**: "Javascript files under `assets/javascripts` are automatically included"

**Cause**: Tried to manually `register_asset "javascripts/discourse/..."` in `plugin.rb`

**Fix**: Remove the `register_asset` line. Discourse auto-includes JavaScript files.

### Deprecated Widget API

**Warning**: "Plugin contains code which needs updating (id:discourse.post-stream-widget-overrides)"

**Cause**: Using old `api.decorateWidget()` pattern

**Fix**: Rewrite using `api.decorateCookedElement()`:

```javascript
// ❌ OLD (deprecated)
api.decorateWidget("post-contents:after-cooked", ...)

// ✅ NEW (modern)
api.decorateCookedElement((element, helper) => { ... })
```

### Custom Fields Not Saving

**Symptom**: `post.custom_fields["yak_features"]` returns nil after saving

**Causes**:
1. Forgot to register field type in `plugin.rb`
2. Forgot to call `post.save_custom_fields` (not `post.save`)
3. Typo in field name (case-sensitive)

**Fix**:
```ruby
# In plugin.rb
register_post_custom_field_type("yak_features", :json)

# In code
post.custom_fields["yak_features"] = data
post.save_custom_fields  # NOT post.save
```

### Negative Amounts in Transactions

Debits are stored as negative amounts:
- Earn: `+50`
- Spend: `-25`
- Refund: `+25` (reverses a spend)

The `YakWallet` methods handle this - `spend_yaks` negates the amount automatically:

```ruby
# Correct
wallet.spend_yaks(25, "highlight", "Purchase")  # Stores -25

# Wrong - don't negate yourself
wallet.spend_yaks(-25, "highlight", "Purchase")  # Will fail validation
```

### Missing Serializer Include

**Symptom**: `post.yak_features` undefined in JavaScript

**Cause**: Forgot to add serializer in `plugin.rb`

**Fix**:
```ruby
add_to_serializer(:post, :yak_features) do
  object.custom_fields["yak_features"]
end
```

## File Guide

```
plugins/discourse-yaks/
├── plugin.rb                           # Main plugin registration, routes, serializers
├── config/
│   ├── settings.yml                    # Site settings (costs, rates, toggles)
│   └── locales/
│       ├── en.yml                      # Server-side translations
│       └── client.en.yml               # Client-side translations
├── db/migrate/
│   └── 20250103000001_create_yak_system.rb  # Database schema
├── app/
│   ├── models/
│   │   ├── yak_wallet.rb               # Wallet balance and transactions
│   │   ├── yak_transaction.rb          # Immutable transaction log
│   │   ├── yak_feature.rb              # Feature definitions
│   │   └── yak_feature_use.rb          # Applied feature tracking
│   ├── services/
│   │   └── yak_feature_service.rb      # Business logic for applying features
│   └── controllers/
│       ├── yaks_controller.rb          # User endpoints
│       └── admin/yaks_controller.rb    # Admin endpoints
├── assets/
│   ├── javascripts/discourse/
│   │   └── initializers/
│   │       └── yak-post-decorations.js # Frontend decorators (CSS classes)
│   └── stylesheets/
│       └── yaks.scss                   # Feature styling (borders, backgrounds)
├── spec/
│   ├── models/                         # Model specs (full coverage)
│   ├── services/                       # Service specs (full coverage)
│   └── fabricators/yak_fabricators.rb  # Test data factories
├── README.md                           # User-facing documentation
└── CLAUDE.md                           # This file (AI assistant context)
```

## Development Workflow

### Server Restart Requirements

**CRITICAL**: After making plugin changes, you must restart servers:

```bash
# 1. Restart Rails server (port 3000)
# Stop with Ctrl+C, then:
bin/rails s

# 2. Restart Ember CLI dev server (port 4200)
# Stop with Ctrl+C, then:
bin/ember-cli
```

**When to restart**:
- ✅ After editing `plugin.rb` (routes, serializers, settings)
- ✅ After editing Ruby models, controllers, services
- ✅ After editing JavaScript initializers or components
- ✅ After running migrations
- ✅ After editing SCSS files
- ❌ Only need to reload browser for HTML template changes

**Common symptom**: "Why isn't my change showing up?" → You forgot to restart the server.

### Adding a New Feature

1. **Add to seed data** in `YakFeature.seed_default_features`:
```ruby
{
  feature_key: "new_feature",
  feature_name: "New Feature",
  description: "What it does",
  cost: 50,
  category: "post",
  settings: { duration_hours: 48 }
}
```

2. **Add effect handler** in `YakFeatureService.apply_feature_effects`:
```ruby
when "new_feature"
  current_features["new_feature"] = { enabled: true, applied_at: Time.zone.now.to_i }
```

3. **Add CSS styling** in `assets/stylesheets/yaks.scss`:
```scss
.yak-new-feature-post {
  border: 2px solid blue;
}
```

4. **Add decorator logic** in `yak-post-decorations.js`:
```javascript
if (yakFeatures.new_feature?.enabled) {
  article.classList.add("yak-new-feature-post");
}
```

5. **Write tests** for the new feature flow

### Testing a Feature End-to-End

```ruby
# In Rails console
user = User.first
wallet = YakWallet.for_user(user)
wallet.add_yaks(1000, "test", "Testing funds")

post = Post.first
result = YakFeatureService.apply_feature(
  user,
  "post_highlight",
  related_post: post,
  feature_data: { color: "gold" }
)

puts result.inspect
puts post.reload.custom_fields["yak_features"].inspect
```

Then view the post in browser - should see gold border.

### Debugging Custom Fields

```ruby
# Check registration
puts PluginStore.get("discourse-yaks", "registered_fields")

# Check post custom fields
post = Post.find(123)
puts post.custom_fields.inspect
puts post.custom_fields["yak_features"].inspect

# Force reload
post.reload
post.custom_fields(true)  # Force reload custom fields
```

## Common Issues

**Issue**: Decorator not applying classes
- Check browser console for JS errors
- Verify `post.yak_features` is present in serializer output (check Network tab, look for `.json` requests)
- Check if `article` element found - **use `requestAnimationFrame` + `document.querySelector`**, not just `element.closest("article")`
- Verify both Rails and Ember CLI servers were restarted after code changes

**Issue**: Custom fields in database but not in JSON response
- **Most likely**: Forgot `topic_view_post_custom_fields_allowlister` in `plugin.rb`
- Check serializer is registered with `add_to_serializer`
- Restart Rails server after changes
- Test in Rails console: `PostSerializer.new(post, scope: Guardian.new(user), root: false).as_json`

**Issue**: Features not appearing after purchase
- Check wallet balance changed: `user.reload.yak_balance`
- Check transaction created: `YakTransaction.last`
- Check custom field saved: `post.reload.custom_fields["yak_features"]`
- Check decorator ran: Inspect DOM for CSS classes

**Issue**: Tests failing with "Database error"
- Make sure migrations ran: `LOAD_PLUGINS=1 bin/rake db:migrate`
- Check test database: `RAILS_ENV=test LOAD_PLUGINS=1 bin/rake db:migrate`

## Site Settings

Configured in `config/settings.yml`:

- `yaks_enabled` - Master toggle
- `yaks_dollar_to_yak_rate` - Exchange rate (default: 20 Yaks per $1)
- `yaks_earning_enabled` - Allow earning through posts
- `yaks_min_likes_for_reward` - Threshold for earning
- `yaks_max_reward_per_post` - Cap per post

Access in code:
```ruby
SiteSetting.yaks_enabled
SiteSetting.yaks_dollar_to_yak_rate
```

## Future Enhancements

### Frontend UI (High Priority)
- Yak balance display in user menu
- "Spend Yaks" button on posts
- Feature purchase modal with options
- Transaction history page
- Wallet management page

### Earning System (Medium Priority)
- Background job to detect quality posts
- Automatic Yak rewards based on likes
- Milestone rewards (badges integration)

### Payment Integration (Medium Priority)
- Replace stub with Stripe integration
- Webhook handlers
- Receipt emails
- Refund processing

### Advanced Features (Low Priority)
- Topic highlighting
- Custom avatar frames
- Priority support badges
- Marketplace for user-created features

## Performance Considerations

- **Balance lookups**: Denormalized in `User` model for speed
- **Transaction queries**: Indexed on `user_id`, `created_at`, `transaction_type`
- **Feature lookups**: Indexed on `feature_key`
- **Custom fields**: JSONB in PostgreSQL, efficient queries
- **Caching**: Not implemented yet, but serializer output could be cached

## Security

- **Authentication**: All spending requires logged-in user
- **Authorization**: Guardian classes (to be implemented)
- **Atomicity**: Database transactions prevent race conditions
- **Validation**: Server-side validation on all inputs
- **Audit trail**: Complete transaction history
- **Admin logging**: `StaffActionLogger` for admin actions

## Knowledge Sharing

Per project guidelines, always persist important decisions:
- Document new features in README.md
- Update this file (CLAUDE.md) with patterns and gotchas
- Write inline comments for non-obvious code
- Add JSDoc for all classes and methods
- Keep test coverage high

## Version History

**0.1.0** (Current)
- Core wallet system implemented
- Four default features defined
- Service layer for applying features
- Post highlighting fully functional
- Modern Discourse API patterns
- Full test coverage on models and services
- Frontend decorators working
- Admin endpoints (basic)

**Next**: Frontend UI, earning system, payment integration
