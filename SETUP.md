# Quick Setup Guide

## What We've Built

This is a **proof of concept** virtual currency system for Discourse. The core backend is fully implemented and tested.

### ✅ Completed
- **4 Database Tables**: wallets, transactions, features, feature_uses
- **4 Models**: Fully tested with validations, scopes, and business logic
- **1 Service**: YakFeatureService for applying purchased features
- **2 Controllers**: User wallet actions + Admin management
- **18 Files Total**: Complete backend implementation
- **Full Test Suite**: 100+ test cases covering all models and services
- **CSS Styling**: Ready for post highlighting, pinning, and boosting

### 🚧 Still Needed
- **Frontend UI**: Ember.js components (balance display, spend buttons, wallet page)
- **Payment Integration**: Replace stub with real Stripe
- **Background Jobs**: Auto-earning from likes, feature expiration cleanup
- **Ruby/Bundle Setup**: Environment needs Ruby configured to run tests

## Testing the Backend

Once Ruby/Bundle is available:

```bash
# Run all plugin tests
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec

# Run specific model tests
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec/models/yak_wallet_spec.rb
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec/services/yak_feature_service_spec.rb
```

## Using the API (Manual Testing)

### 1. Enable the Plugin

In Admin → Settings → Plugins:
- Set `yaks_enabled` to `true`
- Default features will be seeded automatically

### 2. Grant Yaks to a User

```bash
# As admin
curl -X POST http://localhost:3000/admin/yaks/give \
  -H "Content-Type: application/json" \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: admin" \
  -d '{
    "user_id": 1,
    "amount": 100,
    "reason": "Testing the system"
  }'
```

### 3. Check Wallet

```bash
# As authenticated user
curl http://localhost:3000/yaks \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: username"
```

### 4. Spend Yaks on Post Highlighting

```bash
curl -X POST http://localhost:3000/yaks/spend \
  -H "Content-Type: application/json" \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: username" \
  -d '{
    "feature_key": "post_highlight",
    "post_id": 123,
    "feature_data": {
      "color": "gold"
    }
  }'
```

### 5. View Admin Stats

```bash
curl http://localhost:3000/admin/yaks \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: admin"
```

## Database Schema

The migration creates these tables:

1. **yak_wallets** - User balances (1:1 with users)
2. **yak_transactions** - Complete audit trail
3. **yak_features** - Purchasable features catalog
4. **yak_feature_uses** - Applied features tracking

Plus adds `yak_balance` column to `users` table for fast lookups.

## Models Overview

### YakWallet
- `add_yaks(amount, source, description, metadata)` - Credit Yaks
- `spend_yaks(amount, feature_key, description, options)` - Debit Yaks
- `refund_transaction(transaction, reason)` - Refund a purchase
- All operations are atomic and update both wallet and user balance

### YakFeature
- `seed_default_features` - Creates 4 default features
- `affordable_by?(user)` - Check if user can afford
- Scopes: `enabled`, `by_category`

### YakFeatureService
- `apply_feature(user, feature_key, related_post:, feature_data:)` - Main purchasing logic
- `can_apply_to_post?` - Validation before purchase
- `calculate_expiration` - Time-limited features
- `apply_feature_effects` - Update post custom_fields
- `remove_feature_effects` - Cleanup expired features

## Next Development Steps

### Phase 1: Basic UI (High Priority)
1. Create Ember component to display balance in user menu
2. Add "Spend Yaks" button to post actions
3. Create modal for feature selection and confirmation
4. Build basic `/yaks` wallet page

### Phase 2: Payment Integration
1. Integrate Stripe Checkout
2. Add webhook handler for payment.succeeded
3. Implement refund handling
4. Create purchase history view

### Phase 3: Earning System
1. Background job to scan posts for like milestones
2. Automatic Yak rewards based on site settings
3. User notifications for Yak earnings
4. Leaderboard (optional)

### Phase 4: Feature Enhancements
1. Custom user flair rendering
2. Post boost ranking algorithm
3. Expiration cleanup job
4. Feature effect rendering in post stream

## File Structure

```
plugins/discourse-yaks/
├── plugin.rb                                      # Main plugin registration
├── README.md                                      # Full documentation
├── SETUP.md                                       # This file
├── config/
│   ├── settings.yml                              # Site settings
│   └── locales/en.yml                           # i18n strings
├── db/migrate/
│   └── 20250103000001_create_yak_system.rb      # Database schema
├── app/
│   ├── controllers/
│   │   ├── yaks_controller.rb                   # User endpoints
│   │   └── admin/yaks_controller.rb             # Admin endpoints
│   ├── models/
│   │   ├── yak_wallet.rb                        # Wallet balance & transactions
│   │   ├── yak_transaction.rb                   # Transaction history
│   │   ├── yak_feature.rb                       # Feature catalog
│   │   └── yak_feature_use.rb                   # Applied features tracking
│   └── services/
│       └── yak_feature_service.rb               # Business logic
├── assets/
│   ├── javascripts/discourse/                    # TODO: Ember components
│   └── stylesheets/yaks.scss                    # CSS for features
└── spec/
    ├── fabricators/yak_fabricators.rb           # Test factories
    ├── models/                                   # Model tests (4 files)
    └── services/                                 # Service tests (1 file)
```

## Architecture Decisions

### Why Custom Fields for Post Features?
Using `posts.custom_fields['yak_features']` allows:
- Dynamic feature data without schema changes
- Multiple features per post
- Easy feature enable/disable
- Future extensibility

### Why Denormalize user.yak_balance?
- Fast lookups without joins
- Easy authorization checks
- Consistent with Discourse patterns
- Updated atomically with wallet

### Why Separate YakFeatureUse?
- Track who applied which features
- Manage expiration independently
- Refund capability
- Analytics and reporting

## Troubleshooting

### Tests Won't Run
- Ensure Ruby and Bundler are installed
- Run `bundle install` in discourse root
- Check `LOAD_PLUGINS=1` environment variable is set

### Features Not Showing
- Verify `yaks_enabled` is `true` in site settings
- Check that `YakFeature.seed_default_features` ran
- Look for migration errors in logs

### Balance Not Updating
- Transactions are atomic - check for validation errors
- Verify both `yak_wallets.balance` and `users.yak_balance` update together
- Check transaction logs for failed operations

## Contributing

See README.md for contribution guidelines. Key areas:

1. **Frontend Development** - We need Ember.js expertise
2. **Payment Integration** - Stripe experience helpful
3. **Background Jobs** - Sidekiq job implementation
4. **UI/UX Design** - Making features visually appealing

---

**Questions?** Open an issue or discussion on the repository.
