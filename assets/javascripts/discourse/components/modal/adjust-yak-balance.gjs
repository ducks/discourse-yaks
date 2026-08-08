import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import UserChooser from "discourse/select-kit/components/user-chooser";
import { not, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class AdjustYakBalanceModal extends Component {
  @tracked username;
  @tracked amount;
  @tracked reason;
  @tracked saving = false;

  get canSubmit() {
    return this.username && Number(this.amount) !== 0 && this.reason?.trim();
  }

  @action
  setUsername(usernames) {
    this.username = usernames[0];
  }

  @action
  setAmount(event) {
    this.amount = event.target.value;
  }

  @action
  setReason(event) {
    this.reason = event.target.value;
  }

  @action
  async save() {
    this.saving = true;

    try {
      const result = await ajax("/admin/plugins/yaks/adjust", {
        type: "POST",
        data: {
          username: this.username,
          amount: this.amount,
          reason: this.reason,
        },
      });

      this.args.closeModal(result);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DModal
      @title={{i18n "yaks.admin.adjustment.title"}}
      @closeModal={{@closeModal}}
      class="adjust-yak-balance-modal"
    >
      <:body>
        <div class="form-horizontal">
          <div class="control-group">
            <label class="control-label">
              {{i18n "yaks.admin.adjustment.member"}}
            </label>
            <div class="controls">
              <UserChooser
                @value={{this.username}}
                @onChange={{this.setUsername}}
                @options={{hash maximum=1 excludeCurrentUser=false}}
              />
            </div>
          </div>

          <div class="control-group">
            <label class="control-label" for="yak-adjustment-amount">
              {{i18n "yaks.admin.adjustment.amount"}}
            </label>
            <div class="controls">
              <input
                id="yak-adjustment-amount"
                type="number"
                value={{this.amount}}
                {{on "input" this.setAmount}}
              />
              <p class="help">{{i18n "yaks.admin.adjustment.amount_help"}}</p>
            </div>
          </div>

          <div class="control-group">
            <label class="control-label" for="yak-adjustment-reason">
              {{i18n "yaks.admin.adjustment.reason"}}
            </label>
            <div class="controls">
              <input
                id="yak-adjustment-reason"
                type="text"
                value={{this.reason}}
                {{on "input" this.setReason}}
              />
            </div>
          </div>
        </div>
      </:body>

      <:footer>
        <DButton
          @action={{this.save}}
          @label="yaks.admin.adjustment.submit"
          @disabled={{or (not this.canSubmit) this.saving}}
          class="btn-primary"
        />
        <DButton
          @action={{@closeModal}}
          @label="cancel"
          @disabled={{this.saving}}
          class="btn-default"
        />
      </:footer>
    </DModal>
  </template>
}
