# frozen_string_literal: true

# Audits materialized Yak wallet totals against the immutable transaction ledger.
class YakLedgerReconciler
  def self.run(repair: false)
    new(repair: repair).run
  end

  def initialize(repair: false)
    @repair = repair
    @issues = []
    @wallets_checked = 0
    @wallets_repaired = 0
    @orphaned_caches_repaired = 0
  end

  def run
    YakWallet.find_each { |wallet| reconcile_wallet(wallet) }
    reconcile_orphaned_user_caches

    {
      repair: @repair,
      wallets_checked: @wallets_checked,
      discrepancies: @issues.length,
      wallets_repaired: @wallets_repaired,
      orphaned_caches_repaired: @orphaned_caches_repaired,
      unrepaired: @issues.count { |issue| issue[:repairable] == false },
      issues: @issues,
    }
  end

  private

  def reconcile_wallet(wallet)
    wallet.with_lock do
      @wallets_checked += 1
      totals = wallet.yak_transactions.group(:transaction_type).sum(:amount)
      expected = {
        balance: totals.values.sum,
        lifetime_earned: totals.fetch("earn", 0),
        lifetime_spent: -(totals.fetch("spend", 0) + totals.fetch("refund", 0)),
      }
      actual = {
        balance: wallet.balance,
        lifetime_earned: wallet.lifetime_earned,
        lifetime_spent: wallet.lifetime_spent,
        cached_balance: wallet.user&.yak_balance,
      }

      return if wallet_matches?(actual, expected)

      repairable = expected.values.all? { |value| value >= 0 }
      issue = {
        type: "wallet",
        wallet_id: wallet.id,
        user_id: wallet.user_id,
        actual: actual,
        expected: expected,
        repairable: repairable,
      }
      @issues << issue
      return unless @repair && repairable

      wallet.update_columns(**expected, updated_at: Time.zone.now)
      wallet.user&.update_columns(yak_balance: expected[:balance])
      @wallets_repaired += 1
      issue[:repaired] = true
    end
  end

  def wallet_matches?(actual, expected)
    actual[:balance] == expected[:balance] &&
      actual[:lifetime_earned] == expected[:lifetime_earned] &&
      actual[:lifetime_spent] == expected[:lifetime_spent] &&
      (actual[:cached_balance].nil? || actual[:cached_balance] == expected[:balance])
  end

  def reconcile_orphaned_user_caches
    User
      .where.not(yak_balance: 0)
      .where.not(id: YakWallet.select(:user_id))
      .find_each do |user|
        issue = {
          type: "orphaned_user_cache",
          user_id: user.id,
          actual: {
            cached_balance: user.yak_balance,
          },
          expected: {
            cached_balance: 0,
          },
          repairable: true,
        }
        @issues << issue
        next unless @repair

        user.update_columns(yak_balance: 0)
        @orphaned_caches_repaired += 1
        issue[:repaired] = true
      end
  end
end
