# frozen_string_literal: true

class AddCustomFlairFeature < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      INSERT INTO yak_features (feature_key, feature_name, description, cost, enabled, category, settings, created_at, updated_at)
      VALUES (
        'custom_flair',
        'Custom Avatar Flair',
        'Add a custom badge next to your avatar for 30 days',
        200,
        true,
        'user',
        '{"duration_hours": 720}'::jsonb,
        NOW(),
        NOW()
      )
      ON CONFLICT (feature_key) DO NOTHING;
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM yak_features WHERE feature_key = 'custom_flair';
    SQL
  end
end
