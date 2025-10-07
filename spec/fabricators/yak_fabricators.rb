# frozen_string_literal: true

Fabricator(:yak_wallet) do
  user
  balance 0
  lifetime_earned 0
  lifetime_spent 0
end

Fabricator(:yak_transaction) do
  user
  yak_wallet
  amount 10
  transaction_type "earn"
  source "test"
  description "Test transaction"
end

Fabricator(:yak_feature) do
  feature_key { sequence(:feature_key) { |i| "test_feature_#{i}" } }
  feature_name { sequence(:feature_name) { |i| "Test Feature #{i}" } }
  description "A test feature"
  cost 25
  enabled true
  category "post"
end

Fabricator(:yak_feature_use) do
  user
  yak_feature
  yak_transaction
end
