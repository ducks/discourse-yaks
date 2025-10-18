# frozen_string_literal: true

# Defines purchasable Yak packages.
#
# @class YakPackage
class YakPackage < ActiveRecord::Base
  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :yaks, presence: true, numericality: { greater_than: 0 }
  validates :bonus_yaks, numericality: { greater_than_or_equal_to: 0 }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(:position) }

  # Get total yaks for this package.
  #
  # @returns [Integer] Total yaks including bonus
  def total_yaks
    yaks + bonus_yaks
  end

  # Get price in dollars.
  #
  # @returns [Float] Price in USD
  def price_usd
    price_cents / 100.0
  end

  # Set price in dollars.
  #
  # @param usd [Float] Price in USD
  def price_usd=(usd)
    self.price_cents = (usd.to_f * 100).to_i
  end
end
