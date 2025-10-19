/**
 * Shared quantity calculation logic for Yak features
 */
export class YakFeatureQuantity {
  constructor(feature, quantity = 1) {
    this.feature = feature;
    this._quantity = quantity;
  }

  get quantity() {
    return this._quantity;
  }

  set quantity(value) {
    const parsed = parseInt(value, 10);
    if (parsed >= 1 && parsed <= 12) {
      this._quantity = parsed;
    }
  }

  get baseCost() {
    return this.feature?.cost || 0;
  }

  get totalCost() {
    return this.baseCost * this._quantity;
  }

  get baseDuration() {
    return this.feature?.settings?.duration_days || 30;
  }

  get totalDuration() {
    return this.baseDuration * this._quantity;
  }

  canAfford(userBalance) {
    return userBalance >= this.totalCost;
  }
}
