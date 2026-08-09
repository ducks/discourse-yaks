import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { eq, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import CustomFlairModal from "../../components/modal/custom-flair";
import CustomTitleModal from "../../components/modal/custom-title";

export default class YaksWallet extends Component {
  @service modal;

  get formattedActivePerks() {
    return (this.args.model.active_perks || []).map((perk) => ({
      ...perk,
      appliedDate: new Date(perk.applied_at).toLocaleDateString(),
      expiresDate: perk.expires_at
        ? new Date(perk.expires_at).toLocaleDateString()
        : null,
      remaining: this.remainingDuration(perk.expires_at),
      targetLabel: this.targetLabel(perk.target),
    }));
  }

  get hasActivePerks() {
    return this.formattedActivePerks.length > 0;
  }

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

  remainingDuration(expiresAt) {
    if (!expiresAt) {
      return i18n("yaks.wallet.active_perks.permanent");
    }

    const remainingMinutes = Math.max(
      1,
      Math.ceil((new Date(expiresAt).getTime() - Date.now()) / 60_000)
    );

    if (remainingMinutes >= 1_440) {
      return i18n("yaks.wallet.active_perks.days_remaining", {
        count: Math.ceil(remainingMinutes / 1_440),
      });
    }

    if (remainingMinutes >= 60) {
      return i18n("yaks.wallet.active_perks.hours_remaining", {
        count: Math.ceil(remainingMinutes / 60),
      });
    }

    return i18n("yaks.wallet.active_perks.minutes_remaining", {
      count: remainingMinutes,
    });
  }

  targetLabel(target) {
    if (target.type === "post" && target.title) {
      return i18n("yaks.wallet.active_perks.post_target", {
        title: target.title,
        post_number: target.post_number,
      });
    }

    if (target.type === "topic" && target.title) {
      return target.title;
    }

    if (target.type === "profile") {
      return i18n("yaks.wallet.active_perks.profile_target");
    }

    return i18n("yaks.wallet.active_perks.unavailable_target");
  }

  @action
  openCustomFlairModal() {
    const feature = this.args.model.features.find(
      (f) => f.key === "custom_flair"
    );
    this.modal.show(CustomFlairModal, { model: { feature } });
  }

  @action
  openCustomTitleModal() {
    const feature = this.args.model.features.find(
      (f) => f.key === "custom_title"
    );
    this.modal.show(CustomTitleModal, { model: { feature } });
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

      {{#if this.hasActivePerks}}
        <section class="active-perks">
          <h2>{{i18n "yaks.wallet.active_perks.title"}}</h2>
          <p class="active-perks__description">
            {{i18n "yaks.wallet.active_perks.description"}}
          </p>
          <div class="active-perks__grid">
            {{#each this.formattedActivePerks as |perk|}}
              <article class="active-perk">
                <div class="active-perk__header">
                  <strong>{{perk.name}}</strong>
                  <span class="active-perk__quantity">
                    {{i18n
                      "yaks.wallet.active_perks.quantity"
                      count=perk.quantity
                    }}
                  </span>
                </div>

                <div class="active-perk__target">
                  {{#if perk.target.url}}
                    <a href={{perk.target.url}}>{{perk.targetLabel}}</a>
                  {{else}}
                    {{perk.targetLabel}}
                  {{/if}}
                </div>

                <div class="active-perk__timing">
                  <span>
                    {{i18n
                      "yaks.wallet.active_perks.applied"
                      date=perk.appliedDate
                    }}
                  </span>
                  {{#if perk.expiresDate}}
                    <span>
                      {{i18n
                        "yaks.wallet.active_perks.expires"
                        date=perk.expiresDate
                      }}
                    </span>
                  {{/if}}
                </div>

                <div class="active-perk__remaining">{{perk.remaining}}</div>
              </article>
            {{/each}}
          </div>
        </section>
      {{/if}}

      {{#if @model.features}}
        <section class="available-features">
          <h2>{{i18n "yaks.features.title"}}</h2>
          <div class="features-grid">
            {{#each @model.features as |feature|}}
              {{#if
                (or
                  (eq feature.key "custom_flair")
                  (eq feature.key "custom_title")
                )
              }}
                <div
                  class="feature-card clickable"
                  role="button"
                  {{on
                    "click"
                    (if
                      (eq feature.key "custom_flair")
                      this.openCustomFlairModal
                      this.openCustomTitleModal
                    )
                  }}
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
              <div class="transaction-item {{if tx.isCredit 'credit' 'debit'}}">
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
