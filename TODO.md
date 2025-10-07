# Discourse Yaks - Development Roadmap

## ✅ Completed (v0.1.0)

- [x] Core wallet system with balance tracking
- [x] Four default features (highlight, pin, boost, flair)
- [x] Service layer for applying features
- [x] Post highlighting fully functional with colors
- [x] Modern Discourse API decorators working
- [x] Full test coverage on models and services
- [x] Admin endpoints for granting Yaks
- [x] Custom field serialization working
- [x] Frontend decorator applying CSS classes

---

## Phase 1: Core Earning System (Foundation)

**Goal**: Users can earn Yaks through natural forum activity

### Design & Planning
- [ ] Define earning rates (how many Yaks per action?)
  - [ ] Yaks per post created
  - [ ] Yaks per like received
  - [ ] Yaks per minute reading
  - [ ] Yaks per day logged in
- [ ] Design anti-gaming measures
  - [ ] Rate limiting
  - [ ] Diminishing returns
  - [ ] Quality thresholds

### Implementation
- [ ] Reading tracking system
  - [ ] Track time spent on posts/topics
  - [ ] Minimum read time before reward
  - [ ] Cap on reading rewards per day
- [ ] Posting rewards
  - [ ] Instant reward on post creation
  - [ ] Bonus for first post in topic
  - [ ] Deduct Yaks for deleted/flagged posts
- [ ] Like-based rewards (uses existing `yaks_min_likes_for_reward` setting)
  - [ ] Award Yaks when post reaches like threshold
  - [ ] Progressive rewards (5 likes = 10 Yaks, 10 likes = 25 Yaks, etc.)
  - [ ] Cap per post (`yaks_max_reward_per_post`)
- [ ] Background job for auto-earning
  - [ ] Scheduled job (every 5 minutes?)
  - [ ] Process pending rewards
  - [ ] Batch updates for performance
  - [ ] Logging and monitoring

### Testing
- [ ] Test earning from posts
- [ ] Test earning from likes
- [ ] Test earning from reading
- [ ] Test rate limiting
- [ ] Test reward caps
- [ ] Test background job performance

---

## Phase 2: Basic UI (Make it usable)

**Goal**: Users can see balance and spend Yaks without using Rails console

### Balance Display
- [ ] Add Yak balance to user menu dropdown
  - [ ] Show current balance with icon
  - [ ] Link to wallet page
  - [ ] Show "+X Yaks" animation when earning
- [ ] Add balance to user profile card
- [ ] Add balance to user profile page (optional toggle)

### Spending Interface
- [ ] Add "Spend Yaks" button to post actions menu
  - [ ] Show cost for available features
  - [ ] Hide button if user can't afford any features
  - [ ] Disable if feature already applied
- [ ] Build feature selection modal
  - [ ] List available features with costs
  - [ ] Color picker for highlight feature
  - [ ] Duration display for time-limited features
  - [ ] Show remaining balance after purchase
  - [ ] Confirm button
  - [ ] Error handling (insufficient funds, etc.)
- [ ] Show confirmation after successful purchase
- [ ] Live update balance in UI after spending

### Wallet Page (`/yaks`)
- [ ] Header with current balance (large, prominent)
- [ ] Stats cards
  - [ ] Lifetime earned
  - [ ] Lifetime spent
  - [ ] Current balance
  - [ ] Rank/percentile (optional)
- [ ] Transaction history table
  - [ ] Date, type, amount, description
  - [ ] Pagination
  - [ ] Filters (earn/spend/all)
  - [ ] Export to CSV (optional)
- [ ] Available features grid
  - [ ] Feature cards with cost and description
  - [ ] Quick purchase buttons

### Testing
- [ ] Test balance display in various locations
- [ ] Test "Spend Yaks" button shows/hides correctly
- [ ] Test modal interactions
- [ ] Test wallet page loads correctly
- [ ] Test transaction history pagination

---

## Phase 3: Social Features (Make it fun)

