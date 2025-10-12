# frozen_string_literal: true

class AddTopicPinFeature < ActiveRecord::Migration[7.0]
  def up
    # Add topic_pin feature
    execute <<~SQL
      INSERT INTO yak_features (feature_key, feature_name, description, cost, enabled, category, settings, created_at, updated_at)
      VALUES (
        'topic_pin',
        'Pin Topic',
        'Pin your topic to the top of the category for 24 hours',
        100,
        true,
        'topic',
        '{"duration_hours": 24}'::jsonb,
        NOW(),
        NOW()
      )
      ON CONFLICT (feature_key) DO NOTHING;
    SQL
  end

  def down
    execute "DELETE FROM yak_features WHERE feature_key = 'topic_pin'"
  end
end
