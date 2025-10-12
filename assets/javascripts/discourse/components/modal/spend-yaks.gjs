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

export default class SpendYaksModal extends Component {
  @service currentUser;
  @tracked selectedFeature = null;
  @tracked selectedColor = "gold";
  @tracked processing = false;

  postFeatures = [
    {
      id: "post_highlight",
      name: i18n("yaks.features.post_highlight.name"),
      description: i18n("yaks.features.post_highlight.description"),
      cost: 25,
      hasOptions: true,
    },
    {
      id: "post_pin",
      name: i18n("yaks.features.post_pin.name"),
      description: i18n("yaks.features.post_pin.description"),
      cost: 50,
      hasOptions: false,
    },
    {
      id: "post_boost",
      name: i18n("yaks.features.post_boost.name"),
      description: i18n("yaks.features.post_boost.description"),
      cost: 30,
      hasOptions: false,
    },
  ];

  topicFeatures = [
    {
      id: "topic_pin",
      name: i18n("yaks.features.topic_pin.name"),
      description: i18n("yaks.features.topic_pin.description"),
      cost: 100,
      hasOptions: false,
    },
  ];

  colors = [
    { id: "gold", name: "Gold" },
    { id: "blue", name: "Blue" },
    { id: "red", name: "Red" },
    { id: "green", name: "Green" },
    { id: "purple", name: "Purple" },
  ];

  get isPostContext() {
    return !!this.args.model.post;
  }

  get isTopicContext() {
    return !!this.args.model.topic;
  }

  get features() {
    return this.isPostContext ? this.postFeatures : this.topicFeatures;
  }

  get balance() {
    return this.currentUser.yak_balance || 0;
  }

  get selectedFeatureData() {
    return this.features.find((f) => f.id === this.selectedFeature);
  }

  get canAfford() {
    if (!this.selectedFeatureData) return false;
    return this.balance >= this.selectedFeatureData.cost;
  }

  @action
  selectFeature(featureId) {
    this.selectedFeature = featureId;
  }

  @action
  selectColor(colorId) {
    this.selectedColor = colorId;
  }

  @action
  async applyFeature() {
    if (!this.selectedFeature || !this.canAfford) return;

    this.processing = true;

    try {
      const data = {
        feature_key: this.selectedFeature,
        feature_data: {},
      };

      // Add the appropriate ID based on context
      if (this.isPostContext) {
        data.post_id = this.args.model.post.id;
      } else if (this.isTopicContext) {
        data.topic_id = this.args.model.topic.id;
      }

      if (this.selectedFeature === "post_highlight") {
        data.feature_data.color = this.selectedColor;
      }

      const result = await ajax("/yaks/spend.json", {
        type: "POST",
        data,
      });

      if (result.success) {
        // Update user balance
        this.currentUser.set("yak_balance", result.new_balance);

        // Close modal
        this.args.closeModal();

        // Reload the page to show the changes
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
      @title={{i18n "yaks.modal.title"}}
      @closeModal={{@closeModal}}
      class="spend-yaks-modal"
    >
      <:body>
        <div class="spend-yaks-content">
          <div class="balance-display">
            <strong>{{i18n "yaks.wallet.balance"}}:</strong>
            {{this.balance}}
            Yaks
          </div>

          <div class="features-list">
            <h3>{{i18n "yaks.modal.select_feature"}}</h3>

            {{#each this.features as |feature|}}
              <div
                class="feature-option {{if
                  (eq this.selectedFeature feature.id)
                  'selected'
                }}"
                role="button"
                {{on "click" (fn this.selectFeature feature.id)}}
              >
                <div class="feature-info">
                  <div class="feature-name">{{feature.name}}</div>
                  <div class="feature-description">{{feature.description}}</div>
                </div>
                <div class="feature-cost">{{feature.cost}} Yaks</div>
              </div>
            {{/each}}
          </div>

          {{#if (eq this.selectedFeature "post_highlight")}}
            <div class="color-picker">
              <h3>{{i18n "yaks.modal.select_color"}}</h3>
              <div class="color-options">
                {{#each this.colors as |color|}}
                  <div
                    class="color-option {{if
                      (eq this.selectedColor color.id)
                      'selected'
                    }}"
                    data-color={{color.id}}
                    role="button"
                    {{on "click" (fn this.selectColor color.id)}}
                  >
                    {{color.name}}
                  </div>
                {{/each}}
              </div>
            </div>
          {{/if}}

          {{#if this.selectedFeature}}
            {{#unless this.canAfford}}
              <div class="insufficient-balance">
                {{i18n "yaks.errors.insufficient_balance"}}
              </div>
            {{/unless}}
          {{/if}}
        </div>
      </:body>

      <:footer>
        <DButton
          @action={{this.applyFeature}}
          @label="yaks.modal.apply"
          @disabled={{or (not this.selectedFeature) (not this.canAfford) this.processing}}
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
