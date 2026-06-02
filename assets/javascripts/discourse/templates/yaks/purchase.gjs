import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import DButton from "discourse/components/d-button";

export default class YaksPurchase extends Component {
  <template>
    <div class="yak-purchase-page">
      <div class="purchase-header">
        <h1>{{i18n "yaks.wallet.purchase_yaks"}}</h1>
        <p>{{i18n "yaks.purchase.unavailable"}}</p>
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
