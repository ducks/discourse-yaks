# frozen_string_literal: true

require "rails_helper"

RSpec.describe YakFeatureUse do
  fab!(:user)
  fab!(:feature) { Fabricate(:yak_feature) }
  fab!(:wallet) { Fabricate(:yak_wallet, user: user) }
  fab!(:transaction) { Fabricate(:yak_transaction, user: user, yak_wallet: wallet) }

  describe "validations" do
    it "validates presence of user_id" do
      use = YakFeatureUse.new(yak_feature: feature, yak_transaction: transaction)
      expect(use.valid?).to be false
      expect(use.errors[:user_id]).to be_present
    end

    it "validates presence of yak_feature_id" do
      use = YakFeatureUse.new(user: user, yak_transaction: transaction)
      expect(use.valid?).to be false
      expect(use.errors[:yak_feature_id]).to be_present
    end

    it "validates presence of yak_transaction_id" do
      use = YakFeatureUse.new(user: user, yak_feature: feature)
      expect(use.valid?).to be false
      expect(use.errors[:yak_transaction_id]).to be_present
    end
  end

  describe "associations" do
    it "belongs to user" do
      use = YakFeatureUse.create!(user: user, yak_feature: feature, yak_transaction: transaction)
      expect(use.user).to eq(user)
    end

    it "belongs to yak_feature" do
      use = YakFeatureUse.create!(user: user, yak_feature: feature, yak_transaction: transaction)
      expect(use.yak_feature).to eq(feature)
    end

    it "belongs to yak_transaction" do
      use = YakFeatureUse.create!(user: user, yak_feature: feature, yak_transaction: transaction)
      expect(use.yak_transaction).to eq(transaction)
    end

    it "optionally belongs to related_post" do
      post = Fabricate(:post)
      use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post: post,
        )
      expect(use.related_post).to eq(post)
    end

    it "optionally belongs to related_topic" do
      topic = Fabricate(:topic)
      use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_topic: topic,
        )
      expect(use.related_topic).to eq(topic)
    end
  end

  describe "scopes" do
    let!(:active_permanent) do
      YakFeatureUse.create!(
        user: user,
        yak_feature: feature,
        yak_transaction: transaction,
        expires_at: nil,
      )
    end
    let!(:active_temporary) do
      YakFeatureUse.create!(
        user: user,
        yak_feature: feature,
        yak_transaction: transaction,
        expires_at: 1.hour.from_now,
      )
    end
    let!(:expired_use) do
      YakFeatureUse.create!(
        user: user,
        yak_feature: feature,
        yak_transaction: transaction,
        expires_at: 1.hour.ago,
      )
    end

    describe ".active" do
      it "returns non-expired feature uses" do
        expect(YakFeatureUse.active).to contain_exactly(active_permanent, active_temporary)
      end
    end

    describe ".expired" do
      it "returns expired feature uses" do
        expect(YakFeatureUse.expired).to contain_exactly(expired_use)
      end
    end

    describe ".for_post" do
      fab!(:post)
      let!(:post_use) do
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post_id: post.id,
        )
      end

      it "filters by related_post_id" do
        expect(YakFeatureUse.for_post(post.id)).to contain_exactly(post_use)
      end
    end

    describe ".for_user" do
      fab!(:other_user) { Fabricate(:user) }
      fab!(:other_wallet) { Fabricate(:yak_wallet, user: other_user) }
      fab!(:other_transaction) do
        Fabricate(:yak_transaction, user: other_user, yak_wallet: other_wallet)
      end
      let!(:other_use) do
        YakFeatureUse.create!(
          user: other_user,
          yak_feature: feature,
          yak_transaction: other_transaction,
        )
      end

      it "filters by user_id" do
        user_uses = YakFeatureUse.for_user(user.id)
        expect(user_uses).to include(active_permanent, active_temporary, expired_use)
        expect(user_uses).not_to include(other_use)
      end
    end

    describe ".by_feature" do
      fab!(:other_feature) { Fabricate(:yak_feature, feature_key: "other_feature") }
      let!(:other_feature_use) do
        YakFeatureUse.create!(
          user: user,
          yak_feature: other_feature,
          yak_transaction: transaction,
        )
      end

      it "filters by feature_key" do
        expect(YakFeatureUse.by_feature(feature.feature_key)).to contain_exactly(
          active_permanent,
          active_temporary,
          expired_use,
        )
        expect(YakFeatureUse.by_feature(other_feature.feature_key)).to contain_exactly(
          other_feature_use,
        )
      end
    end
  end

  describe "#active?" do
    it "returns true for permanent features (nil expires_at)" do
      use =
        YakFeatureUse.new(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          expires_at: nil,
        )
      expect(use.active?).to be true
    end

    it "returns true for features with future expiration" do
      use =
        YakFeatureUse.new(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          expires_at: 1.hour.from_now,
        )
      expect(use.active?).to be true
    end

    it "returns false for expired features" do
      use =
        YakFeatureUse.new(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          expires_at: 1.hour.ago,
        )
      expect(use.active?).to be false
    end
  end

  describe "#expired?" do
    it "returns false for permanent features" do
      use =
        YakFeatureUse.new(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          expires_at: nil,
        )
      expect(use.expired?).to be false
    end

    it "returns false for features with future expiration" do
      use =
        YakFeatureUse.new(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          expires_at: 1.hour.from_now,
        )
      expect(use.expired?).to be false
    end

    it "returns true for expired features" do
      use =
        YakFeatureUse.new(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          expires_at: 1.hour.ago,
        )
      expect(use.expired?).to be true
    end
  end
end
