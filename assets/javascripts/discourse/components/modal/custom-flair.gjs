import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq, or, not } from "truth-helpers";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class CustomFlairModal extends Component {
  @service currentUser;
  @tracked selectedIcon = "star";
  @tracked selectedBgColor = "FF0000";
  @tracked selectedColor = "FFFFFF";
  @tracked processing = false;

  icons = [
    { id: "star", name: "Star" },
    { id: "heart", name: "Heart" },
    { id: "fire", name: "Fire" },
    { id: "bolt", name: "Bolt" },
    { id: "gem", name: "Gem" },
    { id: "crown", name: "Crown" },
    { id: "rocket", name: "Rocket" },
    { id: "trophy", name: "Trophy" },
  ];

  bgColors = [
    { id: "FF0000", name: "Red", hex: "#FF0000" },
    { id: "0000FF", name: "Blue", hex: "#0000FF" },
    { id: "00FF00", name: "Green", hex: "#00FF00" },
    { id: "FFD700", name: "Gold", hex: "#FFD700" },
    { id: "9370DB", name: "Purple", hex: "#9370DB" },
    { id: "FF1493", name: "Pink", hex: "#FF1493" },
  ];

  textColors = [
    { id: "FFFFFF", name: "White", hex: "#FFFFFF" },
    { id: "000000", name: "Black", hex: "#000000" },
    { id: "FFD700", name: "Gold", hex: "#FFD700" },
  ];

  get feature() {
    return this.args.model.feature;
  }

  get cost() {
    return this.feature?.cost || 0;
  }

  get balance() {
    return this.currentUser.yak_balance || 0;
  }

  get canAfford() {
    return this.balance >= this.cost;
  }

  @action
  selectIcon(iconId) {
    this.selectedIcon = iconId;
  }

  @action
  selectBgColor(colorId) {
    this.selectedBgColor = colorId;
  }

  @action
  selectColor(colorId) {
    this.selectedColor = colorId;
  }

  @action
  async applyFlair() {
    if (!this.canAfford) return;

    this.processing = true;

    try {
      const data = {
        feature_key: "custom_flair",
        feature_data: {
          icon: this.selectedIcon,
          bg_color: this.selectedBgColor,
          color: this.selectedColor,
        },
      };

      const result = await ajax("/yaks/spend.json", {
        type: "POST",
        data,
      });

      if (result.success) {
        // Update user balance
        this.currentUser.set("yak_balance", result.new_balance);

        // Close modal
        this.args.closeModal();

        // Reload to show flair
        window.location.reload();
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.processing = false;
    }
  }

  <template>
    <DModal
      @title={{i18n "yaks.features.custom_flair.name"}}
      @closeModal={{@closeModal}}
      class="custom-flair-modal"
    >
      <:body>
        <div class="custom-flair-content">
          <div class="balance-display">
            <strong>{{i18n "yaks.wallet.balance"}}:</strong>
            {{this.balance}}
            Yaks (Cost: {{this.cost}} Yaks)
          </div>

          <div class="flair-preview">
            <h3>Preview</h3>
            <div
              class="flair-badge"
              style="background-color: #{{this.selectedBgColor}}; color: #{{this.selectedColor}};"
            >
              <svg class="fa d-icon d-icon-{{this.selectedIcon}} svg-icon svg-string" xmlns="http://www.w3.org/2000/svg"><use href="#{{this.selectedIcon}}"></use></svg>
            </div>
          </div>

          <div class="icon-picker">
            <h3>Choose Icon</h3>
            <div class="icon-options">
              {{#each this.icons as |icon|}}
                <div
                  class="icon-option {{if
                    (eq this.selectedIcon icon.id)
                    'selected'
                  }}"
                  role="button"
                  {{on "click" (fn this.selectIcon icon.id)}}
                >
                  <svg class="fa d-icon d-icon-{{icon.id}} svg-icon svg-string" xmlns="http://www.w3.org/2000/svg"><use href="#{{icon.id}}"></use></svg>
                  <span>{{icon.name}}</span>
                </div>
              {{/each}}
            </div>
          </div>

          <div class="color-picker">
            <h3>Background Color</h3>
            <div class="color-options">
              {{#each this.bgColors as |color|}}
                <div
                  class="color-swatch {{if
                    (eq this.selectedBgColor color.id)
                    'selected'
                  }}"
                  style="background-color: {{color.hex}};"
                  role="button"
                  {{on "click" (fn this.selectBgColor color.id)}}
                  title={{color.name}}
                ></div>
              {{/each}}
            </div>
          </div>

          <div class="color-picker">
            <h3>Text Color</h3>
            <div class="color-options">
              {{#each this.textColors as |color|}}
                <div
                  class="color-swatch {{if
                    (eq this.selectedColor color.id)
                    'selected'
                  }}"
                  style="background-color: {{color.hex}};"
                  role="button"
                  {{on "click" (fn this.selectColor color.id)}}
                  title={{color.name}}
                ></div>
              {{/each}}
            </div>
          </div>

          {{#unless this.canAfford}}
            <div class="insufficient-balance">
              {{i18n "yaks.errors.insufficient_balance"}}
            </div>
          {{/unless}}
        </div>
      </:body>

      <:footer>
        <DButton
          @action={{this.applyFlair}}
          @label="yaks.modal.apply"
          @disabled={{or (not this.canAfford) this.processing}}
          class="btn-primary"
        />
        <DButton
          @action={{@closeModal}}
          @label="cancel"
          class="btn-default"
        />
      </:footer>
    </DModal>
  </template>
}
