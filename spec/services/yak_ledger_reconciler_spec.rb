# frozen_string_literal: true

require "rails_helper"

RSpec.describe YakLedgerReconciler do
  fab!(:user)
  let(:wallet) { YakWallet.for_user(user) }

  before do
    wallet.add_yaks(100, "test", "Earned Yaks")
    wallet.spend_yaks(30, "post_highlight", "Spent Yaks")
  end

  it "reports a consistent wallet without changing it" do
    result = described_class.run

    expect(result).to include(
      repair: false,
      wallets_checked: 1,
      discrepancies: 0,
      wallets_repaired: 0,
    )
    expect(wallet.reload).to have_attributes(balance: 70, lifetime_earned: 100, lifetime_spent: 30)
    expect(user.reload.yak_balance).to eq(70)
  end

  it "reports wallet and cache drift in dry-run mode" do
    wallet.update_columns(balance: 9, lifetime_earned: 8, lifetime_spent: 7)
    user.update_columns(yak_balance: 6)

    result = described_class.run

    expect(result).to include(discrepancies: 1, wallets_repaired: 0)
    expect(result[:issues].first).to include(
      type: "wallet",
      actual: {
        balance: 9,
        lifetime_earned: 8,
        lifetime_spent: 7,
        cached_balance: 6,
      },
      expected: {
        balance: 70,
        lifetime_earned: 100,
        lifetime_spent: 30,
      },
    )
    expect(wallet.reload.balance).to eq(9)
    expect(user.reload.yak_balance).to eq(6)
  end

  it "repairs wallet totals and the user cache from the ledger" do
    wallet.update_columns(balance: 9, lifetime_earned: 8, lifetime_spent: 7)
    user.update_columns(yak_balance: 6)

    result = described_class.run(repair: true)

    expect(result).to include(discrepancies: 1, wallets_repaired: 1, unrepaired: 0)
    expect(result[:issues].first).to include(repaired: true)
    expect(wallet.reload).to have_attributes(balance: 70, lifetime_earned: 100, lifetime_spent: 30)
    expect(user.reload.yak_balance).to eq(70)
  end

  it "reports and repairs a cached balance without a wallet" do
    orphaned_user = Fabricate(:user)
    orphaned_user.update_columns(yak_balance: 25)

    dry_run = described_class.run

    expect(dry_run[:issues]).to include(
      include(type: "orphaned_user_cache", user_id: orphaned_user.id, repairable: true),
    )
    expect(orphaned_user.reload.yak_balance).to eq(25)

    repaired = described_class.run(repair: true)

    expect(repaired[:orphaned_caches_repaired]).to eq(1)
    expect(orphaned_user.reload.yak_balance).to eq(0)
  end

  it "does not repair a ledger whose totals would violate wallet constraints" do
    wallet.yak_transactions.delete_all
    wallet.yak_transactions.create!(
      user: user,
      amount: -10,
      transaction_type: "spend",
      source: "invalid_test_ledger",
    )

    result = described_class.run(repair: true)

    expect(result).to include(discrepancies: 1, wallets_repaired: 0, unrepaired: 1)
    expect(result[:issues].first).to include(repairable: false)
    expect(wallet.reload.balance).to eq(70)
  end
end
