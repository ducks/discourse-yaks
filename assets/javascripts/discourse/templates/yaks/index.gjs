import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { eq } from "truth-helpers";
import { i18n } from "discourse-i18n";
import DButton from "discourse/components/d-button";
import CustomFlairModal from "../../components/modal/custom-flair";

export default class YaksWallet extends Component {
  @service router;
  @service modal;

  get formattedTransactions() {
    return (this.args.model.transactions || []).map((tx) => {
      const date = new Date(tx.created_at);
      return {
        ...tx,
        formattedDate: date.toLocaleDateString(),
        formattedTime: date.toLocaleTimeString(),
        isCredit: tx.amount > 0,
        displayAmount: Math.abs(tx.amount),
      };
    });
  }

  @action
  openCustomFlairModal() {
    this.modal.show(CustomFlairModal);
  }

  <template>
    <div class="yak-wallet-page">
      <div class="wallet-header">
        <div>
          <h1>{{i18n "yaks.wallet.title"}}</h1>
          <div class="balance">
            {{@model.balance}}
            Yaks
          </div>
        </div>
        <DButton
          @route="yaks.purchase"
          @label="yaks.wallet.purchase_yaks"
          @icon="coins"
          class="btn-primary"
        />
      </div>

      <div class="wallet-stats">
        <div class="stat-card">
          <div class="label">{{i18n "yaks.wallet.lifetime_earned"}}</div>
          <div class="value">{{@model.lifetime_earned}}</div>
        </div>
        <div class="stat-card">
          <div class="label">{{i18n "yaks.wallet.lifetime_spent"}}</div>
          <div class="value">{{@model.lifetime_spent}}</div>
        </div>
        <div class="stat-card">
          <div class="label">{{i18n "yaks.wallet.balance"}}</div>
          <div class="value">{{@model.balance}}</div>
        </div>
      </div>

      {{#if @model.features}}
        <section class="available-features">
          <h2>{{i18n "yaks.features.title"}}</h2>
          <div class="features-grid">
            {{#each @model.features as |feature|}}
              {{#if (eq feature.key "custom_flair")}}
                <div
                  class="feature-card clickable"
                  role="button"
                  {{on "click" this.openCustomFlairModal}}
                >
                  <div class="feature-name">{{feature.name}}</div>
                  <div class="feature-description">{{feature.description}}</div>
                  <div class="feature-cost">
                    <span class="cost">{{feature.cost}} Yaks</span>
                    {{#if feature.affordable}}
                      <span class="affordable">✓</span>
                    {{else}}
                      <span class="not-affordable">✗</span>
                    {{/if}}
                  </div>
                </div>
              {{else}}
                <div class="feature-card">
                  <div class="feature-name">{{feature.name}}</div>
                  <div class="feature-description">{{feature.description}}</div>
                  <div class="feature-cost">
                    <span class="cost">{{feature.cost}} Yaks</span>
                    {{#if feature.affordable}}
                      <span class="affordable">✓</span>
                    {{else}}
                      <span class="not-affordable">✗</span>
                    {{/if}}
                  </div>
                </div>
              {{/if}}
            {{/each}}
          </div>
        </section>
      {{/if}}

      {{#if this.formattedTransactions}}
        <section class="transaction-history">
          <h2>{{i18n "yaks.wallet.transaction_history"}}</h2>
          <div class="transactions-list">
            {{#each this.formattedTransactions as |tx|}}
              <div class="transaction-item {{if tx.isCredit "credit" "debit"}}">
                <div class="description">
                  <strong>{{tx.description}}</strong>
                  <div class="meta">
                    {{tx.formattedDate}}
                    {{tx.formattedTime}}
                  </div>
                </div>
                <div class="amount">
                  {{if tx.isCredit "+" "-"}}{{tx.displayAmount}}
                </div>
              </div>
            {{/each}}
          </div>
        </section>
      {{/if}}
    </div>
  </template>
}
