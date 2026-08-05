# frozen_string_literal: true

require "rails_helper"

RSpec.describe YaksController do
  fab!(:user)

  before { SiteSetting.yaks_enabled = true }

  describe "GET /yaks" do
    it "renders the Discourse application shell for direct navigation" do
      sign_in(user)

      get "/yaks"

      expect(response.status).to eq(200)
      expect(response.media_type).to eq("text/html")
    end

    it "returns wallet data to the client route" do
      sign_in(user)
      wallet = YakWallet.for_user(user)
      wallet.add_yaks(25, "test", "Test award")

      get "/yaks.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "balance" => 25,
        "lifetime_earned" => 25,
        "lifetime_spent" => 0,
      )
    end

    it "requires authentication" do
      get "/yaks.json"

      expect(response.status).to eq(403)
    end
  end

  describe "GET /yaks/catalog.json" do
    before { sign_in(user) }

    let!(:enabled_feature) do
      YakFeature
        .find_by!(feature_key: "post_highlight")
        .tap do |feature|
          feature.update!(
            feature_name: "Server-priced highlight",
            cost: 73,
            settings: {
              duration_hours: 24,
            },
          )
        end
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
            "duration_hours" => 24,
          },
        ),
      )
      expect(response.parsed_body["features"]).not_to include(
        include("key" => disabled_feature.feature_key),
      )
    end
  end

  describe "POST /yaks/purchase.json" do
    before { sign_in(user) }

    it "does not expose a real-money purchase endpoint" do
      expect { post "/yaks/purchase.json", params: { amount: 100 } }.not_to change {
        YakTransaction.count
      }

      expect(YakWallet.find_by(user: user)).to be_nil
      expect(response.status).to eq(404)
    end
  end

  describe "POST /yaks/spend.json" do
    fab!(:owned_post) { Fabricate(:post, user: user) }
    let!(:highlight_feature) do
      YakFeature
        .find_by!(feature_key: "post_highlight")
        .tap { |feature| feature.update!(cost: 25, enabled: true) }
    end

    before do
      sign_in(user)
      YakWallet.for_user(user).add_yaks(50, "test", "Test award")
    end

    it "applies an implemented feature to the user's own post" do
      post "/yaks/spend.json",
           params: {
             feature_key: highlight_feature.feature_key,
             post_id: owned_post.id,
             feature_data: {
               color: "gold",
             },
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("success" => true, "new_balance" => 25)
      expect(owned_post.reload.custom_fields.dig("yak_features", "highlight", "enabled")).to eq(
        true,
      )
    end

    it "rejects spending on another user's post without charging the wallet" do
      other_post = Fabricate(:post)

      expect {
        post "/yaks/spend.json",
             params: {
               feature_key: highlight_feature.feature_key,
               post_id: other_post.id,
               feature_data: {
                 color: "gold",
               },
             }
      }.not_to change { YakWallet.find_by!(user: user).reload.balance }

      expect(response.status).to eq(422)
      expect(response.parsed_body).to include(
        "success" => false,
        "error" => I18n.t("yaks.errors.not_allowed"),
      )
    end
  end

  describe "admin endpoints" do
    fab!(:admin)

    before { sign_in(admin) }

    it "returns the persisted balance after granting Yaks" do
      post "/admin/plugins/yaks/give.json",
           params: {
             user_id: user.id,
             amount: 40,
             reason: "Alpha test",
           }

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("success" => true, "new_balance" => 40)
      expect(YakWallet.find_by!(user: user).balance).to eq(40)
      expect(user.reload.yak_balance).to eq(40)
    end

    it "does not expose creation of unsupported feature keys" do
      expect {
        post "/admin/plugins/yaks/features.json",
             params: {
               feature_key: "unsupported_feature",
               feature_name: "Unsupported Feature",
               cost: 10,
               category: "user",
             }
      }.not_to change { YakFeature.count }

      expect(response.status).to eq(404)
    end
  end

  describe "removed monetary surfaces" do
    before { sign_in(user) }

    it "does not expose a purchase page" do
      get "/yaks/purchase.json"

      expect(response.status).to eq(404)
    end

    it "does not expose package management to admins" do
      sign_in(Fabricate(:admin))

      get "/admin/plugins/yaks/packages.json"

      expect(response.status).to eq(404)
    end
  end
end
