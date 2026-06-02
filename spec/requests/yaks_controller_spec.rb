# frozen_string_literal: true

require "rails_helper"

RSpec.describe YaksController do
  fab!(:user)

  before { sign_in(user) }

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