**Goal**: Enable community interaction through Yaks

### Gifting & Tipping
- [ ] Add "Gift Yaks" feature
  - [ ] Modal to select user and amount
  - [ ] Confirmation step
  - [ ] Optional message
  - [ ] Transaction logged for both users
  - [ ] Notification to recipient
- [ ] Add "Tip Author" button to posts
  - [ ] Quick tip amounts (1, 5, 10 Yaks)
  - [ ] Custom amount option
  - [ ] Show total tips received on post
  - [ ] Leaderboard for most-tipped posts

### Notifications
- [ ] Notify when earning Yaks
  - [ ] Post reward notification
  - [ ] Like milestone notification
  - [ ] Daily login bonus notification
- [ ] Notify when spending Yaks
  - [ ] Purchase confirmation
  - [ ] Feature expiration warning
- [ ] Notify when receiving gifts/tips
  - [ ] Who sent, how much, optional message

### Leaderboard
- [ ] Top earners page
  - [ ] Weekly/Monthly/All-time tabs
  - [ ] User avatar, name, total earned
  - [ ] Rank badges
- [ ] Top spenders page
  - [ ] Shows who's using features most
- [ ] Most generous page
  - [ ] Most tips given
  - [ ] Most gifts sent

### Testing
- [ ] Test gifting flow
- [ ] Test tipping flow
- [ ] Test notifications deliver correctly
- [ ] Test leaderboard calculations
- [ ] Test leaderboard performance with many users

---

## Phase 4: Economy Management & Admin Tools

**Goal**: Keep the economy healthy and prevent abuse

### Admin Dashboard
- [ ] Economy overview page
  - [ ] Total Yaks in circulation
  - [ ] Yaks created (earned) per day
  - [ ] Yaks destroyed (spent) per day
  - [ ] Inflation/deflation rate
  - [ ] Average balance per user
  - [ ] Median balance per user
- [ ] Top users report
  - [ ] Highest balances
  - [ ] Most active earners
  - [ ] Most active spenders
  - [ ] Suspicious activity flagging
- [ ] Transaction browser
  - [ ] Search by user, type, date
  - [ ] Refund capability
  - [ ] Manual transaction creation
  - [ ] Export reports

### Dynamic Balancing
- [ ] Adjust earning rates based on economy
  - [ ] Lower rewards if too much inflation
  - [ ] Increase rewards if too much deflation
- [ ] Yak sinks (ways to remove Yaks from economy)
  - [ ] Feature purchases (already implemented)
  - [ ] Expiration/decay (optional)
  - [ ] Charity donations (Yaks → site donations)
  - [ ] Seasonal events (spend Yaks for special rewards)

### Fraud Detection
- [ ] Rate limit monitoring
  - [ ] Alert on unusual earning patterns
  - [ ] Auto-suspend for suspected abuse
- [ ] Transaction auditing
  - [ ] Flag suspicious transactions
  - [ ] Manual review queue

---

## Phase 5: Advanced Features

**Goal**: More ways to use Yaks

### More Feature Types
- [ ] Topic highlighting
  - [ ] Highlight entire topic in listing
  - [ ] Duration-based (24h, 48h, 1 week)
  - [ ] Multiple tier colors
- [ ] Custom emoji reactions
  - [ ] Pay Yaks to add custom emoji to posts
  - [ ] Limited-time or permanent
- [ ] Priority moderation queue
  - [ ] Spend Yaks to get faster mod response
  - [ ] Ethical considerations needed
- [ ] Username styling
  - [ ] Custom colors
  - [ ] Bold/italic
  - [ ] Icon next to name
- [ ] Profile customization
  - [ ] Custom badges
  - [ ] Profile border colors
  - [ ] Featured posts
  - [ ] Profile background
- [ ] Avatar frames
  - [ ] Seasonal frames
  - [ ] Achievement frames
  - [ ] Custom frames

