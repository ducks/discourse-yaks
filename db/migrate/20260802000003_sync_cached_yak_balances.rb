# frozen_string_literal: true

class SyncCachedYakBalances < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      UPDATE users
      SET yak_balance = yak_wallets.balance
      FROM yak_wallets
      WHERE yak_wallets.user_id = users.id
    SQL
  end

  def down
  end
end
