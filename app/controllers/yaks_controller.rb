# frozen_string_literal: true

# Controller for user-facing Yak wallet and spending actions.
#
# @class YaksController
class YaksController < ApplicationController
  requires_plugin DiscourseYaks::PLUGIN_NAME
  requires_login
  skip_before_action :check_xhr, only: [:index]

  # Displays user's wallet, transaction history, and available features.
  #
  # @returns [JSON] Wallet data, transactions, and features
  def index
    respond_to do |format|
      format.html { render "default/empty" }
      format.json { render json: wallet_payload }
    end
  end

  # Returns the enabled feature catalog used by contextual spending controls.
  def catalog
    features = YakFeature.available.order(:category, :cost)

    render json: {
             features:
               features.map do |feature|
                 {
                   key: feature.feature_key,
                   name: feature.feature_name,
                   description: feature.description,
                   cost: feature.cost,
                   category: feature.category,
                   settings: feature.settings || {},
                 }
               end,
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
        quantity: quantity,
      )

    if result[:success]
      render json: {
               success: true,
               new_balance: result[:new_balance],
               feature_use_id: result[:feature_use].id,
             }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def wallet_payload
    wallet = YakWallet.for_user(current_user)
    transactions = wallet.yak_transactions.recent.limit(50)
    features = YakFeature.available.order(:cost)
    active_perks =
      YakFeatureUse
        .active
        .for_user(current_user.id)
        .includes(:yak_feature, :yak_transaction, :related_topic, related_post: :topic)
        .order(created_at: :desc)

    {
      balance: wallet.balance,
      lifetime_earned: wallet.lifetime_earned,
      lifetime_spent: wallet.lifetime_spent,
      active_perks: active_perks.map { |feature_use| active_perk_payload(feature_use) },
      transactions:
        transactions.map do |tx|
          {
            id: tx.id,
            amount: tx.amount,
            type: tx.transaction_type,
            source: tx.source,
            description: tx.description,
            created_at: tx.created_at,
          }
        end,
      features:
        features.map do |feature|
          {
            id: feature.id,
            key: feature.feature_key,
            name: feature.feature_name,
            description: feature.description,
            cost: feature.cost,
            category: feature.category,
            affordable: feature.affordable_by?(current_user),
          }
        end,
    }
  end

  def active_perk_payload(feature_use)
    transaction_metadata = feature_use.yak_transaction.metadata || {}

    {
      id: feature_use.id,
      key: feature_use.yak_feature.feature_key,
      name: feature_use.yak_feature.feature_name,
      category: feature_use.yak_feature.category,
      quantity: transaction_metadata["quantity"] || 1,
      applied_at: feature_use.created_at,
      expires_at: feature_use.expires_at,
      target: active_perk_target(feature_use),
    }
  end

  def active_perk_target(feature_use)
    if feature_use.related_post
      post = feature_use.related_post

      {
        type: "post",
        title: post.topic&.title,
        post_number: post.post_number,
        url: post.topic ? post.relative_url : nil,
      }
    elsif feature_use.related_topic
      topic = feature_use.related_topic
      { type: "topic", title: topic.title, url: topic.relative_url }
    elsif feature_use.related_post_id || feature_use.related_topic_id
      { type: "unavailable" }
    else
      { type: "profile", url: user_path(current_user.username) }
    end
  end
end
