# frozen_string_literal: true

class YakEarningRule < ActiveRecord::Base
  self.table_name = "yak_earning_rules"

  validates :action_key, presence: true, uniqueness: true
  validates :action_name, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :daily_cap, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :min_trust_level,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 4,
            }

  def self.get_rule(action_key)
    find_by(action_key: action_key, enabled: true)
  end

  def has_daily_cap?
    daily_cap > 0
  end

  def min_length
    settings["min_length"].to_i
  end
end

# == Schema Information
#
# Table name: yak_earning_rules
#
#  id              :bigint           not null, primary key
#  action_key      :string           not null
#  action_name     :string           not null
#  amount          :integer          default(0), not null
#  daily_cap       :integer          default(0), not null
#  description     :text
#  enabled         :boolean          default(TRUE), not null
#  min_trust_level :integer          default(1), not null
#  settings        :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_yak_earning_rules_on_action_key  (action_key) UNIQUE
#
