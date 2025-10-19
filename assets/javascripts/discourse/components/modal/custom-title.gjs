import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { eq, or, not } from "truth-helpers";
import { concat } from "@ember/helper";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { YakFeatureQuantity } from "discourse/plugins/discourse-yaks/discourse/lib/yak-feature-quantity";

export default class CustomTitleModal extends Component {
  @service currentUser;
  @tracked titleText = "";
  @tracked processing = false;
  @tracked quantityCalc;

  constructor() {
    super(...arguments);
    this.quantityCalc = new YakFeatureQuantity(this.args.model.feature, 1);
  }

  get quantity() {
    return this.quantityCalc.quantity;
  }

  get baseCost() {
    return this.quantityCalc.baseCost;
  }

  get totalCost() {
    return this.quantityCalc.totalCost;
  }

  get baseDuration() {
    return this.quantityCalc.baseDuration;
  }

  get totalDuration() {
    return this.quantityCalc.totalDuration;
  }

  get balance() {
    return this.currentUser.yak_balance || 0;
  }

  get canAfford() {
    return this.quantityCalc.canAfford(this.balance);
  }

  get canSubmit() {
    return this.canAfford && this.titleText.trim().length > 0 && this.titleText.trim().length <= 50;
  }

  @action
  updateTitle(event) {
    this.titleText = event.target.value;
  }

  @action
  updateQuantity(event) {
    this.quantityCalc.quantity = event.target.value;
    // Force Ember to notice the change
    this.quantityCalc = this.quantityCalc;
  }

  @action
  async applyTitle() {
    if (!this.canSubmit) return;

    this.processing = true;

    try {
      const data = {
        feature_key: "custom_title",
        quantity: this.quantity,
        feature_data: {
          text: this.titleText.trim(),
        },
      };

      const response = await ajax("/yaks/spend", {
        type: "POST",
        data,
      });

      // Update user's balance
      this.currentUser.set("yak_balance", response.new_balance);

      // Reload to show new title
      window.location.reload();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.processing = false;
    }
  }

  <template>
    <DModal
      @title="Custom User Title"
      @closeModal={{@closeModal}}
      class="custom-title-modal"
    >
      <:body>
        <div class="custom-title-form">
          <div class="form-group">
            <label for="title-input">Your Custom Title</label>
            <input
              id="title-input"
              type="text"
              class="title-input"
              placeholder="Enter your custom title (max 50 characters)"
              value={{this.titleText}}
              maxlength="50"
              {{on "input" this.updateTitle}}
            />
            <div class="character-count">
              {{this.titleText.length}} / 50 characters
            </div>
          </div>

          <div class="form-group">
            <label for="quantity-input">Duration (months)</label>
            <input
              id="quantity-input"
              type="number"
              class="quantity-input"
              min="1"
              max="12"
              value={{this.quantity}}
              {{on "input" this.updateQuantity}}
            />
            <div class="duration-display">
              {{this.totalDuration}} days ({{this.quantity}} month{{#if (not (eq this.quantity 1))}}s{{/if}})
            </div>
          </div>

          <div class="preview-section">
            <h4>Preview</h4>
            <div class="title-preview">
              <span class="username">{{this.currentUser.username}}</span>
              {{#if this.titleText}}
                <span class="user-title">{{this.titleText}}</span>
              {{else}}
                <span class="user-title placeholder">Your title here</span>
              {{/if}}
            </div>
          </div>

          <div class="cost-info">
            <strong>Cost:</strong> {{this.totalCost}} Yaks ({{this.baseCost}} × {{this.quantity}})
            <br />
            <strong>Your Balance:</strong> {{this.balance}} Yaks
            {{#if (not this.canAfford)}}
              <div class="insufficient-balance">
                Insufficient balance!
              </div>
            {{/if}}
          </div>
        </div>
      </:body>

      <:footer>
        <DButton
          @action={{this.applyTitle}}
          @disabled={{or (not this.canSubmit) this.processing}}
          @translatedLabel={{if
            this.processing
            (i18n "yaks.applying")
            (concat (i18n "yaks.apply_custom_title") " (" this.totalCost " " (i18n "yaks.currency") ")")
          }}
          class="btn-primary"
        />
        <DButton
          @action={{@closeModal}}
          @disabled={{this.processing}}
          @translatedLabel={{i18n "cancel"}}
        />
      </:footer>
    </DModal>
  </template>
}
