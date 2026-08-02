# frozen_string_literal: true

class DisableUnfinishedPostFeatures < ActiveRecord::Migration[7.0]
  FEATURE_KEYS = %w[post_pin post_boost].freeze

  def up
    execute <<~SQL
      UPDATE yak_features
      SET enabled = FALSE, updated_at = NOW()
      WHERE feature_key IN (#{FEATURE_KEYS.map { |key| connection.quote(key) }.join(", ")})
    SQL
  end

  def down
    execute <<~SQL
      UPDATE yak_features
      SET enabled = TRUE, updated_at = NOW()
      WHERE feature_key IN (#{FEATURE_KEYS.map { |key| connection.quote(key) }.join(", ")})
    SQL
  end
end
