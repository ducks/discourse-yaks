# frozen_string_literal: true

# Defines purchasable features that users can spend Yaks on.
#
# @class YakFeature
class YakFeature < ActiveRecord::Base
  has_many :yak_feature_uses, dependent: :destroy

  validates :feature_key, presence: true, uniqueness: true
  validates :feature_name, presence: true
  validates :cost, presence: true, numericality: { greater_than: 0 }
  validates :category, inclusion: { in: %w[post user topic] }, allow_nil: true

  scope :enabled, -> { where(enabled: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Seeds default features defined in the specification.
  #
  # @returns [Array<YakFeature>] The created features
  def self.seed_default_features
    return if YakFeature.exists?

    default_features = [
      {
        feature_key: "post_highlight",
        feature_name: "Post Highlighting",
        description: "Add a colored border and background to your post to make it stand out",
        cost: 25,
        category: "post",
        settings: {
          default_color: "gold",
          duration: nil,
        },
      },
      {
        feature_key: "post_pin",
        feature_name: "Pin Post",
        description: "Pin your post to the top of a topic for 24 hours",
        cost: 50,
        category: "post",
        settings: {
          duration_hours: 24,
        },
      },
      {
        feature_key: "custom_flair",
        feature_name: "Custom User Flair",
        description: "Display custom text and color flair next to your username for 30 days",
        cost: 100,
        category: "user",
        settings: {
          duration_days: 30,
          max_length: 20,
        },
      },
      {
        feature_key: "post_boost",
        feature_name: "Post Boost",
        description: "Give your post priority in feeds and search results for 72 hours",
        cost: 30,
        category: "post",
        settings: {
          duration_hours: 72,
        },
      },
    ]

    default_features.map { |attrs| create!(attrs) }
  end

  # Checks if a user can afford this feature.
  #
  # @param user [User] The user to check
  # @returns [Boolean] True if user has sufficient balance
  def affordable_by?(user)
    user.yak_balance >= cost
  end
end
