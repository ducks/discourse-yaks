import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { i18n } from "discourse-i18n";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class YaksPurchase extends Component {
  @service router;
  @service currentUser;
  @tracked purchasing = false;

  @action
  async purchasePackage(pkg) {
    if (this.purchasing) {
      return;
    }

    this.purchasing = true;

    try {
      const result = await ajax("/yaks/purchase.json", {
        type: "POST",
        data: { amount: pkg.amount },
      });

      if (result.success) {
        // Update user balance
        this.currentUser.set("yak_balance", result.new_balance);

        // Show success message and redirect
        // TODO: Add proper notification
        alert(
          `Successfully purchased ${result.yaks_added} Yaks! New balance: ${result.new_balance}`
        );
        this.router.transitionTo("yaks");
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.purchasing = false;
    }
  }

  <template>
    <div class="yak-purchase-page">
      <div class="purchase-header">
        <h1>{{i18n "yaks.wallet.purchase_yaks"}}</h1>
        <p>Choose a package to add Yaks to your wallet</p>
      </div>

      <div class="packages-grid">
        {{#each @model.packages as |pkg|}}
          <div class="package-card">
            <div class="package-amount">${{pkg.amount}}</div>
            <div class="package-yaks">
              {{pkg.yaks}}
              Yaks
              {{#if pkg.bonus}}
                <span class="bonus">+ {{pkg.bonus}} bonus</span>
              {{/if}}
            </div>
            <div class="package-total">
              Total: {{pkg.total}} Yaks
            </div>
            <DButton
              @action={{this.purchasePackage}}
              @actionParam={{pkg}}
              @label="yaks.purchase.buy_now"
              @icon="shopping-cart"
              @disabled={{this.purchasing}}
              class="btn-primary package-buy-button"
            />
          </div>
        {{/each}}
      </div>

      <div class="purchase-footer">
        <DButton
          @route="yaks"
          @label="yaks.purchase.back_to_wallet"
          class="btn-default"
        />
      </div>
    </div>
  </template>
}
