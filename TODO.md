# Discourse Yaks - Development Roadmap

## ✅ Completed

### Phase 1: Core Backend (20251007)
- [x] Core wallet system with balance tracking
- [x] Transaction logging with full audit trail
- [x] Four default features defined (highlight, pin, boost, flair)
- [x] YakFeatureService for applying features
- [x] Database schema and migrations
- [x] Full test coverage on models and services
- [x] Admin endpoints for granting Yaks
- [x] Custom field serialization working

### Phase 2: Complete Frontend UI (20251008)
- [x] Balance display in user menu dropdown
- [x] "Spend Yaks" button in post actions menu
- [x] Feature selection modal with color picker
- [x] Wallet page (`/yaks`) with:
  - [x] Current balance and lifetime stats
  - [x] Transaction history with formatted dates
  - [x] Available features grid with affordability indicators
- [x] Purchase flow (`/yaks/purchase`) with configurable packages
- [x] Modern Discourse API patterns (no deprecated code)
- [x] Frontend decorator applying CSS classes for highlighting

### Post Highlighting Feature (Fully Working)
- [x] Backend service implementation
- [x] Frontend color picker (gold/blue/red/green/purple)
- [x] Custom field storage
- [x] CSS styling with colored borders
- [x] Real-time application after purchase

---

## 🚧 In Progress

### Phase 3: Implement Remaining Features

**Priority: High** - These are defined and available in the modal but don't
actually do anything yet beyond highlighting.

#### Post Pinning
- [ ] Implement pin logic in YakFeatureService.apply_feature_effects
- [ ] Add CSS styling for pinned posts
- [ ] Topic-level pinning logic (show at top)
- [ ] 24-hour expiration handling
- [ ] Test pinning behavior

#### Post Boost
- [ ] Implement boost logic in YakFeatureService.apply_feature_effects
- [ ] Add CSS styling for boosted posts
- [ ] Integrate with feed/search ranking (if applicable)
- [ ] 72-hour expiration handling
- [ ] Test boost behavior

#### Custom User Flair
- [ ] Implement flair logic (different from post features)
- [ ] User-level custom field storage
- [ ] Flair display in user card/profile
- [ ] Text length validation (max 20 chars)
- [ ] 30-day expiration handling
- [ ] Color selection for flair
- [ ] Test flair display across site

---

## Phase 4: Earning System

**Priority: Medium** - Users currently can only get Yaks from admin grants or
purchases. Need automatic earning for organic engagement.

### Design Decisions Needed
- [ ] Define earning rates (how many Yaks per action?)
  - [ ] Yaks per post created (if any)
  - [ ] Yaks per like received (progressive: 5 likes = 10 Yaks, 10 likes = 25?)
  - [ ] Yaks per minute reading (if tracking)
  - [ ] Daily login bonus?

### Anti-Gaming Measures
- [ ] Rate limiting per user per day
- [ ] Diminishing returns for repetitive actions
- [ ] Quality thresholds (minimum post length, etc.)
- [ ] Flag/delete post deducts Yaks

### Implementation
- [ ] Background job for auto-earning
  - [ ] Scheduled job (every 5 minutes? hourly?)
  - [ ] Process posts that hit like thresholds
  - [ ] Batch updates for performance
  - [ ] Logging and monitoring
- [ ] Like-based rewards (uses existing `yaks_min_likes_for_reward` setting)
  - [ ] Award Yaks when post reaches threshold
  - [ ] Progressive rewards system
  - [ ] Cap per post (`yaks_max_reward_per_post`)

### Testing
- [ ] Test earning from posts
- [ ] Test earning from likes
- [ ] Test rate limiting
- [ ] Test reward caps
- [ ] Test background job performance

---

## Phase 5: Feature Expiration & Cleanup

**Priority: Medium** - Features with durations need automatic cleanup.

- [ ] Background job to expire features
  - [ ] Query YakFeatureUse.expired
  - [ ] Call YakFeatureService.remove_feature_effects
  - [ ] Update or soft-delete YakFeatureUse records
  - [ ] Run daily or hourly
