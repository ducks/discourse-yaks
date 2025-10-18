# frozen_string_literal: true

class AddTopicBoostFeature < ActiveRecord::Migration[7.0]
  def up
    # Add topic_boost feature
    execute <<~SQL
      INSERT INTO yak_features (feature_key, feature_name, description, cost, enabled, category, settings, created_at, updated_at)
      VALUES (
        'topic_boost',
        'Boost Topic',
        'Pin your topic globally with visual highlighting',
        150,
        true,
        'topic',
        '{"duration_hours": 72}'::jsonb,
        NOW(),
        NOW()
      )
      ON CONFLICT (feature_key) DO NOTHING;
    SQL
  end

  def down
    execute "DELETE FROM yak_features WHERE feature_key = 'topic_boost'"
  end
end
