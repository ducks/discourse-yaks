import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class EditYakEarningRuleModal extends Component {
  @service modal;
  @tracked amount;
  @tracked dailyCap;
  @tracked minTrustLevel;
  @tracked enabled;
  @tracked saving = false;

  constructor() {
    super(...arguments);
    const rule = this.args.model.rule;
    this.amount = rule.amount;
    this.dailyCap = rule.daily_cap;
    this.minTrustLevel = rule.min_trust_level;
    this.enabled = rule.enabled;
  }

  @action
  async save() {
    this.saving = true;

    try {
      await ajax(`/admin/plugins/yaks/earning_rules/${this.args.model.rule.id}`, {
        type: "PUT",
        data: {
          amount: this.amount,
          daily_cap: this.dailyCap,
          min_trust_level: this.minTrustLevel,
          enabled: this.enabled,
        },
      });

      this.args.closeModal();
      return true;
    } catch (error) {
      popupAjaxError(error);
      return false;
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DModal
      @title="Edit Earning Rule"
      @closeModal={{@closeModal}}
      class="edit-yak-earning-rule-modal"
    >
      <:body>
        <form class="form-horizontal">
          <div class="control-group">
            <label>Action</label>
            <div class="controls">
              <strong>{{@model.rule.action_name}}</strong>
              <p class="help">{{@model.rule.description}}</p>
            </div>
          </div>

          <div class="control-group">
            <label for="amount">Amount (Yaks)</label>
            <div class="controls">
              <input
                id="amount"
                type="number"
                min="0"
                value={{this.amount}}
                {{on "input" (fn (mut this.amount) value="target.value")}}
              />
            </div>
          </div>

          <div class="control-group">
            <label for="daily-cap">Daily Cap (0 = unlimited)</label>
            <div class="controls">
              <input
                id="daily-cap"
                type="number"
                min="0"
                value={{this.dailyCap}}
                {{on "input" (fn (mut this.dailyCap) value="target.value")}}
              />
            </div>
          </div>

          <div class="control-group">
            <label for="min-trust-level">Minimum Trust Level</label>
            <div class="controls">
              <select
                id="min-trust-level"
                value={{this.minTrustLevel}}
                {{on "change" (fn (mut this.minTrustLevel) value="target.value")}}
              >
                <option value="0">TL0 (New User)</option>
                <option value="1">TL1 (Basic User)</option>
                <option value="2">TL2 (Member)</option>
                <option value="3">TL3 (Regular)</option>
                <option value="4">TL4 (Leader)</option>
              </select>
            </div>
          </div>

          <div class="control-group">
            <label>
              <input
                type="checkbox"
                checked={{this.enabled}}
                {{on "change" (fn (mut this.enabled) value="target.checked")}}
              />
              Enabled
            </label>
          </div>
        </form>
      </:body>

      <:footer>
        <DButton
          @action={{this.save}}
          @label="Save"
          @disabled={{this.saving}}
          class="btn-primary"
        />
        <DButton
          @action={{@closeModal}}
          @label="Cancel"
          @disabled={{this.saving}}
          class="btn-default"
        />
      </:footer>
    </DModal>
  </template>
}
