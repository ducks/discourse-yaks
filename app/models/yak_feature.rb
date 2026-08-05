# frozen_string_literal: true

# Defines purchasable features that users can spend Yaks on.
#
# @class YakFeature
class YakFeature < ActiveRecord::Base
  IMPLEMENTED_FEATURE_KEYS = %w[
    post_highlight
    topic_pin
    topic_boost
    custom_flair
    custom_title
  ].freeze

  has_many :yak_feature_uses, dependent: :destroy

  validates :feature_key, presence: true, uniqueness: true
  validates :feature_name, presence: true
  validates :cost, presence: true, numericality: { greater_than: 0 }
  validates :category, inclusion: { in: %w[post user topic] }, allow_nil: true

  scope :enabled, -> { where(enabled: true) }
  scope :available, -> { enabled.where(feature_key: IMPLEMENTED_FEATURE_KEYS) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Seeds default features defined in the specification.
  #
  # @returns [Array<YakFeature>] The created features
  def self.seed_default_features
    default_features = [
      {
        feature_key: "post_highlight",
        feature_name: "Post Highlighting",
        description:
          "Add a colored border and background to your post to make it stand out",
        cost: 25,
        category: "post",
        settings: {
          default_color: "gold",
          duration: nil
        }
      },
      {
        feature_key: "post_pin",
        feature_name: "Pin Post",
        description: "Pin your post to the top of a topic for 24 hours",
        cost: 50,
        category: "post",
        settings: {
          duration_hours: 24
        },
        enabled: false
      },
      {
        feature_key: "custom_flair",
        feature_name: "Custom User Flair",
        description: "Display custom flair next to your username for 30 days",
        cost: 200,
        category: "user",
        settings: {
          duration_hours: 720
        }
      },
      {
        feature_key: "post_boost",
        feature_name: "Post Boost",
        description:
          "Give your post priority in feeds and search results for 72 hours",
        cost: 30,
        category: "post",
        settings: {
          duration_hours: 72
        },
        enabled: false
      },
      {
        feature_key: "topic_pin",
        feature_name: "Pin Topic",
        description: "Pin your topic to the top of its category for 24 hours",
        cost: 100,
        category: "topic",
        settings: {
          duration_hours: 24
        }
      },
      {
        feature_key: "topic_boost",
        feature_name: "Boost Topic",
        description: "Pin your topic globally with visual highlighting",
        cost: 150,
        category: "topic",
        settings: {
          duration_hours: 72
        }
      },
      {
        feature_key: "custom_title",
        feature_name: "Custom User Title",
        description: "Set a custom title displayed next to your username",
        cost: 150,
        category: "user",
        settings: {
          duration_hours: 720
        }
      }
    ]

    default_features.map do |attrs|
      create_with(attrs.except(:feature_key)).find_or_create_by!(
        feature_key: attrs[:feature_key]
      )
    end
  end

  # Checks if a user can afford this feature.
  #
  # @param user [User] The user to check
  # @returns [Boolean] True if user has sufficient balance
  def affordable_by?(user)
    YakWallet.find_by(user_id: user.id)&.balance.to_i >= cost
  end
end
