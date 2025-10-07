# frozen_string_literal: true

module Admin
  # Controller for admin management of the Yak system.
  #
  # @class YaksController
  class YaksController < Admin::AdminController
    # Displays admin dashboard with system stats.
    #
    # @returns [JSON] System-wide Yak statistics
    def index
      stats = {
        total_wallets: YakWallet.count,
        total_transactions: YakTransaction.count,
        total_yaks_in_circulation: YakWallet.sum(:balance),
        total_yaks_earned: YakWallet.sum(:lifetime_earned),
        total_yaks_spent: YakWallet.sum(:lifetime_spent),
        total_feature_uses: YakFeatureUse.count,
        active_feature_uses: YakFeatureUse.active.count,
        recent_transactions:
          YakTransaction.recent.limit(25).includes(:user).map do |tx|
            {
              id: tx.id,
              user_id: tx.user_id,
              username: tx.user.username,
              amount: tx.amount,
              type: tx.transaction_type,
              created_at: tx.created_at,
            }
          end,
      }

      render json: stats
    end

    # Grants Yaks to a user.
    #
    # @returns [JSON] Success status and new balance
    def give_yaks
      user = User.find(params.require(:user_id))
      amount = params.require(:amount).to_i
      reason = params[:reason] || "Admin grant"

      wallet = YakWallet.for_user(user)
      transaction = wallet.add_yaks(amount, "admin", reason, { admin_id: current_user.id })

      if transaction
        StaffActionLogger.new(current_user).log_custom(
          "yaks_granted",
          user_id: user.id,
          details: "Granted #{amount} Yaks: #{reason}",
        )

        render json: { success: true, new_balance: user.yak_balance }
      else
        render json: { success: false, error: "Failed to grant Yaks" },
               status: :unprocessable_entity
      end
    end

    # Lists all transactions with filtering.
    #
    # @returns [JSON] Filtered transaction list
    def transactions
      transactions = YakTransaction.includes(:user).order(created_at: :desc).limit(100)

      if params[:user_id]
        transactions = transactions.where(user_id: params[:user_id])
      end

      if params[:transaction_type]
        transactions = transactions.where(transaction_type: params[:transaction_type])
      end

      render json: {
               transactions:
                 transactions.map do |tx|
                   {
                     id: tx.id,
                     user_id: tx.user_id,
                     username: tx.user.username,
                     amount: tx.amount,
                     type: tx.transaction_type,
                     source: tx.source,
                     description: tx.description,
                     created_at: tx.created_at,
                     metadata: tx.metadata,
                   }
                 end,
             }
    end

    # Creates a new purchasable feature.
    #
    # @returns [JSON] The created feature
    def create_feature
      feature =
        YakFeature.create(
          feature_key: params.require(:feature_key),
          feature_name: params.require(:feature_name),
          description: params[:description],
          cost: params.require(:cost).to_i,
          category: params[:category],
          enabled: params.fetch(:enabled, true),
          settings: params[:settings] || {},
        )

      if feature.persisted?
        render json: { success: true, feature: feature }
      else
        render json: { success: false, errors: feature.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # Updates an existing feature.
    #
    # @returns [JSON] The updated feature
    def update_feature
      feature = YakFeature.find(params.require(:id))

      if feature.update(
           feature_name: params[:feature_name],
           description: params[:description],
           cost: params[:cost]&.to_i,
           enabled: params[:enabled],
           settings: params[:settings],
         )
        render json: { success: true, feature: feature }
      else
        render json: { success: false, errors: feature.errors.full_messages },
               status: :unprocessable_entity
      end
    end
  end
end
