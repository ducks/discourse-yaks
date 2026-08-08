# frozen_string_literal: true

# Tracks when users apply purchased features to posts, topics, or their profile.
#
# @class YakFeatureUse
class YakFeatureUse < ActiveRecord::Base
  belongs_to :user
  belongs_to :yak_feature
  belongs_to :yak_transaction
  belongs_to :related_post, class_name: "Post", optional: true
  belongs_to :related_topic, class_name: "Topic", optional: true

  validates :user_id, presence: true
  validates :yak_feature_id, presence: true
  validates :yak_transaction_id, presence: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.zone.now) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.zone.now) }
  scope :for_post, ->(post_id) { where(related_post_id: post_id) }
  scope :for_topic, ->(topic_id) { where(related_topic_id: topic_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :by_feature, ->(feature_key) { joins(:yak_feature).where(yak_features: { feature_key: }) }

  # Checks if this feature use is currently active (not expired).
  #
  # @returns [Boolean] True if not expired
  def active?
    expires_at.nil? || expires_at > Time.zone.now
  end

  # Checks if this feature use has expired.
  #
  # @returns [Boolean] True if expired
  def expired?
    !active?
  end
end

# == Schema Information
#
# Table name: yak_feature_uses
#
#  id                 :bigint           not null, primary key
#  expires_at         :datetime
#  feature_data       :jsonb
#  processed_at       :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  related_post_id    :integer
#  related_topic_id   :integer
#  user_id            :integer          not null
#  yak_feature_id     :integer          not null
#  yak_transaction_id :integer          not null
#
# Indexes
#
#  index_yak_feature_uses_on_expires_at       (expires_at)
#  index_yak_feature_uses_on_processed_at     (processed_at)
#  index_yak_feature_uses_on_related_post_id  (related_post_id)
#  index_yak_feature_uses_on_user_id          (user_id)
#  index_yak_feature_uses_on_yak_feature_id   (yak_feature_id)
#
