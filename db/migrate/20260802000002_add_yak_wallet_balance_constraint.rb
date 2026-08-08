# frozen_string_literal: true

class AddYakWalletBalanceConstraint < ActiveRecord::Migration[7.0]
  def up
    add_check_constraint :yak_wallets, "balance >= 0", name: "yak_wallets_non_negative_balance"
  end

  def down
    remove_check_constraint :yak_wallets, name: "yak_wallets_non_negative_balance"
  end
end
