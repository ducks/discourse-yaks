# Discourse Yaks - Virtual Currency System

A virtual currency system for Discourse forums that allows users to earn and spend "Yaks" on premium features. The name is a playful pun on "yakking" (talking/chatting) and "yak shaving" (developer rabbit holes).

## Features

### Core Wallet System
- **Balance Tracking**: Each user has a wallet with current balance and lifetime statistics
- **Transaction History**: Complete audit trail of all Yak transactions
- **Multiple Transaction Types**: Purchase, earn, spend, refund, and admin grants

### Available Features

**Currently Implemented:**
1. **Post Highlighting** (25 Yaks) - Add a colored border and background to posts (gold, blue, red, green, purple)

**Planned Features:**
2. **Post Pinning** (50 Yaks) - Pin posts to the top of topics for 24 hours
3. **Custom User Flair** (100 Yaks) - Display custom flair for 30 days
4. **Post Boost** (30 Yaks) - Priority in feeds and search for 72 hours

### Admin Tools
- System-wide statistics dashboard
- Grant Yaks to users
- View transaction history with filtering
- Create and manage custom features
- Full audit logging

## Installation

1. Add the plugin to your `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/discourse-yaks.git
```

2. Rebuild your container:

```bash
./launcher rebuild app
```

3. Enable the plugin in Admin → Settings → Plugins → `yaks_enabled`

4. Default features will be seeded automatically when enabled

## Configuration

### Site Settings

- **yaks_enabled** - Enable/disable the Yaks currency system
- **yaks_dollar_to_yak_rate** - Exchange rate (default: 20 Yaks per $1)
- **yaks_earning_enabled** - Allow users to earn Yaks through contributions
- **yaks_min_likes_for_reward** - Minimum likes needed to earn Yaks (default: 5)
- **yaks_max_reward_per_post** - Maximum Yaks per post (default: 50)
- **yaks_show_balance_publicly** - Show balances on user profiles

## Usage

### For Users

#### Viewing Balance
Users can view their Yak balance at `/yaks` which shows:
- Current balance
- Lifetime earned and spent
- Transaction history
- Available features to purchase

#### Spending Yaks
1. Navigate to a post you want to enhance
2. Click the "Spend Yaks" button in the post actions menu
3. Select a feature and customize options (e.g., highlight color)
4. Confirm the purchase
5. The feature is applied immediately and your balance is updated

#### Earning Yaks (Not Yet Implemented)
Currently, users can only receive Yaks through:
- Admin grants
- Purchases (stubbed endpoint, awaiting Stripe integration)

Planned automatic earning system:
- Quality posts that receive likes will earn Yaks automatically
- Configurable thresholds and rewards via site settings

#### Purchasing Yaks
- Visit `/yaks/purchase` to see available packages
- Payment integration stubbed for now (awaiting Stripe)
- Packages configurable via site settings

### For Admins

#### Granting Yaks
```bash
POST /admin/yaks/give
{
  "user_id": 123,
  "amount": 100,
  "reason": "Community contribution award"
}
```

#### Viewing Statistics
- Navigate to Admin → Yaks
- View system-wide stats and recent transactions
- Filter transactions by user or type

#### Creating Custom Features
```bash
POST /admin/yaks/features
{
  "feature_key": "custom_avatar_frame",
  "feature_name": "Custom Avatar Frame",
  "description": "Add a decorative frame to your avatar",
  "cost": 75,
  "category": "user",
  "settings": {
    "duration_days": 30
  }
}
```

## API Endpoints

### User Endpoints
- `GET /yaks` - View wallet and available features
- `POST /yaks/spend` - Purchase and apply a feature
- `POST /yaks/purchase` - Buy Yaks (stubbed)

### Admin Endpoints
- `GET /admin/yaks` - System statistics
- `POST /admin/yaks/give` - Grant Yaks to users
- `GET /admin/yaks/transactions` - Transaction history
- `POST /admin/yaks/features` - Create new feature
- `PUT /admin/yaks/features/:id` - Update feature

## Database Schema

### Tables
- `yak_wallets` - User wallet balances and lifetime stats
- `yak_transactions` - Complete transaction history
- `yak_features` - Available purchasable features
- `yak_feature_uses` - Tracking of applied features

### Custom Fields
- `users.yak_balance` - Cached balance for quick lookups
- `posts.yak_features` - JSON field storing active post features

## Development

### Running Tests

```bash
# Run all plugin tests
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec

# Run specific test file
LOAD_PLUGINS=1 bin/rspec plugins/discourse-yaks/spec/models/yak_wallet_spec.rb
```

### Project Structure

```
plugins/discourse-yaks/
├── plugin.rb                    # Main plugin definition
├── config/
│   ├── settings.yml             # Site settings
│   └── locales/en.yml          # Translations
├── db/migrate/
│   └── 20250103000001_create_yak_system.rb
├── app/
│   ├── controllers/
│   │   ├── yaks_controller.rb
│   │   └── admin/yaks_controller.rb
│   ├── models/
│   │   ├── yak_wallet.rb
│   │   ├── yak_transaction.rb
│   │   ├── yak_feature.rb
│   │   └── yak_feature_use.rb
│   └── services/
│       └── yak_feature_service.rb
├── assets/
│   ├── javascripts/discourse/   # Frontend components (complete)
│   │   ├── components/
│   │   ├── initializers/
│   │   ├── routes/
│   │   └── templates/
│   └── stylesheets/yaks.scss
├── spec/                        # Full test suite
└── README.md
```

## Current Status

### ✅ Implemented (Version 20251008)
**Backend:**
- Core wallet and transaction system
- Database schema and migrations
- All models with full test coverage
- YakFeatureService for applying features
- Controllers (user and admin endpoints)
- Site settings configuration

**Frontend:**
- Balance display in user menu
- "Spend Yaks" button in post actions menu
- Feature selection modal with color picker
- Full wallet page (`/yaks`) with stats and transaction history
- Purchase flow (`/yaks/purchase`) with configurable packages
- Post highlighting with 5 color options (gold, blue, red, green, purple)
- Modern Discourse API patterns (no deprecated code)

**Features Working End-to-End:**
- Post highlighting (purchase, apply, display)

### 🚧 Next Steps
1. **Implement Remaining Features**
   - Post pinning logic and display
   - Post boost logic and display
   - Custom user flair
   - Expiration cleanup background job

2. **Earning System**
   - Background job for quality post detection
   - Automatic Yak rewards based on likes
   - Milestone rewards

3. **Authorization & Security**
   - Guardian implementation
   - Rate limiting on endpoints
   - Security audit

4. **Payment Integration**
   - Replace stub with real Stripe integration
   - Webhook handlers
   - Refund processing

5. **Testing**
   - Controller request specs
   - System specs for UI interactions
   - JavaScript component tests

## Security Considerations

- All spending actions require authentication
- Transaction atomicity ensures balance consistency
- Rate limiting on spending (to be implemented)
- Admin actions logged via StaffActionLogger
- Input validation on all endpoints

## Performance

- Denormalized `users.yak_balance` for fast lookups
- Indexed foreign keys on all relations
- JSONB for flexible feature_data storage
- Efficient scopes for common queries

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

GPL v2 (same as Discourse)

## Support

- Report issues on GitHub
- Community discussion on Meta Discourse
- Documentation at discourse.org

---

**Version**: 20251008
**Status**: Alpha - Backend and frontend complete, post highlighting working end-to-end. Additional features (pin/boost/flair) and earning system in development.
**Discourse Version**: Tested with Discourse 3.4+
