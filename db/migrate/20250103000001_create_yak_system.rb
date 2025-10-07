# frozen_string_literal: true

class CreateYakSystem < ActiveRecord::Migration[7.0]
  def change
    create_table :yak_wallets do |t|
      t.integer :user_id, null: false
      t.integer :balance, default: 0, null: false
      t.integer :lifetime_earned, default: 0, null: false
      t.integer :lifetime_spent, default: 0, null: false
      t.timestamps
    end

    add_index :yak_wallets, :user_id, unique: true

    create_table :yak_transactions do |t|
      t.integer :user_id, null: false
      t.integer :yak_wallet_id, null: false
      t.integer :amount, null: false
      t.string :transaction_type, null: false, limit: 50
      t.string :source, limit: 100
      t.text :description
      t.jsonb :metadata
      t.integer :related_post_id
      t.integer :related_topic_id
      t.timestamps
    end

    add_index :yak_transactions, :user_id
    add_index :yak_transactions, :yak_wallet_id
    add_index :yak_transactions, :transaction_type
    add_index :yak_transactions, :related_post_id
    add_index :yak_transactions, :created_at

    create_table :yak_features do |t|
      t.string :feature_key, null: false, limit: 100
      t.string :feature_name, null: false, limit: 200
      t.text :description
      t.integer :cost, null: false
      t.boolean :enabled, default: true
      t.string :category, limit: 50
      t.jsonb :settings
      t.timestamps
    end

    add_index :yak_features, :feature_key, unique: true
    add_index :yak_features, :enabled
    add_index :yak_features, :category

    create_table :yak_feature_uses do |t|
      t.integer :user_id, null: false
      t.integer :yak_feature_id, null: false
      t.integer :yak_transaction_id, null: false
      t.integer :related_post_id
      t.integer :related_topic_id
      t.timestamp :expires_at
      t.jsonb :feature_data
      t.timestamps
    end

    add_index :yak_feature_uses, :user_id
    add_index :yak_feature_uses, :yak_feature_id
    add_index :yak_feature_uses, :related_post_id
    add_index :yak_feature_uses, :expires_at

    add_column :users, :yak_balance, :integer, default: 0, null: false
  end
end
