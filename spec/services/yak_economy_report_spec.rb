# frozen_string_literal: true

require "rails_helper"

RSpec.describe YakEconomyReport do
  fab!(:user)
  let(:wallet) { YakWallet.for_user(user) }

  before { freeze_time(Time.zone.local(2026, 8, 8, 12)) }

  it "reports current supply and period source and sink flows" do
    old_credit = wallet.add_yaks(40, "old_award", "Old award")
    old_credit.update_columns(created_at: 60.days.ago)
    wallet.add_yaks(100, "earning_post_created", "Recent award")
    spend = wallet.spend_yaks(25, "post_highlight", "Recent spend")
    wallet.refund_transaction(spend, "Recent refund")

    report = described_class.generate(days: 30)

    expect(report).to include(
      period_days: 30,
      current_supply: 140,
      ledger_supply: 140,
      supply_difference: 0,
      wallet_count: 1,
      holder_count: 1,
      all_time: {
        issued: 165,
        removed: 25,
        net: 140,
        transaction_count: 4,
      },
      period: {
        issued: 125,
        removed: 25,
        net: 100,
        transaction_count: 3,
      },
    )
    expect(report[:sources]).to eq(
      [
        { source: "earning_post_created", amount: 100, count: 1 },
        { source: "refunds", amount: 25, count: 1 },
      ],
    )
    expect(report[:sinks]).to eq([{ source: "feature_post_highlight", amount: 25, count: 1 }])
  end

  it "exposes wallet and ledger drift" do
    wallet.add_yaks(25, "test", "Award")
    wallet.update_columns(balance: 20)

    expect(described_class.generate).to include(
      current_supply: 20,
      ledger_supply: 25,
      supply_difference: -5,
    )
  end

  it "rejects invalid reporting periods" do
    expect { described_class.generate(days: 0) }.to raise_error(ArgumentError)
    expect { described_class.generate(days: 3651) }.to raise_error(ArgumentError)
  end
end
