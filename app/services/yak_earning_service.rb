# frozen_string_literal: true

class YakEarningService
  # Awards Yaks to a user for completing an action, with rate limiting and validation.
  #
  # @param user [User] The user earning Yaks
  # @param action_key [String] The action being performed (e.g., 'post_created')
  # @param related_post [Post, nil] Optional post related to the earning
  # @param related_topic [Topic, nil] Optional topic related to the earning
  # @returns [Boolean] True if Yaks were awarded, false if denied
  def self.award(user:, action_key:, related_post: nil, related_topic: nil)
    # Get the earning rule
    rule = YakEarningRule.get_rule(action_key)
    if !rule
      Rails.logger.info("[Yaks] Award failed: Rule not found or disabled (#{action_key})")
      return false
    end

    # Check trust level requirement
    if user.trust_level < rule.min_trust_level
      Rails.logger.info("[Yaks] Award failed: User TL#{user.trust_level} < required TL#{rule.min_trust_level}")
      return false
    end

    # Check minimum content length if applicable
    if rule.min_length > 0
      content = related_post&.raw || related_topic&.first_post&.raw || ""
      if content.length < rule.min_length
        Rails.logger.info("[Yaks] Award failed: Content length #{content.length} < required #{rule.min_length}")
        return false
      end
    end

    # Check daily cap
    if rule.has_daily_cap?
      earned_today = get_daily_earning_count(user, action_key)
      if earned_today >= rule.daily_cap
        Rails.logger.info("[Yaks] Award failed: Daily cap reached (#{earned_today}/#{rule.daily_cap})")
        return false
      end
    end

    # Award the Yaks
    wallet = YakWallet.find_or_create_by(user: user)

    YakTransaction.create!(
      user: user,
      yak_wallet: wallet,
      amount: rule.amount,
      transaction_type: "earn",
      description: "Earned from: #{rule.action_name}",
      related_post: related_post,
      related_topic: related_topic,
    )

    wallet.update!(balance: wallet.balance + rule.amount)

    # Publish balance update to frontend
    MessageBus.publish("/yak-balance/#{user.id}", { balance: wallet.balance }, user_ids: [user.id])

    true
  rescue => e
    Rails.logger.error("Error awarding Yaks: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    false
  end

  # Gets the count of times a user has earned from an action today.
  #
  # @param user [User] The user to check
  # @param action_key [String] The action key to check
  # @returns [Integer] Number of times earned today
  def self.get_daily_earning_count(user, action_key)
    wallet = YakWallet.find_by(user: user)
    return 0 if !wallet

    rule = YakEarningRule.find_by(action_key: action_key)
    return 0 if !rule

    # Count transactions from this action today
    start_of_day = Time.zone.now.beginning_of_day

    YakTransaction
      .where(yak_wallet: wallet)
      .where(transaction_type: "earn")
      .where("description LIKE ?", "Earned from: #{rule.action_name}")
      .where("created_at >= ?", start_of_day)
      .count
  end

  # Check if user can earn from an action (for preview/UI purposes).
  #
  # @param user [User] The user to check
  # @param action_key [String] The action key to check
  # @returns [Hash] { can_earn: Boolean, reason: String }
  def self.can_earn?(user:, action_key:)
    rule = YakEarningRule.get_rule(action_key)
    return { can_earn: false, reason: "Rule not found or disabled" } if !rule

    if user.trust_level < rule.min_trust_level
      return { can_earn: false, reason: "Trust level too low (need TL#{rule.min_trust_level})" }
    end

    if rule.has_daily_cap?
      earned_today = get_daily_earning_count(user, action_key)
      if earned_today >= rule.daily_cap
        return { can_earn: false, reason: "Daily cap reached (#{rule.daily_cap})" }
      end
    end

    { can_earn: true, reason: "Can earn #{rule.amount} Yaks" }
  end
end
