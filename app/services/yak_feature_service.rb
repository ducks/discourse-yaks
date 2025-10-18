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
  # @param related_topic [Topic, nil] The topic to apply the feature to (if applicable)
  # @param feature_data [Hash] Additional data for the feature (colors, text, etc.)
  # @returns [Hash] Result with success status and data or error message
  def self.apply_feature(user, feature_key, related_post: nil, related_topic: nil, feature_data: {})
    feature = YakFeature.enabled.find_by(feature_key: feature_key)
    return { success: false, error: I18n.t("yaks.errors.feature_not_found") } unless feature

    return { success: false, error: I18n.t("yaks.errors.insufficient_balance") } unless feature
             .affordable_by?(user)

    # Derive topic from post if not provided
    topic = related_topic || related_post&.topic

    # Check if feature can be applied
    if related_post && !can_apply_to_post?(user, related_post, feature_key)
      return { success: false, error: I18n.t("yaks.errors.already_applied") }
    end

    if related_topic && !can_apply_to_topic?(user, related_topic, feature_key)
      return { success: false, error: I18n.t("yaks.errors.already_applied") }
    end

    # For user-level features, check if user already has one active
    if feature.category == "user" && !can_apply_to_user?(user, feature_key)
      return { success: false, error: I18n.t("yaks.errors.already_applied") }
    end

    wallet = YakWallet.for_user(user)

    transaction =
      wallet.spend_yaks(
        feature.cost,
        feature_key,
        "Applied #{feature.feature_name}",
        related_post_id: related_post&.id,
        related_topic_id: topic&.id,
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
        related_topic: topic,
        expires_at: expires_at,
        feature_data: feature_data,
      )

    # Apply effects based on what was provided
    apply_feature_effects(feature, user: user, related_post: related_post, related_topic: topic, feature_data: feature_data)

    # Schedule expiration job if feature has expiration time
    if expires_at
      Jobs.enqueue_at(expires_at, :expire_yak_feature, feature_use_id: feature_use.id)
    end

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

  # Checks if a feature can be applied to a topic.
  #
  # @param user [User] The user attempting to apply the feature
  # @param topic [Topic] The topic to check
  # @param feature_key [String] The feature being applied
  # @returns [Boolean] True if the feature can be applied
  def self.can_apply_to_topic?(user, topic, feature_key)
    return false unless topic

    existing_uses =
      YakFeatureUse.active.for_topic(topic.id).by_feature(feature_key).where(user_id: user.id)

    existing_uses.empty?
  end

  # Checks if a feature can be applied to a user.
  #
  # @param user [User] The user attempting to apply the feature
  # @param feature_key [String] The feature being applied
  # @returns [Boolean] True if the feature can be applied
  def self.can_apply_to_user?(user, feature_key)
    return false unless user

    existing_uses = YakFeatureUse.active.by_feature(feature_key).where(user_id: user.id)

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

  # Applies visual and functional effects of a feature.
  #
  # @param feature [YakFeature] The feature being applied
  # @param user [User] The user applying the feature
  # @param related_post [Post, nil] The post to apply effects to
  # @param related_topic [Topic, nil] The topic to apply effects to
  # @param feature_data [Hash] Additional feature configuration
  # @returns [void]
  def self.apply_feature_effects(feature, user:, related_post: nil, related_topic: nil, feature_data: {})
    feature_key = feature.feature_key

    # Handle user-specific features
    case feature_key
    when "custom_flair"
      current_features = user.custom_fields["yak_features"] || {}
      current_features["flair"] = {
        enabled: true,
        icon: feature_data[:icon] || "star",
        bg_color: feature_data[:bg_color] || "FF0000",
        color: feature_data[:color] || "FFFFFF",
        applied_at: Time.zone.now.to_i,
      }
      user.custom_fields["yak_features"] = current_features
      user.save_custom_fields
    end

    # Handle post-specific features
    if related_post
      current_features = related_post.custom_fields["yak_features"] || {}

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

      related_post.custom_fields["yak_features"] = current_features
      related_post.save_custom_fields
    end

    # Handle topic-specific features
    if related_topic
      case feature_key
      when "topic_pin"
        duration = feature.settings["duration_hours"]&.hours || 24.hours
        related_topic.update_pinned(true, false, duration.from_now.to_s)
      when "topic_boost"
        duration = feature.settings["duration_hours"]&.hours || 72.hours
        related_topic.update_pinned(true, true, duration.from_now.to_s)

        # Add visual highlight for boosted topics
        current_features = related_topic.custom_fields["yak_features"] || {}
        current_features["boosted"] = {
          enabled: true,
          color: feature_data[:color] || "gold",
          applied_at: Time.zone.now.to_i,
        }
        related_topic.custom_fields["yak_features"] = current_features
        related_topic.save_custom_fields
      end
    end
  end

  # Removes expired feature effects.
  #
  # @param feature_use [YakFeatureUse] The expired feature use
  # @returns [void]
  def self.remove_feature_effects(feature_use)
    feature_key = feature_use.yak_feature.feature_key
    user = feature_use.user

    # Handle user-specific feature removal
    case feature_key
    when "custom_flair"
      current_features = user.custom_fields["yak_features"] || {}
      current_features.delete("flair")
      user.custom_fields["yak_features"] = current_features
      user.save_custom_fields
    end

    # Handle post-specific feature removal
    if feature_use.related_post
      post = feature_use.related_post
      current_features = post.custom_fields["yak_features"] || {}

      case feature_key
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

    # Handle topic-specific feature removal
    if feature_use.related_topic
      topic = feature_use.related_topic

      case feature_key
      when "topic_pin"
        topic.update_pinned(false) if topic.pinned_at.present?
      when "topic_boost"
        topic.update_pinned(false) if topic.pinned_at.present?

        # Remove visual highlight
        current_features = topic.custom_fields["yak_features"] || {}
        current_features.delete("boosted")
        topic.custom_fields["yak_features"] = current_features
        topic.save_custom_fields
      end
    end
  end
end
