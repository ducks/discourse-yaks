# frozen_string_literal: true

class AlterYakAssociationIdsToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :yak_wallets, :user_id, :bigint

    change_column :yak_transactions, :user_id, :bigint
    change_column :yak_transactions, :yak_wallet_id, :bigint
    change_column :yak_transactions, :related_post_id, :bigint
    change_column :yak_transactions, :related_topic_id, :bigint

    change_column :yak_feature_uses, :user_id, :bigint
    change_column :yak_feature_uses, :yak_feature_id, :bigint
    change_column :yak_feature_uses, :yak_transaction_id, :bigint
    change_column :yak_feature_uses, :related_post_id, :bigint
    change_column :yak_feature_uses, :related_topic_id, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
