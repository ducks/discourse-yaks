# frozen_string_literal: true

# Manages a user's Yak currency wallet, including balance tracking and transaction history.
#
# @class YakWallet
class YakWallet < ActiveRecord::Base
  belongs_to :user
  has_many :yak_transactions, dependent: :destroy

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :lifetime_earned, numericality: { greater_than_or_equal_to: 0 }
  validates :lifetime_spent, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, presence: true, uniqueness: true

  # Credits Yaks to the wallet with transaction logging.
  #
  # @param amount [Integer] The number of Yaks to add (must be positive)
  # @param source [String] The source of the Yaks (e.g., 'stripe_purchase', 'quality_post')
  # @param description [String] Human-readable description of the transaction
  # @param metadata [Hash] Additional data to store with the transaction
  # @returns [YakTransaction, nil] The created transaction or nil if failed
  def add_yaks(amount, source, description, metadata = {})
    return nil if amount <= 0

    transaction do
      increment!(:balance, amount)
      increment!(:lifetime_earned, amount)

      yak_transactions.create!(
        user_id: user_id,
        amount: amount,
        transaction_type: "earn",
        source: source,
        description: description,
        metadata: metadata,
      )
    end
  rescue ActiveRecord::RecordInvalid
    nil
  end

  # Debits Yaks from the wallet for feature purchases.
  #
  # @param amount [Integer] The number of Yaks to spend (must be positive)
  # @param feature_key [String] The key identifying the feature being purchased
  # @param description [String] Human-readable description of the transaction
  # @param options [Hash] Additional options including :related_post_id, :related_topic_id, :metadata
  # @returns [YakTransaction, nil] The created transaction or nil if insufficient balance or failed
  def spend_yaks(amount, feature_key, description, options = {})
    return nil if amount <= 0 || balance < amount

    transaction do
      decrement!(:balance, amount)
      increment!(:lifetime_spent, amount)

      yak_transactions.create!(
        user_id: user_id,
        amount: -amount,
        transaction_type: "spend",
        source: "feature_#{feature_key}",
        description: description,
        metadata: options[:metadata] || {},
        related_post_id: options[:related_post_id],
        related_topic_id: options[:related_topic_id],
      )
    end
  rescue ActiveRecord::RecordInvalid
    nil
  end

  # Refunds a previous transaction.
  #
  # @param transaction [YakTransaction] The transaction to refund
  # @param reason [String] Reason for the refund
  # @returns [YakTransaction, nil] The refund transaction or nil if failed
  def refund_transaction(transaction, reason)
    return nil unless transaction.user_id == user_id
    return nil if transaction.amount >= 0 # Only refund debit transactions

    refund_amount = transaction.amount.abs

    transaction do
      increment!(:balance, refund_amount)
      decrement!(:lifetime_spent, refund_amount)

      yak_transactions.create!(
        user_id: user_id,
        amount: refund_amount,
        transaction_type: "refund",
        source: "refund_#{transaction.id}",
        description: reason,
        metadata: { original_transaction_id: transaction.id },
      )
    end
  rescue ActiveRecord::RecordInvalid
    nil
  end

  # Finds or creates a wallet for a user.
  #
  # @param user [User] The user to find or create a wallet for
  # @returns [YakWallet] The user's wallet
  def self.for_user(user)
    find_or_create_by!(user_id: user.id)
  end
end
