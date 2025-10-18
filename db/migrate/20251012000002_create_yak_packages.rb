# frozen_string_literal: true

class CreateYakPackages < ActiveRecord::Migration[7.0]
  def change
    create_table :yak_packages do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.integer :yaks, null: false, default: 0
      t.integer :bonus_yaks, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :yak_packages, :enabled
    add_index :yak_packages, :position

    # Seed existing packages from site settings
    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO yak_packages (name, description, price_cents, yaks, bonus_yaks, enabled, position, created_at, updated_at)
          VALUES 
            ('Starter Pack', '100 Yaks + bonus', 500, 100, 0, true, 1, NOW(), NOW()),
            ('Value Pack', '200 Yaks + 25 bonus', 1000, 200, 25, true, 2, NOW(), NOW()),
            ('Premium Pack', '500 Yaks + 75 bonus', 2500, 500, 75, true, 3, NOW(), NOW()),
            ('Ultimate Pack', '1000 Yaks + 200 bonus', 5000, 1000, 200, true, 4, NOW(), NOW());
        SQL
      end
    end
  end
end
