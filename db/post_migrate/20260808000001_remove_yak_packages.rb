# frozen_string_literal: true

class RemoveYakPackages < ActiveRecord::Migration[7.0]
  def up
    drop_table :yak_packages, if_exists: true
  end

  def down
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
  end
end