- [ ] Test expiration for pinned posts (24h)
- [ ] Test expiration for boosted posts (72h)
- [ ] Test expiration for custom flair (30 days)
- [ ] Notifications before expiration? (optional)

---

## Phase 6: Authorization & Security

**Priority: Medium-High** - Currently no permission checks.

### Guardian Implementation
- [ ] Create `lib/guardian/yak_guardian.rb` (or extend existing Guardian)
- [ ] can_spend_yaks? - check user owns wallet
- [ ] can_apply_feature_to_post? - check ownership or permissions
- [ ] can_view_wallet? - privacy settings
- [ ] can_gift_yaks? - if implementing gifting

### Security Audit
- [ ] Rate limiting on spending endpoints
- [ ] Validate all user inputs
- [ ] CSRF protection verified
- [ ] SQL injection prevention audit
- [ ] Test concurrent spending (race conditions)

---

## Phase 7: Admin Dashboard Improvements

**Priority: Low** - Basic admin endpoints exist but UI is minimal.

### Economy Dashboard
- [ ] Total Yaks in circulation
- [ ] Yaks created (earned) per day
- [ ] Yaks destroyed (spent) per day
- [ ] Inflation/deflation rate
- [ ] Average/median balance per user
- [ ] Charts and graphs

### Reports
- [ ] Top earners (weekly/monthly/all-time)
- [ ] Top spenders
- [ ] Most popular features
- [ ] Suspicious activity flagging

### Tools
- [ ] Transaction browser with search/filters
- [ ] Manual refund capability
- [ ] Bulk Yak grants
- [ ] Feature management UI (create/edit/disable)

---

## Phase 8: Social Features (Optional)

**Priority: Low** - Nice-to-have community features.

### Gifting & Tipping
- [ ] "Gift Yaks" feature
  - [ ] Modal to select user and amount
  - [ ] Optional message
  - [ ] Notification to recipient
- [ ] "Tip Author" button on posts
  - [ ] Quick tip amounts (1, 5, 10 Yaks)
  - [ ] Show total tips received
  - [ ] Leaderboard for most-tipped posts

### Leaderboards
- [ ] Top earners page
- [ ] Top spenders page
- [ ] Most generous (tips/gifts)

### Notifications
- [ ] Earning notifications
- [ ] Spending confirmations
- [ ] Feature expiration warnings
- [ ] Gift/tip received

---

## Phase 9: Monetization (Future)

**Priority: Low** - Optional revenue stream for forum operators.

### Payment Integration
- [ ] Replace stub with real Stripe integration
- [ ] Checkout flow
- [ ] Webhook handlers
- [ ] Receipt emails
- [ ] Refund processing

### Package Pricing
- [ ] Configurable via site settings (partially done)
- [ ] Bonus Yaks for larger purchases
- [ ] Gift cards/promo codes

---

## Technical Debt & Improvements

### Testing
- [ ] Controller request specs
- [ ] System specs for UI flows
- [ ] JavaScript component tests
- [ ] Load testing for earning jobs

### Documentation
- [ ] User guide (how to earn and spend)
- [ ] Admin guide (economy management)
- [ ] Developer guide (adding features)
- [ ] Update README with current screenshots
- [ ] API documentation

### Performance
- [ ] Cache serializer output
- [ ] Optimize transaction queries
- [ ] Add database indexes for leaderboards
- [ ] Background job monitoring

---

## Current Focus (2025-10-11)

**Immediate Next Steps:**
1. Implement post pinning effect (show pinned posts at top of topic)
2. Implement post boost effect (visual indicator + ranking if applicable)
3. Implement custom flair (user-level feature)
4. Write blog post Part 2 about implementing these features

**Blockers:** None

**Notes:**
- Backend and frontend infrastructure is solid
- All the hard patterns are established
- Now it's about adding feature effects and polishing
- Earning system and expiration cleanup are important but not blocking users
  from trying the system
