# frozen_string_literal: true

class CreateYakEarningRules < ActiveRecord::Migration[7.0]
  def change
    create_table :yak_earning_rules do |t|
      t.string :action_key, null: false, index: { unique: true }
      t.string :action_name, null: false
      t.text :description
      t.integer :amount, null: false, default: 0
      t.integer :daily_cap, null: false, default: 0
      t.integer :min_trust_level, null: false, default: 1
      t.boolean :enabled, null: false, default: true
      t.jsonb :settings, null: false, default: {}
      t.timestamps
    end

    # Seed default earning rules
    execute <<~SQL
      INSERT INTO yak_earning_rules (action_key, action_name, description, amount, daily_cap, min_trust_level, enabled, settings, created_at, updated_at)
      VALUES
        ('post_created', 'Post Created', 'Earn Yaks for creating a new post', 2, 20, 1, true, '{"min_length": 20}'::jsonb, NOW(), NOW()),
        ('topic_created', 'Topic Created', 'Earn Yaks for creating a new topic', 5, 10, 1, true, '{"min_length": 50}'::jsonb, NOW(), NOW()),
        ('post_liked', 'Post Liked', 'Earn Yaks when someone likes your post', 3, 30, 1, true, '{}'::jsonb, NOW(), NOW()),
        ('solution_accepted', 'Solution Accepted', 'Earn Yaks when your post is marked as solution', 25, 0, 1, true, '{}'::jsonb, NOW(), NOW())
      ON CONFLICT (action_key) DO NOTHING;
    SQL
  end
end
