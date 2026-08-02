# frozen_string_literal: true

require "rails_helper"

RSpec.describe YakFeatureService do
  fab!(:user)
  fab!(:post) { Fabricate(:post, user: user) }

  before do
    SiteSetting.yaks_enabled = true
    YakFeature.seed_default_features
    YakWallet.for_user(user).add_yaks(100, "test", "Initial balance")
  end

  describe ".apply_feature" do
    it "successfully applies a feature" do
      result =
        YakFeatureService.apply_feature(
          user,
          "post_highlight",
          related_post: post,
          feature_data: {
            color: "gold"
          }
        )

      expect(result[:success]).to be true
      expect(result[:feature_use]).to be_present
      expect(result[:transaction]).to be_present
      expect(result[:new_balance]).to eq(75)
    end

    it "deducts cost from user balance" do
      expect {
        YakFeatureService.apply_feature(
          user,
          "post_highlight",
          related_post: post
        )
      }.to change { user.reload.yak_balance }.by(-25)
    end

    it "creates a YakFeatureUse record" do
      expect {
        YakFeatureService.apply_feature(
          user,
          "post_highlight",
          related_post: post
        )
      }.to change { YakFeatureUse.count }.by(1)
    end

    it "creates a YakTransaction record" do
      wallet = YakWallet.for_user(user)
      expect {
        YakFeatureService.apply_feature(
          user,
          "post_highlight",
          related_post: post
        )
      }.to change { wallet.yak_transactions.count }.by(1)
    end

    it "applies feature effects to post custom fields" do
      YakFeatureService.apply_feature(
        user,
        "post_highlight",
        related_post: post,
        feature_data: {
          color: "blue"
        }
      )

      post.reload
      expect(
        post.custom_fields["yak_features"]["highlight"]["enabled"]
      ).to be true
      expect(post.custom_fields["yak_features"]["highlight"]["color"]).to eq(
        "blue"
      )
    end

    it "returns error if feature not found" do
      result =
        YakFeatureService.apply_feature(
          user,
          "nonexistent_feature",
          related_post: post
        )

      expect(result[:success]).to be false
      expect(result[:error]).to eq(I18n.t("yaks.errors.feature_not_found"))
    end

    it "returns error if insufficient balance" do
      YakWallet.for_user(user).update!(balance: 10)
      result =
        YakFeatureService.apply_feature(
          user,
          "post_highlight",
          related_post: post
        )

      expect(result[:success]).to be false
      expect(result[:error]).to eq(I18n.t("yaks.errors.insufficient_balance"))
    end

    it "does not allow a feature on another user's post" do
      other_post = Fabricate(:post)

      expect {
        result =
          described_class.apply_feature(
            user,
            "post_highlight",
            related_post: other_post
          )
        expect(result[:error]).to eq(I18n.t("yaks.errors.not_allowed"))
      }.not_to change { YakWallet.for_user(user).reload.balance }
    end

    it "rejects a feature applied to the wrong target type" do
      result =
        described_class.apply_feature(user, "custom_flair", related_post: post)

      expect(result[:success]).to be false
      expect(result[:error]).to eq(I18n.t("yaks.errors.invalid_target"))
    end

    it "rolls back the debit when applying the effect fails" do
      allow(described_class).to receive(:apply_feature_effects).and_raise(
        "effect failed"
      )

      expect {
        expect {
          described_class.apply_feature(
            user,
            "post_highlight",
            related_post: post
          )
        }.to raise_error("effect failed")
      }.not_to change { YakWallet.for_user(user).reload.balance }
    end

    it "returns error if feature already applied to post" do
      YakFeatureService.apply_feature(
        user,
        "post_highlight",
        related_post: post
      )
      YakWallet.for_user(user).update!(balance: 100)

      result =
        YakFeatureService.apply_feature(
          user,
          "post_highlight",
          related_post: post
        )

      expect(result[:success]).to be false
      expect(result[:error]).to eq(I18n.t("yaks.errors.already_applied"))
    end

    it "sets expiration for time-limited features" do
      result =
        YakFeatureService.apply_feature(user, "post_pin", related_post: post)

      expect(result[:feature_use].expires_at).to be_present
      expect(result[:feature_use].expires_at).to be_within(1.minute).of(
        24.hours.from_now
      )
    end

    it "does not set expiration for permanent features" do
      result =
        YakFeatureService.apply_feature(
          user,
          "post_highlight",
          related_post: post
        )

      expect(result[:feature_use].expires_at).to be_nil
    end

    it "schedules expiration job for time-limited features" do
      freeze_time

      expect_enqueued_with(job: :expire_yak_feature, at: 24.hours.from_now) do
        YakFeatureService.apply_feature(user, "post_pin", related_post: post)
      end
    end

    it "does not schedule expiration job for permanent features" do
      expect_not_enqueued_with(job: :expire_yak_feature) do
        YakFeatureService.apply_feature(
          user,
          "post_highlight",
          related_post: post
        )
      end
    end
  end

  describe ".can_apply_to_post?" do
    it "returns true if feature not yet applied" do
      expect(
        YakFeatureService.can_apply_to_post?(user, post, "post_highlight")
      ).to be true
    end

    it "returns false if feature already applied and active" do
      YakFeatureService.apply_feature(
        user,
        "post_highlight",
        related_post: post
      )

      expect(
        YakFeatureService.can_apply_to_post?(user, post, "post_highlight")
      ).to be false
    end

    it "returns false when another user already applied the feature" do
      other_user = Fabricate(:user)
      feature = YakFeature.find_by(feature_key: "post_highlight")
      wallet = YakWallet.for_user(other_user)
      wallet.add_yaks(feature.cost, "test", "Initial balance")
      transaction =
        wallet.spend_yaks(feature.cost, feature.feature_key, "Applied feature")
      YakFeatureUse.create!(
        user: other_user,
        yak_feature: feature,
        yak_transaction: transaction,
        related_post: post
      )

      expect(
        described_class.can_apply_to_post?(user, post, feature.feature_key)
      ).to be false
    end

    it "returns true if previous feature use expired" do
      wallet = YakWallet.for_user(user)
      feature = YakFeature.find_by(feature_key: "post_pin")
      transaction =
        wallet.spend_yaks(50, "post_pin", "Test", related_post_id: post.id)

      YakFeatureUse.create!(
        user: user,
        yak_feature: feature,
        yak_transaction: transaction,
        related_post: post,
        expires_at: 1.hour.ago
      )

      expect(
        YakFeatureService.can_apply_to_post?(user, post, "post_pin")
      ).to be true
    end

    it "returns false if post is nil" do
      expect(
        YakFeatureService.can_apply_to_post?(user, nil, "post_highlight")
      ).to be false
    end
  end

  describe ".calculate_expiration" do
    it "calculates expiration for hour-based features" do
      feature = YakFeature.find_by(feature_key: "post_pin")
      expiration = YakFeatureService.calculate_expiration(feature)

      expect(expiration).to be_within(1.minute).of(24.hours.from_now)
    end

    it "calculates expiration for day-based features" do
      feature = YakFeature.find_by(feature_key: "custom_flair")
      expiration = YakFeatureService.calculate_expiration(feature)

      expect(expiration).to be_within(1.minute).of(30.days.from_now)
    end

    it "returns nil for permanent features" do
      feature = YakFeature.find_by(feature_key: "post_highlight")
      expiration = YakFeatureService.calculate_expiration(feature)

      expect(expiration).to be_nil
    end
  end

  describe ".apply_feature_effects" do
    it "applies highlight effect to post" do
      feature = YakFeature.find_by(feature_key: "post_highlight")
      YakFeatureService.apply_feature_effects(
        feature,
        user: user,
        related_post: post,
        feature_data: {
          color: "red"
        }
      )

      post.reload
      expect(post.custom_fields["yak_features"]["highlight"]).to be_present
      expect(post.custom_fields["yak_features"]["highlight"]["color"]).to eq(
        "red"
      )
    end

    it "applies pin effect to post" do
      feature = YakFeature.find_by(feature_key: "post_pin")
      YakFeatureService.apply_feature_effects(
        feature,
        user: user,
        related_post: post
      )

      post.reload
      expect(post.custom_fields["yak_features"]["pinned"]).to be_present
      expect(post.custom_fields["yak_features"]["pinned"]["enabled"]).to be true
    end

    it "applies boost effect to post" do
      feature = YakFeature.find_by(feature_key: "post_boost")
      YakFeatureService.apply_feature_effects(
        feature,
        user: user,
        related_post: post
      )

      post.reload
      expect(post.custom_fields["yak_features"]["boosted"]).to be_present
    end

    it "preserves existing features when adding new ones" do
      highlight = YakFeature.find_by(feature_key: "post_highlight")
      boost = YakFeature.find_by(feature_key: "post_boost")
      YakFeatureService.apply_feature_effects(
        highlight,
        user: user,
        related_post: post,
        feature_data: {
          color: "gold"
        }
      )
      YakFeatureService.apply_feature_effects(
        boost,
        user: user,
        related_post: post
      )

      post.reload
      expect(post.custom_fields["yak_features"]["highlight"]).to be_present
      expect(post.custom_fields["yak_features"]["boosted"]).to be_present
    end
  end

  describe ".remove_feature_effects" do
    fab!(:wallet) { Fabricate(:yak_wallet, user: user) }
    let(:yak_feature) { YakFeature.find_by!(feature_key: "post_highlight") }
    fab!(:transaction) do
      Fabricate(:yak_transaction, user: user, yak_wallet: wallet)
    end

    let(:feature_use) do
      post.custom_fields["yak_features"] = {
        "highlight" => {
          "enabled" => true
        }
      }
      post.save_custom_fields

      YakFeatureUse.create!(
        user: user,
        yak_feature: yak_feature,
        yak_transaction: transaction,
        related_post: post
      )
    end

    it "removes highlight effect from post" do
      YakFeatureService.remove_feature_effects(feature_use)

      post.reload
      expect(post.custom_fields["yak_features"]["highlight"]).to be_nil
    end

    it "preserves other features when removing one" do
      feature_use
      post.custom_fields["yak_features"] = {
        "highlight" => {
          "enabled" => true
        },
        "boosted" => {
          "enabled" => true
        }
      }
      post.save_custom_fields

      YakFeatureService.remove_feature_effects(feature_use)

      post.reload
      expect(post.custom_fields["yak_features"]["highlight"]).to be_nil
      expect(post.custom_fields["yak_features"]["boosted"]).to be_present
    end
  end
end
