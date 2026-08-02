# frozen_string_literal: true

require "rails_helper"

RSpec.describe YaksController do
  fab!(:user)

  before do
    SiteSetting.yaks_enabled = true
    sign_in(user)
  end

  describe "GET /yaks/catalog.json" do
    fab!(:enabled_feature) do
      Fabricate(
        :yak_feature,
        feature_key: "server_priced_feature",
        feature_name: "Server-priced highlight",
        cost: 73,
        settings: {
          duration_hours: 24
        }
      )
    end
    fab!(:disabled_feature) { Fabricate(:yak_feature, enabled: false) }

    it "returns enabled features with their server-configured attributes" do
      get "/yaks/catalog.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["features"]).to include(
        include(
          "key" => enabled_feature.feature_key,
          "name" => enabled_feature.feature_name,
          "cost" => 73,
          "settings" => {
            "duration_hours" => 24
          }
        )
      )
      expect(response.parsed_body["features"]).not_to include(
        include("key" => disabled_feature.feature_key)
      )
    end
  end

  describe "POST /yaks/purchase.json" do
    it "does not allow stubbed Yak purchases" do
      expect {
        post "/yaks/purchase.json", params: { amount: 100 }
      }.not_to change { YakTransaction.count }

      expect(YakWallet.find_by(user: user)).to be_nil
      expect(response.status).to eq(404)
    end
  end
end
