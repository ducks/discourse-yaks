# frozen_string_literal: true

class NormalizeYakFeatureKeys < ActiveRecord::Migration[7.0]
  LEGACY_KEYS = {
    "highlight" => {
      key: "post_highlight",
      cost: 25,
      settings: '{"default_color":"gold","duration":null}',
    },
    "pin" => {
      key: "post_pin",
      cost: 50,
      settings: '{"duration_hours":24}',
    },
    "boost" => {
      key: "post_boost",
      cost: 30,
      settings: '{"duration_hours":72}',
    },
  }.freeze

  def up
    LEGACY_KEYS.each do |legacy_key, attributes|
      canonical_key = attributes[:key]
      legacy_id = select_value(<<~SQL)
        SELECT id FROM yak_features WHERE feature_key = #{connection.quote(legacy_key)}
      SQL
      next if legacy_id.blank?

      canonical_id = select_value(<<~SQL)
        SELECT id FROM yak_features WHERE feature_key = #{connection.quote(canonical_key)}
      SQL

      if canonical_id.present?
        execute <<~SQL
          UPDATE yak_feature_uses
          SET yak_feature_id = #{connection.quote(canonical_id)}
          WHERE yak_feature_id = #{connection.quote(legacy_id)}
        SQL
        execute <<~SQL
          DELETE FROM yak_features WHERE id = #{connection.quote(legacy_id)}
        SQL
      else
        execute <<~SQL
          UPDATE yak_features
          SET feature_key = #{connection.quote(canonical_key)},
              cost = #{attributes[:cost]},
              settings = #{connection.quote(attributes[:settings])}::jsonb,
              updated_at = NOW()
          WHERE id = #{connection.quote(legacy_id)}
        SQL
      end
    end
  end

  def down
    LEGACY_KEYS.each do |legacy_key, attributes|
      canonical_key = attributes[:key]
      execute <<~SQL
        UPDATE yak_features
        SET feature_key = #{connection.quote(legacy_key)}, updated_at = NOW()
        WHERE feature_key = #{connection.quote(canonical_key)}
          AND NOT EXISTS (
            SELECT 1 FROM yak_features WHERE feature_key = #{connection.quote(legacy_key)}
          )
      SQL
    end
  end
end
