# frozen_string_literal: true

# Summarizes Yak issuance, removal, and supply for economy operators.
class YakEconomyReport
  DEFAULT_PERIOD_DAYS = 30
  MAX_PERIOD_DAYS = 3650
  NORMALIZED_SOURCE_SQL = <<~SQL.squish
    CASE
      WHEN transaction_type = 'refund' THEN 'refunds'
      WHEN transaction_type = 'purchase' THEN 'purchases'
      WHEN transaction_type = 'admin' THEN 'admin_adjustments'
      ELSE COALESCE(NULLIF(source, ''), transaction_type)
    END
  SQL

  def self.generate(days: DEFAULT_PERIOD_DAYS)
    new(days: days).generate
  end

  def initialize(days: DEFAULT_PERIOD_DAYS)
    @days = Integer(days)
    unless @days.in?(1..MAX_PERIOD_DAYS)
      raise ArgumentError, "days must be between 1 and #{MAX_PERIOD_DAYS}"
    end
  end

  def generate
    period_transactions = YakTransaction.where(created_at: since..)
    current_supply = YakWallet.sum(:balance)
    ledger_supply = YakTransaction.sum(:amount)

    {
      period_days: @days,
      since: since,
      current_supply: current_supply,
      ledger_supply: ledger_supply,
      supply_difference: current_supply - ledger_supply,
      wallet_count: YakWallet.count,
      holder_count: YakWallet.where("balance > 0").count,
      all_time: totals(YakTransaction.all),
      period: totals(period_transactions),
      sources: breakdown(period_transactions.where("amount > 0")),
      sinks: breakdown(period_transactions.where("amount < 0")),
    }
  end

  private

  def since
    @since ||= @days.days.ago.beginning_of_day
  end

  def totals(scope)
    issued = scope.where("amount > 0").sum(:amount)
    removed = -scope.where("amount < 0").sum(:amount)

    { issued: issued, removed: removed, net: issued - removed, transaction_count: scope.count }
  end

  def breakdown(scope)
    source_sql = Arel.sql(NORMALIZED_SOURCE_SQL)

    scope
      .group(source_sql)
      .pluck(source_sql, Arel.sql("SUM(ABS(amount))"), Arel.sql("COUNT(*)"))
      .map { |source, amount, count| { source: source, amount: amount.to_i, count: count.to_i } }
      .sort_by { |row| [-row[:amount], row[:source]] }
  end
end
