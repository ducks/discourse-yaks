# frozen_string_literal: true

require "rails_helper"

RSpec.describe YakTransaction do
  fab!(:user)
  fab!(:wallet) { Fabricate(:yak_wallet, user: user) }

  describe "validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:yak_wallet_id) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:transaction_type) }

    it "validates amount is not zero" do
      transaction = YakTransaction.new(user: user, yak_wallet: wallet, amount: 0)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount]).to be_present
    end

    it "validates transaction_type is valid" do
      transaction = YakTransaction.new(user: user, yak_wallet: wallet, amount: 10)

      transaction.transaction_type = "purchase"
      expect(transaction).to be_valid

      transaction.transaction_type = "earn"
      expect(transaction).to be_valid

      transaction.transaction_type = "spend"
      expect(transaction).to be_valid

      transaction.transaction_type = "refund"
      expect(transaction).to be_valid

      transaction.transaction_type = "admin"
      expect(transaction).to be_valid

      transaction.transaction_type = "invalid"
      expect(transaction).not_to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:yak_wallet) }
    it { should belong_to(:related_post).optional }
    it { should belong_to(:related_topic).optional }
  end

  describe "scopes" do
    let!(:credit1) do
      YakTransaction.create!(
        user: user,
        yak_wallet: wallet,
        amount: 100,
        transaction_type: "earn",
      )
    end
    let!(:credit2) do
      YakTransaction.create!(
        user: user,
        yak_wallet: wallet,
        amount: 50,
        transaction_type: "purchase",
      )
    end
    let!(:debit1) do
      YakTransaction.create!(user: user, yak_wallet: wallet, amount: -25, transaction_type: "spend")
    end
    let!(:debit2) do
      YakTransaction.create!(user: user, yak_wallet: wallet, amount: -10, transaction_type: "spend")
    end

    describe ".credits" do
      it "returns only positive amount transactions" do
        expect(YakTransaction.credits).to contain_exactly(credit1, credit2)
      end
    end

    describe ".debits" do
      it "returns only negative amount transactions" do
        expect(YakTransaction.debits).to contain_exactly(debit1, debit2)
      end
    end

    describe ".recent" do
      it "orders transactions by created_at descending" do
        expect(YakTransaction.recent.first).to eq(debit2)
        expect(YakTransaction.recent.last).to eq(credit1)
      end
    end

    describe ".by_type" do
      it "filters by transaction type" do
        expect(YakTransaction.by_type("spend")).to contain_exactly(debit1, debit2)
        expect(YakTransaction.by_type("earn")).to contain_exactly(credit1)
      end
    end

    describe ".for_user" do
      it "filters by user_id" do
        other_user = Fabricate(:user)
        other_wallet = YakWallet.create!(user: other_user)
        other_tx =
          YakTransaction.create!(
            user: other_user,
            yak_wallet: other_wallet,
            amount: 100,
            transaction_type: "earn",
          )

        expect(YakTransaction.for_user(user.id)).to contain_exactly(
          credit1,
          credit2,
          debit1,
          debit2,
        )
        expect(YakTransaction.for_user(other_user.id)).to contain_exactly(other_tx)
      end
    end
  end

  describe "#credit?" do
    it "returns true for positive amounts" do
      transaction =
        YakTransaction.new(user: user, yak_wallet: wallet, amount: 100, transaction_type: "earn")
      expect(transaction.credit?).to be true
    end

    it "returns false for negative amounts" do
      transaction =
        YakTransaction.new(user: user, yak_wallet: wallet, amount: -50, transaction_type: "spend")
      expect(transaction.credit?).to be false
    end
  end

  describe "#debit?" do
    it "returns true for negative amounts" do
      transaction =
        YakTransaction.new(user: user, yak_wallet: wallet, amount: -50, transaction_type: "spend")
      expect(transaction.debit?).to be true
    end

    it "returns false for positive amounts" do
      transaction =
        YakTransaction.new(user: user, yak_wallet: wallet, amount: 100, transaction_type: "earn")
      expect(transaction.debit?).to be false
    end
  end
end
