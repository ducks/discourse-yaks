# frozen_string_literal: true

# Records all Yak currency transactions for audit and history tracking.
#
# @class YakTransaction
class YakTransaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :yak_wallet
  belongs_to :related_post, class_name: "Post", optional: true
  belongs_to :related_topic, class_name: "Topic", optional: true

  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :transaction_type,
            presence: true,
            inclusion: {
              in: %w[purchase earn spend refund admin],
            }
  validates :user_id, presence: true
  validates :yak_wallet_id, presence: true

  scope :credits, -> { where("amount > 0") }
  scope :debits, -> { where("amount < 0") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(transaction_type: type) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  # Returns whether this transaction is a credit (adding Yaks).
  #
  # @returns [Boolean] True if amount is positive
  def credit?
    amount.positive?
  end

  # Returns whether this transaction is a debit (spending Yaks).
  #
  # @returns [Boolean] True if amount is negative
  def debit?
    amount.negative?
  end
end
