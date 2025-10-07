# frozen_string_literal: true

require "rails_helper"

RSpec.describe YakWallet do
  fab!(:user)
  let(:wallet) { YakWallet.create!(user: user) }

  describe "validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_numericality_of(:balance).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:lifetime_earned).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:lifetime_spent).is_greater_than_or_equal_to(0) }

    it "validates uniqueness of user_id" do
      YakWallet.create!(user: user)
      duplicate_wallet = YakWallet.new(user: user)
      expect(duplicate_wallet).not_to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:yak_transactions).dependent(:destroy) }
  end

  describe ".for_user" do
    it "creates a new wallet if one doesn't exist" do
      expect { YakWallet.for_user(user) }.to change { YakWallet.count }.by(1)
    end

    it "returns existing wallet if one exists" do
      existing_wallet = YakWallet.create!(user: user)
      expect(YakWallet.for_user(user)).to eq(existing_wallet)
    end
  end

  describe "#add_yaks" do
    it "increases wallet balance" do
      expect { wallet.add_yaks(100, "test", "Test credit") }.to change { wallet.reload.balance }.by(
        100,
      )
    end

    it "increases lifetime_earned" do
      expect {
        wallet.add_yaks(100, "test", "Test credit")
      }.to change { wallet.reload.lifetime_earned }.by(100)
    end

    it "updates user yak_balance" do
      expect { wallet.add_yaks(100, "test", "Test credit") }.to change {
        user.reload.yak_balance
      }.by(100)
    end

    it "creates a transaction record" do
      expect { wallet.add_yaks(100, "test", "Test credit") }.to change {
        wallet.yak_transactions.count
      }.by(1)
    end

    it "creates transaction with correct attributes" do
      transaction = wallet.add_yaks(100, "quality_post", "Earned from great post", post_id: 123)

      expect(transaction.amount).to eq(100)
      expect(transaction.transaction_type).to eq("earn")
      expect(transaction.source).to eq("quality_post")
      expect(transaction.description).to eq("Earned from great post")
      expect(transaction.metadata["post_id"]).to eq(123)
    end

    it "returns nil for negative amounts" do
      expect(wallet.add_yaks(-50, "test", "Test")).to be_nil
    end

    it "returns nil for zero amount" do
      expect(wallet.add_yaks(0, "test", "Test")).to be_nil
    end

    it "is atomic - all or nothing" do
      allow(user).to receive(:increment!).and_raise(ActiveRecord::RecordInvalid.new)

      expect { wallet.add_yaks(100, "test", "Test") }.not_to change { wallet.reload.balance }
    end
  end

  describe "#spend_yaks" do
    before { wallet.add_yaks(100, "test", "Initial balance") }

    it "decreases wallet balance" do
      expect {
        wallet.spend_yaks(50, "post_highlight", "Highlighted post")
      }.to change { wallet.reload.balance }.by(-50)
    end

    it "increases lifetime_spent" do
      expect {
        wallet.spend_yaks(50, "post_highlight", "Highlighted post")
      }.to change { wallet.reload.lifetime_spent }.by(50)
    end

    it "updates user yak_balance" do
      expect {
        wallet.spend_yaks(50, "post_highlight", "Highlighted post")
      }.to change { user.reload.yak_balance }.by(-50)
    end

    it "creates a transaction record with negative amount" do
      transaction =
        wallet.spend_yaks(
          50,
          "post_highlight",
          "Highlighted post",
          related_post_id: 456,
          metadata: {
            color: "gold",
          },
        )

      expect(transaction.amount).to eq(-50)
      expect(transaction.transaction_type).to eq("spend")
      expect(transaction.source).to eq("feature_post_highlight")
      expect(transaction.related_post_id).to eq(456)
      expect(transaction.metadata["color"]).to eq("gold")
    end

    it "returns nil if insufficient balance" do
      expect(wallet.spend_yaks(200, "post_highlight", "Test")).to be_nil
    end

    it "returns nil for negative amounts" do
      expect(wallet.spend_yaks(-50, "post_highlight", "Test")).to be_nil
    end

    it "returns nil for zero amount" do
      expect(wallet.spend_yaks(0, "post_highlight", "Test")).to be_nil
    end

    it "does not allow balance to go negative" do
      wallet.spend_yaks(150, "post_highlight", "Test")
      expect(wallet.reload.balance).to eq(100)
    end

    it "is atomic - all or nothing" do
      allow(user).to receive(:decrement!).and_raise(ActiveRecord::RecordInvalid.new)

      expect {
        wallet.spend_yaks(50, "post_highlight", "Test")
      }.not_to change { wallet.reload.balance }
    end
  end

  describe "#refund_transaction" do
    let!(:spend_transaction) do
      wallet.add_yaks(100, "test", "Initial balance")
      wallet.spend_yaks(50, "post_highlight", "Highlighted post")
    end

    it "increases wallet balance" do
      expect { wallet.refund_transaction(spend_transaction, "Refund reason") }.to change {
        wallet.reload.balance
      }.by(50)
    end

    it "decreases lifetime_spent" do
      expect { wallet.refund_transaction(spend_transaction, "Refund reason") }.to change {
        wallet.reload.lifetime_spent
      }.by(-50)
    end

    it "updates user yak_balance" do
      expect { wallet.refund_transaction(spend_transaction, "Refund reason") }.to change {
        user.reload.yak_balance
      }.by(50)
    end

    it "creates a refund transaction record" do
      refund_tx = wallet.refund_transaction(spend_transaction, "Feature removed")

      expect(refund_tx.transaction_type).to eq("refund")
      expect(refund_tx.amount).to eq(50)
      expect(refund_tx.description).to eq("Feature removed")
      expect(refund_tx.metadata["original_transaction_id"]).to eq(spend_transaction.id)
    end

    it "returns nil if transaction doesn't belong to wallet" do
      other_user = Fabricate(:user)
      other_wallet = YakWallet.create!(user: other_user)
      other_wallet.add_yaks(100, "test", "Test")
      other_transaction = other_wallet.spend_yaks(50, "test", "Test")

      expect(wallet.refund_transaction(other_transaction, "Test")).to be_nil
    end

    it "returns nil for credit transactions (earn/refund)" do
      earn_transaction = wallet.add_yaks(50, "test", "Test")
      expect(wallet.refund_transaction(earn_transaction, "Test")).to be_nil
    end
  end
end
