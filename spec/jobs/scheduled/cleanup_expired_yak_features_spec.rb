# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jobs::CleanupExpiredYakFeatures do
  fab!(:user) { Fabricate(:user) }
  fab!(:post1) { Fabricate(:post) }
  fab!(:post2) { Fabricate(:post) }
  fab!(:feature) { Fabricate(:yak_feature, feature_key: "post_highlight", cost: 25) }
  fab!(:wallet) { Fabricate(:yak_wallet, user: user, balance: 100) }

  before { SiteSetting.yaks_enabled = true }

  describe "#execute" do
    it "expires multiple expired features" do
      transaction1 = wallet.spend_yaks(25, "post_highlight", "Test 1", related_post_id: post1.id)
      transaction2 = wallet.spend_yaks(25, "post_highlight", "Test 2", related_post_id: post2.id)

      feature_use1 =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction1,
          related_post: post1,
          expires_at: 1.hour.ago,
          feature_data: { color: "gold" },
        )

      feature_use2 =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction2,
          related_post: post2,
          expires_at: 2.hours.ago,
          feature_data: { color: "blue" },
        )

      post1.custom_fields["yak_features"] = { "highlight" => { "enabled" => true, "color" => "gold" } }
      post1.save_custom_fields
      post2.custom_fields["yak_features"] = { "highlight" => { "enabled" => true, "color" => "blue" } }
      post2.save_custom_fields

      described_class.new.execute({})

      expect(feature_use1.reload.processed_at).to be_present
      expect(feature_use2.reload.processed_at).to be_present
      expect(post1.reload.custom_fields["yak_features"]["highlight"]).to be_nil
      expect(post2.reload.custom_fields["yak_features"]["highlight"]).to be_nil
    end

    it "does not expire features that have not expired yet" do
      transaction = wallet.spend_yaks(25, "post_highlight", "Test", related_post_id: post1.id)

      feature_use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post: post1,
          expires_at: 1.hour.from_now,
          feature_data: { color: "gold" },
        )

      described_class.new.execute({})

      expect(feature_use.reload.processed_at).to be_nil
    end

    it "does not expire features that have already been processed" do
      transaction = wallet.spend_yaks(25, "post_highlight", "Test", related_post_id: post1.id)

      feature_use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post: post1,
          expires_at: 1.hour.ago,
          processed_at: Time.zone.now,
          feature_data: { color: "gold" },
        )

      post1.custom_fields["yak_features"] = { "highlight" => { "enabled" => true, "color" => "gold" } }
      post1.save_custom_fields

      described_class.new.execute({})

      # Should still have highlight
      expect(post1.reload.custom_fields["yak_features"]["highlight"]).to be_present
    end

    it "does nothing if yaks is disabled" do
      SiteSetting.yaks_enabled = false

      transaction = wallet.spend_yaks(25, "post_highlight", "Test", related_post_id: post1.id)

      feature_use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post: post1,
          expires_at: 1.hour.ago,
          feature_data: { color: "gold" },
        )

      described_class.new.execute({})

      expect(feature_use.reload.processed_at).to be_nil
    end

    it "continues processing if one feature fails" do
      transaction1 = wallet.spend_yaks(25, "post_highlight", "Test 1", related_post_id: post1.id)
      transaction2 = wallet.spend_yaks(25, "post_highlight", "Test 2", related_post_id: post2.id)

      feature_use1 =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction1,
          related_post: post1,
          expires_at: 1.hour.ago,
          feature_data: { color: "gold" },
        )

      feature_use2 =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction2,
          related_post: post2,
          expires_at: 1.hour.ago,
          feature_data: { color: "blue" },
        )

      post2.custom_fields["yak_features"] = { "highlight" => { "enabled" => true, "color" => "blue" } }
      post2.save_custom_fields

      # Make first one fail
      allow(YakFeatureService).to receive(:remove_feature_effects).with(feature_use1).and_raise(
        StandardError,
        "Test error",
      )
      allow(YakFeatureService).to receive(:remove_feature_effects).with(feature_use2).and_call_original

      described_class.new.execute({})

      # First one should fail, second should succeed
      expect(feature_use1.reload.processed_at).to be_nil
      expect(feature_use2.reload.processed_at).to be_present
      expect(post2.reload.custom_fields["yak_features"]["highlight"]).to be_nil
    end
  end
end
