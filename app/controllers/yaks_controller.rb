# frozen_string_literal: true

# Controller for user-facing Yak wallet and spending actions.
#
# @class YaksController
class YaksController < ApplicationController
  requires_plugin DiscourseYaks::PLUGIN_NAME
  requires_login

  # Displays user's wallet, transaction history, and available features.
  #
  # @returns [JSON] Wallet data, transactions, and features
  def index
    wallet = YakWallet.for_user(current_user)
    transactions = wallet.yak_transactions.recent.limit(50)
    features = YakFeature.enabled.order(:cost)

    render json: {
             balance: current_user.yak_balance,
             lifetime_earned: wallet.lifetime_earned,
             lifetime_spent: wallet.lifetime_spent,
             transactions:
               transactions.map do |tx|
                 {
                   id: tx.id,
                   amount: tx.amount,
                   type: tx.transaction_type,
                   source: tx.source,
                   description: tx.description,
                   created_at: tx.created_at
                 }
               end,
             features:
               features.map do |f|
                 {
                   id: f.id,
                   key: f.feature_key,
                   name: f.feature_name,
                   description: f.description,
                   cost: f.cost,
                   category: f.category,
                   affordable: f.affordable_by?(current_user)
                 }
               end
           }
  end

  # Returns the enabled feature catalog used by contextual spending controls.
  def catalog
    features = YakFeature.enabled.order(:category, :cost)

    render json: {
             features:
               features.map do |feature|
                 {
                   key: feature.feature_key,
                   name: feature.feature_name,
                   description: feature.description,
                   cost: feature.cost,
                   category: feature.category,
                   settings: feature.settings || {}
                 }
               end
           }
  end

  # Spends Yaks to purchase and apply a feature.
  #
  # @returns [JSON] Success status and updated balance or error message
  def spend
    feature_key = params.require(:feature_key)
    post_id = params[:post_id]
    topic_id = params[:topic_id]
    feature_data = params[:feature_data]
    quantity = params[:quantity]&.to_i || 1

    post = Post.find_by(id: post_id) if post_id
    topic = Topic.find_by(id: topic_id) if topic_id

    # Convert feature_data to hash with symbol keys
    feature_data_hash =
      if feature_data.respond_to?(:to_unsafe_h)
        feature_data.to_unsafe_h.symbolize_keys
      elsif feature_data.is_a?(Hash)
        feature_data.symbolize_keys
      else
        {}
      end

    result =
      YakFeatureService.apply_feature(
        current_user,
        feature_key,
        related_post: post,
        related_topic: topic,
        feature_data: feature_data_hash,
        quantity: quantity
      )

    if result[:success]
      render json: {
               success: true,
               new_balance: result[:new_balance],
               feature_use_id: result[:feature_use].id
             }
    else
      render json: {
               success: false,
               error: result[:error]
             },
             status: :unprocessable_entity
    end
  end
end
