# frozen_string_literal: true

module Admin
  # Controller for admin management of the Yak system.
  #
  # @class YaksController
  class YaksController < Admin::AdminController
    requires_plugin DiscourseYaks::PLUGIN_NAME

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
          YakTransaction
            .recent
            .limit(25)
            .includes(:user)
            .map do |tx|
              {
                id: tx.id,
                user_id: tx.user_id,
                username: transaction_username(tx),
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

        render json: { success: true, new_balance: wallet.reload.balance }
      else
        render json: {
                 success: false,
                 error: "Failed to grant Yaks",
               },
               status: :unprocessable_entity
      end
    end

    # Applies a signed, audited balance correction for a member.
    def adjust_balance
      user = User.find_by_username(params.require(:username))
      return render json: { error: "User not found" }, status: :not_found unless user

      amount = Integer(params.require(:amount).to_s, 10)
      reason = params[:reason].to_s.strip
      if amount.zero? || reason.blank?
        return(
          render json: {
                   error: "Amount must be non-zero and reason is required",
                 },
                 status: :unprocessable_entity
        )
      end

      wallet = YakWallet.for_user(user)
      old_balance = wallet.balance
      transaction = wallet.adjust_balance(amount, reason: reason, admin_id: current_user.id)
      unless transaction
        return(
          render json: {
                   error: "Adjustment would make the balance negative",
                 },
                 status: :unprocessable_entity
        )
      end

      new_balance = wallet.reload.balance
      StaffActionLogger.new(current_user).log_custom(
        "yaks_balance_adjusted",
        user_id: user.id,
        details: "Adjusted by #{amount} Yaks (#{old_balance} → #{new_balance}): #{reason}",
      )
      MessageBus.publish("/yak-balance/#{user.id}", { balance: new_balance }, user_ids: [user.id])

      render json: {
               success: true,
               username: user.username,
               adjustment: amount,
               old_balance: old_balance,
               new_balance: new_balance,
               transaction_id: transaction.id,
             }
    rescue ArgumentError
      render json: { error: "Amount must be an integer" }, status: :unprocessable_entity
    end

    # Lists all transactions with filtering.
    #
    # @returns [JSON] Filtered transaction list
    def transactions
      transactions = YakTransaction.includes(:user).order(created_at: :desc).limit(100)

      transactions = transactions.where(user_id: params[:user_id]) if params[:user_id]

      if params[:transaction_type]
        transactions = transactions.where(transaction_type: params[:transaction_type])
      end

      render json: {
               transactions:
                 transactions.map do |tx|
                   {
                     id: tx.id,
                     user_id: tx.user_id,
                     username: transaction_username(tx),
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

    # Lists all features.
    #
    # @returns [JSON] All features with settings
    def features
      features = YakFeature.order(:category, :cost)

      render json: {
               features:
                 features.map do |f|
                   {
                     id: f.id,
                     feature_key: f.feature_key,
                     feature_name: f.feature_name,
                     description: f.description,
                     cost: f.cost,
                     category: f.category,
                     enabled: f.enabled,
                     settings: f.settings || {},
                   }
                 end,
             }
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
        render json: {
                 success: false,
                 errors: feature.errors.full_messages,
               },
               status: :unprocessable_entity
      end
    end

    # Returns system statistics.
    #
    # @returns [JSON] System-wide stats
    def stats
      render json: {
               total_wallets: YakWallet.count,
               total_yaks_in_circulation: YakWallet.sum(:balance),
               active_features: YakFeatureUse.active.count,
             }
    end

    # Returns all earning rules.
    #
    # @returns [JSON] All earning rules
    def earning_rules
      rules = YakEarningRule.order(:action_key)

      render json: {
               earning_rules:
                 rules.map do |r|
                   {
                     id: r.id,
                     action_key: r.action_key,
                     action_name: r.action_name,
                     description: r.description,
                     amount: r.amount,
                     daily_cap: r.daily_cap,
                     min_trust_level: r.min_trust_level,
                     enabled: r.enabled,
                     settings: r.settings || {},
                   }
                 end,
             }
    end

    # Updates an existing earning rule.
    #
    # @returns [JSON] The updated earning rule
    def update_earning_rule
      rule = YakEarningRule.find(params[:id])

      rule.update!(
        amount: params[:amount].to_i,
        daily_cap: params[:daily_cap].to_i,
        min_trust_level: params[:min_trust_level].to_i,
        enabled: params[:enabled],
        settings: params[:settings] || {},
      )

      render json: {
               success: true,
               earning_rule: {
                 id: rule.id,
                 action_key: rule.action_key,
                 action_name: rule.action_name,
                 description: rule.description,
                 amount: rule.amount,
                 daily_cap: rule.daily_cap,
                 min_trust_level: rule.min_trust_level,
                 enabled: rule.enabled,
                 settings: rule.settings || {},
               },
             }
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    private

    def transaction_username(transaction)
      transaction.user&.username || "(deleted user)"
    end
  end
end
