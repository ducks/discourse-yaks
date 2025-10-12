# frozen_string_literal: true

class AddProcessedAtToYakFeatureUses < ActiveRecord::Migration[7.0]
  def change
    add_column :yak_feature_uses, :processed_at, :datetime
    add_index :yak_feature_uses, :processed_at
  end
end
