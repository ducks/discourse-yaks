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
        render json: { success: false, errors: feature.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # Lists all packages.
    #
    # @returns [JSON] All packages ordered by position
    def packages
      packages = YakPackage.ordered

      render json: {
               packages:
                 packages.map do |p|
                   {
                     id: p.id,
                     name: p.name,
                     description: p.description,
                     price_usd: p.price_usd,
                     price_cents: p.price_cents,
                     yaks: p.yaks,
                     bonus_yaks: p.bonus_yaks,
                     total_yaks: p.total_yaks,
                     enabled: p.enabled,
                     position: p.position,
                   }
                 end,
             }
    end

    # Creates a new package.
    #
    # @returns [JSON] The created package
    def create_package
      package =
        YakPackage.create(
          name: params.require(:name),
          description: params[:description],
          price_cents: (params.require(:price_usd).to_f * 100).to_i,
          yaks: params.require(:yaks).to_i,
          bonus_yaks: params.fetch(:bonus_yaks, 0).to_i,
          enabled: params.fetch(:enabled, true),
          position: YakPackage.maximum(:position).to_i + 1,
        )

      if package.persisted?
        render json: { success: true, package: package }
      else
        render json: { success: false, errors: package.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # Updates an existing package.
    #
    # @returns [JSON] The updated package
    def update_package
      package = YakPackage.find(params.require(:id))

      update_params = {}
      update_params[:name] = params[:name] if params[:name]
      update_params[:description] = params[:description] if params[:description]
      update_params[:price_cents] = (params[:price_usd].to_f * 100).to_i if params[:price_usd]
      update_params[:yaks] = params[:yaks].to_i if params[:yaks]
      update_params[:bonus_yaks] = params[:bonus_yaks].to_i if params[:bonus_yaks]
      update_params[:enabled] = params[:enabled] if !params[:enabled].nil?
      update_params[:position] = params[:position].to_i if params[:position]

      if package.update(update_params)
        render json: { success: true, package: package }
      else
        render json: { success: false, errors: package.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # Deletes a package.
    #
    # @returns [JSON] Success status
    def delete_package
      package = YakPackage.find(params.require(:id))
      package.destroy!

      render json: { success: true }
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
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
  end
end