### Gamification
- [ ] Daily login bonus
  - [ ] Increasing streak bonuses
  - [ ] Streak counter badge
- [ ] Achievement system
  - [ ] Earned 1000 Yaks
  - [ ] Spent 500 Yaks
  - [ ] Tipped 100 times
  - [ ] Received 1000 likes
  - [ ] Badges displayed on profile
- [ ] Seasonal events
  - [ ] 2x earning weekends
  - [ ] Special limited-edition features
  - [ ] Holiday themes
- [ ] Yak decay/expiration (optional)
  - [ ] Old Yaks expire after X days
  - [ ] Encourages spending
  - [ ] Keeps economy active

### Marketplace
- [ ] User-created features (advanced)
  - [ ] Users submit custom CSS
  - [ ] Admin approval
  - [ ] Set price
  - [ ] Revenue split to creator
- [ ] Feature trading
  - [ ] Buy/sell applied features
  - [ ] Secondary market

---

## Phase 6: Monetization

**Goal**: Optional revenue stream for forum operators

### Payment Integration
- [ ] Stripe integration
  - [ ] Replace purchase stub in `yaks_controller.rb`
  - [ ] Checkout flow
  - [ ] Receipt emails
  - [ ] Invoice generation
- [ ] Webhook handlers
  - [ ] `payment_intent.succeeded`
  - [ ] `payment_intent.failed`
  - [ ] Refund processing
- [ ] Package pricing
  - [ ] 100 Yaks = $5
  - [ ] 500 Yaks = $20 (bonus: +50 free)
  - [ ] 1000 Yaks = $35 (bonus: +150 free)
- [ ] Gift cards/codes
  - [ ] Generate codes for Yak amounts
  - [ ] Redeem codes

### Premium Features
- [ ] Yak subscription
  - [ ] Monthly fee for 2x earning rate
  - [ ] Exclusive features for subscribers
  - [ ] Special badge
- [ ] One-time purchases
  - [ ] Permanent profile upgrades
  - [ ] Permanent username styling
  - [ ] VIP features

### Compliance
- [ ] Terms of service for virtual currency
- [ ] Refund policy
- [ ] Tax considerations (consult lawyer)
- [ ] GDPR compliance for transaction data
- [ ] Age restrictions (if applicable)

---

## Technical Debt & Improvements

### Performance
- [ ] Cache serializer output
- [ ] Optimize transaction queries
- [ ] Add database indexes for leaderboards
- [ ] Background job monitoring
- [ ] Rate limiting implementation

### Testing
- [ ] Controller request specs
- [ ] System specs for UI flows
- [ ] JavaScript component tests
- [ ] Load testing for earning jobs
- [ ] Integration tests for payment flow

### Documentation
- [ ] User guide (how to earn and spend)
- [ ] Admin guide (economy management)
- [ ] Developer guide (adding features)
- [ ] API documentation
- [ ] Update README with screenshots

### Security
- [ ] Guardian implementation for all actions
- [ ] Rate limiting on all endpoints
- [ ] CSRF protection verified
- [ ] Input sanitization audit
- [ ] SQL injection prevention audit

---

## Ideas for Future Consideration

- [ ] Yak-based polls (pay to vote)
- [ ] Yak-based topic creation (premium topics)
- [ ] Charity integration (convert Yaks to real donations)
- [ ] Integration with other plugins (badges, gamification)
- [ ] Mobile app support
- [ ] API for third-party integrations
- [ ] Yak-based advertising (users pay Yaks to promote posts)
- [ ] Yak-based job board (post jobs for Yaks)
- [ ] Yak-based marketplace (buy/sell goods for Yaks)

---

## Current Sprint

**Focus**: Phase 2 - Basic UI (Make it usable)

**Next Tasks**:
1. Add Yak balance to user menu
2. Add "Spend Yaks" button to post actions
3. Build feature selection modal

**Blockers**: None

**Notes**: Backend is solid, now need to make it accessible to users!
