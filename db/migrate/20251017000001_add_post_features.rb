# frozen_string_literal: true

class AddPostFeatures < ActiveRecord::Migration[7.0]
  def up
    # Add post highlighting feature
    execute <<~SQL
      INSERT INTO yak_features (feature_key, feature_name, description, cost, enabled, category, settings, created_at, updated_at)
      VALUES (
        'highlight',
        'Post Highlighting',
        'Add a colored border and background to your post',
        10,
        true,
        'post',
        '{"duration_hours": 168}'::jsonb,
        NOW(),
        NOW()
      )
      ON CONFLICT (feature_key) DO NOTHING;
    SQL

    # Add post pin feature
    execute <<~SQL
      INSERT INTO yak_features (feature_key, feature_name, description, cost, enabled, category, settings, created_at, updated_at)
      VALUES (
        'pin',
        'Pin Post',
        'Pin your post to the top of a topic',
        50,
        true,
        'post',
        '{"duration_hours": 24}'::jsonb,
        NOW(),
        NOW()
      )
      ON CONFLICT (feature_key) DO NOTHING;
    SQL

    # Add post boost feature
    execute <<~SQL
      INSERT INTO yak_features (feature_key, feature_name, description, cost, enabled, category, settings, created_at, updated_at)
      VALUES (
        'boost',
        'Post Boost',
        'Boost your post in feeds and search',
        100,
        true,
        'post',
        '{"duration_hours": 72}'::jsonb,
        NOW(),
        NOW()
      )
      ON CONFLICT (feature_key) DO NOTHING;
    SQL
  end

  def down
    execute "DELETE FROM yak_features WHERE feature_key IN ('highlight', 'pin', 'boost')"
  end
end
