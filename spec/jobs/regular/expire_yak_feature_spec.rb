# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jobs::ExpireYakFeature do
  fab!(:user) { Fabricate(:user) }
  fab!(:post) { Fabricate(:post) }
  fab!(:feature) { Fabricate(:yak_feature, feature_key: "post_highlight", cost: 25) }
  fab!(:wallet) { Fabricate(:yak_wallet, user: user, balance: 100) }

  let(:transaction) do
    wallet.spend_yaks(25, "post_highlight", "Test purchase", related_post_id: post.id)
  end

  describe "#execute" do
    it "expires a feature that has passed its expiration time" do
      feature_use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post: post,
          expires_at: 1.hour.ago,
          feature_data: { color: "gold" },
        )

      # Apply feature effects
      post.custom_fields["yak_features"] = { "highlight" => { "enabled" => true, "color" => "gold" } }
      post.save_custom_fields

      expect(feature_use.expired?).to be true
      expect(post.reload.custom_fields["yak_features"]["highlight"]).to be_present

      described_class.new.execute(feature_use_id: feature_use.id)

      feature_use.reload
      expect(feature_use.processed_at).to be_present
      expect(post.reload.custom_fields["yak_features"]["highlight"]).to be_nil
    end

    it "does nothing if feature use does not exist" do
      expect { described_class.new.execute(feature_use_id: 99999) }.not_to raise_error
    end

    it "does nothing if feature has not expired yet" do
      feature_use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post: post,
          expires_at: 1.hour.from_now,
          feature_data: { color: "gold" },
        )

      described_class.new.execute(feature_use_id: feature_use.id)

      expect(feature_use.reload.processed_at).to be_nil
    end

    it "does nothing if feature has already been processed" do
      feature_use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post: post,
          expires_at: 1.hour.ago,
          processed_at: Time.zone.now,
          feature_data: { color: "gold" },
        )

      post.custom_fields["yak_features"] = { "highlight" => { "enabled" => true, "color" => "gold" } }
      post.save_custom_fields

      described_class.new.execute(feature_use_id: feature_use.id)

      # Should still have highlight since it wasn't removed
      expect(post.reload.custom_fields["yak_features"]["highlight"]).to be_present
    end

    it "handles errors gracefully" do
      feature_use =
        YakFeatureUse.create!(
          user: user,
          yak_feature: feature,
          yak_transaction: transaction,
          related_post: post,
          expires_at: 1.hour.ago,
          feature_data: { color: "gold" },
        )

      allow(YakFeatureService).to receive(:remove_feature_effects).and_raise(StandardError, "Test error")

      expect { described_class.new.execute(feature_use_id: feature_use.id) }.not_to raise_error
      expect(feature_use.reload.processed_at).to be_nil
    end
  end
end
