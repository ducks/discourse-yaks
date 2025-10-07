# frozen_string_literal: true

# Service for applying purchased Yak features to posts, topics, and user profiles.
#
# @class YakFeatureService
class YakFeatureService
  # Applies a feature to a post or user profile.
  #
  # @param user [User] The user purchasing the feature
  # @param feature_key [String] The key of the feature to apply
  # @param related_post [Post, nil] The post to apply the feature to (if applicable)
  # @param feature_data [Hash] Additional data for the feature (colors, text, etc.)
  # @returns [Hash] Result with success status and data or error message
  def self.apply_feature(user, feature_key, related_post: nil, feature_data: {})
    feature = YakFeature.enabled.find_by(feature_key: feature_key)
    return { success: false, error: I18n.t("yaks.errors.feature_not_found") } unless feature

    return { success: false, error: I18n.t("yaks.errors.insufficient_balance") } unless feature
             .affordable_by?(user)

    if related_post && !can_apply_to_post?(user, related_post, feature_key)
      return { success: false, error: I18n.t("yaks.errors.already_applied") }
    end

    wallet = YakWallet.for_user(user)

    transaction =
      wallet.spend_yaks(
        feature.cost,
        feature_key,
        "Applied #{feature.feature_name}",
        related_post_id: related_post&.id,
        related_topic_id: related_post&.topic_id,
        metadata: feature_data,
      )

    return { success: false, error: I18n.t("yaks.errors.insufficient_balance") } unless transaction

    expires_at = calculate_expiration(feature)

    feature_use =
      YakFeatureUse.create!(
        user: user,
        yak_feature: feature,
        yak_transaction: transaction,
        related_post: related_post,
        related_topic: related_post&.topic,
        expires_at: expires_at,
        feature_data: feature_data,
      )

    apply_feature_effects(feature_key, related_post, feature_data) if related_post

    { success: true, feature_use: feature_use, transaction: transaction, new_balance: user.yak_balance }
  end

  # Checks if a feature can be applied to a post.
  #
  # @param user [User] The user attempting to apply the feature
  # @param post [Post] The post to check
  # @param feature_key [String] The feature being applied
  # @returns [Boolean] True if the feature can be applied
  def self.can_apply_to_post?(user, post, feature_key)
    return false unless post

    existing_uses =
      YakFeatureUse.active.for_post(post.id).by_feature(feature_key).where(user_id: user.id)

    existing_uses.empty?
  end

  # Calculates the expiration time for a feature based on its settings.
  #
  # @param feature [YakFeature] The feature to calculate expiration for
  # @returns [Time, nil] The expiration time or nil for permanent features
  def self.calculate_expiration(feature)
    return nil unless feature.settings

    if feature.settings["duration_hours"]
      feature.settings["duration_hours"].hours.from_now
    elsif feature.settings["duration_days"]
      feature.settings["duration_days"].days.from_now
    end
  end

  # Applies visual and functional effects of a feature to a post.
  #
  # @param feature_key [String] The feature being applied
  # @param post [Post] The post to apply effects to
  # @param feature_data [Hash] Additional feature configuration
  # @returns [void]
  def self.apply_feature_effects(feature_key, post, feature_data)
    current_features = post.custom_fields["yak_features"] || {}

    case feature_key
    when "post_highlight"
      current_features["highlight"] = {
        enabled: true,
        color: feature_data[:color] || "gold",
        applied_at: Time.zone.now.to_i,
      }
    when "post_pin"
      current_features["pinned"] = { enabled: true, applied_at: Time.zone.now.to_i }
    when "post_boost"
      current_features["boosted"] = { enabled: true, applied_at: Time.zone.now.to_i }
    end

    post.custom_fields["yak_features"] = current_features
    post.save_custom_fields
  end

  # Removes expired feature effects from a post.
  #
  # @param feature_use [YakFeatureUse] The expired feature use
  # @returns [void]
  def self.remove_feature_effects(feature_use)
    return unless feature_use.related_post

    post = feature_use.related_post
    current_features = post.custom_fields["yak_features"] || {}

    case feature_use.yak_feature.feature_key
    when "post_highlight"
      current_features.delete("highlight")
    when "post_pin"
      current_features.delete("pinned")
    when "post_boost"
      current_features.delete("boosted")
    end

    post.custom_fields["yak_features"] = current_features
    post.save_custom_fields
  end
end
