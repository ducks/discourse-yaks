# frozen_string_literal: true

require "rails_helper"

RSpec.describe YakFeature do
  describe "validations" do
    it { should validate_presence_of(:feature_key) }
    it { should validate_presence_of(:feature_name) }
    it { should validate_presence_of(:cost) }
    it { should validate_numericality_of(:cost).is_greater_than(0) }

    it "validates uniqueness of feature_key" do
      YakFeature.create!(
        feature_key: "test_feature",
        feature_name: "Test",
        cost: 10,
        category: "post",
      )
      duplicate = YakFeature.new(feature_key: "test_feature", feature_name: "Test 2", cost: 20)
      expect(duplicate).not_to be_valid
    end

    it "validates category is valid" do
      feature = YakFeature.new(feature_key: "test", feature_name: "Test", cost: 10)

      feature.category = "post"
      expect(feature).to be_valid

      feature.category = "user"
      expect(feature).to be_valid

      feature.category = "topic"
      expect(feature).to be_valid

      feature.category = nil
      expect(feature).to be_valid

      feature.category = "invalid"
      expect(feature).not_to be_valid
    end
  end

  describe "associations" do
    it { should have_many(:yak_feature_uses).dependent(:destroy) }
  end

  describe "scopes" do
    let!(:enabled_post) do
      YakFeature.create!(
        feature_key: "enabled_post",
        feature_name: "Enabled Post",
        cost: 10,
        category: "post",
        enabled: true,
      )
    end
    let!(:disabled_post) do
      YakFeature.create!(
        feature_key: "disabled_post",
        feature_name: "Disabled Post",
        cost: 20,
        category: "post",
        enabled: false,
      )
    end
    let!(:enabled_user) do
      YakFeature.create!(
        feature_key: "enabled_user",
        feature_name: "Enabled User",
        cost: 30,
        category: "user",
        enabled: true,
      )
    end

    describe ".enabled" do
      it "returns only enabled features" do
        expect(YakFeature.enabled).to contain_exactly(enabled_post, enabled_user)
      end
    end

    describe ".by_category" do
      it "filters by category" do
        expect(YakFeature.by_category("post")).to contain_exactly(enabled_post, disabled_post)
        expect(YakFeature.by_category("user")).to contain_exactly(enabled_user)
      end
    end
  end

  describe ".seed_default_features" do
    it "creates all default features" do
      expect { YakFeature.seed_default_features }.to change { YakFeature.count }.by(4)
    end

    it "creates post_highlight feature" do
      YakFeature.seed_default_features
      feature = YakFeature.find_by(feature_key: "post_highlight")

      expect(feature).to be_present
      expect(feature.feature_name).to eq("Post Highlighting")
      expect(feature.cost).to eq(25)
      expect(feature.category).to eq("post")
      expect(feature.enabled).to be true
    end

    it "creates post_pin feature" do
      YakFeature.seed_default_features
      feature = YakFeature.find_by(feature_key: "post_pin")

      expect(feature).to be_present
      expect(feature.cost).to eq(50)
      expect(feature.settings["duration_hours"]).to eq(24)
    end

    it "creates custom_flair feature" do
      YakFeature.seed_default_features
      feature = YakFeature.find_by(feature_key: "custom_flair")

      expect(feature).to be_present
      expect(feature.cost).to eq(100)
      expect(feature.category).to eq("user")
      expect(feature.settings["duration_days"]).to eq(30)
    end

    it "creates post_boost feature" do
      YakFeature.seed_default_features
      feature = YakFeature.find_by(feature_key: "post_boost")

      expect(feature).to be_present
      expect(feature.cost).to eq(30)
      expect(feature.settings["duration_hours"]).to eq(72)
    end

    it "does not create duplicates if called multiple times" do
      YakFeature.seed_default_features
      expect { YakFeature.seed_default_features }.not_to change { YakFeature.count }
    end
  end

  describe "#affordable_by?" do
    fab!(:user) { Fabricate(:user, yak_balance: 50) }
    let(:cheap_feature) do
      YakFeature.create!(feature_key: "cheap", feature_name: "Cheap", cost: 25, category: "post")
    end
    let(:expensive_feature) do
      YakFeature.create!(
        feature_key: "expensive",
        feature_name: "Expensive",
        cost: 100,
        category: "post",
      )
    end

    it "returns true if user can afford feature" do
      expect(cheap_feature.affordable_by?(user)).to be true
    end

    it "returns false if user cannot afford feature" do
      expect(expensive_feature.affordable_by?(user)).to be false
    end

    it "returns true if user has exact amount" do
      exact_feature =
        YakFeature.create!(feature_key: "exact", feature_name: "Exact", cost: 50, category: "post")
      expect(exact_feature.affordable_by?(user)).to be true
    end
  end
end
