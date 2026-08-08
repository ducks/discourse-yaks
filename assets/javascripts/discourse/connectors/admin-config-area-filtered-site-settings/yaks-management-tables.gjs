import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import AdjustYakBalanceModal from "../../components/modal/adjust-yak-balance";
import EditYakEarningRuleModal from "../../components/modal/edit-yak-earning-rule";
import EditYakFeatureModal from "../../components/modal/edit-yak-feature";

export default class YaksManagementTables extends Component {
  @service modal;

  @tracked stats = null;
  @tracked features = [];
  @tracked earningRules = [];
  @tracked economy = null;
  @tracked loading = true;

  constructor() {
    super(...arguments);
    this.loadData();
  }

  async loadData() {
    try {
      const statsData = await ajax("/admin/plugins/yaks/stats");
      const featuresData = await ajax("/admin/plugins/yaks/features");
      const earningRulesData = await ajax("/admin/plugins/yaks/earning_rules");
      const economyData = await ajax("/admin/plugins/yaks/economy");

      this.stats = statsData;
      this.features = featuresData.features;
      this.earningRules = earningRulesData.earning_rules;
      this.economy = economyData;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  async editFeature(feature) {
    const result = await this.modal.show(EditYakFeatureModal, {
      model: { feature },
    });
    if (result) {
      await this.loadData();
    }
  }

  @action
  async editEarningRule(rule) {
    const result = await this.modal.show(EditYakEarningRuleModal, {
      model: { rule },
    });
    if (result) {
      await this.loadData();
    }
  }

  @action
  async adjustBalance() {
    const result = await this.modal.show(AdjustYakBalanceModal);
    if (result) {
      await this.loadData();
    }
  }

  featureDuration(feature) {
    if (feature.settings?.duration_hours) {
      return `${feature.settings.duration_hours} ${i18n("yaks.admin.features.hours")}`;
    }

    if (feature.settings?.duration_days) {
      return `${feature.settings.duration_days} ${i18n("yaks.admin.features.days")}`;
    }

    return i18n("yaks.admin.features.permanent");
  }

  <template>
    {{yield}}

    {{#if this.loading}}
      <div class="spinner"></div>
    {{else}}
      <div class="yaks-management-section">
        <div class="yaks-management-section__actions">
          <DButton
            @action={{this.adjustBalance}}
            @label="yaks.admin.adjustment.open"
            @icon="plus"
            class="btn-primary"
          />
        </div>

        <h2>{{i18n "yaks.admin.stats.title"}}</h2>
        <table class="yaks-stats-table">
          <tbody>
            <tr>
              <th>{{i18n "yaks.admin.stats.total_wallets"}}</th>
              <td>{{this.stats.total_wallets}}</td>
            </tr>
            <tr>
              <th>{{i18n "yaks.admin.stats.total_yaks"}}</th>
              <td>{{this.stats.total_yaks_in_circulation}}</td>
            </tr>
            <tr>
              <th>{{i18n "yaks.admin.stats.active_features"}}</th>
              <td>{{this.stats.active_features}}</td>
            </tr>
          </tbody>
        </table>

        <h2>{{i18n
            "yaks.admin.economy.title"
            days=this.economy.period_days
          }}</h2>
        <table class="yaks-stats-table">
          <tbody>
            <tr>
              <th>{{i18n "yaks.admin.economy.issued"}}</th>
              <td>{{this.economy.period.issued}}</td>
            </tr>
            <tr>
              <th>{{i18n "yaks.admin.economy.removed"}}</th>
              <td>{{this.economy.period.removed}}</td>
            </tr>
            <tr>
              <th>{{i18n "yaks.admin.economy.net"}}</th>
              <td>{{this.economy.period.net}}</td>
            </tr>
            <tr>
              <th>{{i18n "yaks.admin.economy.holders"}}</th>
              <td>{{this.economy.holder_count}}</td>
            </tr>
            <tr>
              <th>{{i18n "yaks.admin.economy.supply_difference"}}</th>
              <td>{{this.economy.supply_difference}}</td>
            </tr>
          </tbody>
        </table>

        <div class="yaks-economy-breakdowns">
          <div>
            <h3>{{i18n "yaks.admin.economy.sources"}}</h3>
            <table class="yaks-stats-table">
              <thead>
                <tr>
                  <th>{{i18n "yaks.admin.economy.source"}}</th>
                  <th>{{i18n "yaks.admin.economy.amount"}}</th>
                  <th>{{i18n "yaks.admin.economy.events"}}</th>
                </tr>
              </thead>
              <tbody>
                {{#each this.economy.sources as |source|}}
                  <tr>
                    <td>{{source.source}}</td>
                    <td>{{source.amount}}</td>
                    <td>{{source.count}}</td>
                  </tr>
                {{else}}
                  <tr><td colspan="3">{{i18n
                        "yaks.admin.economy.none"
                      }}</td></tr>
                {{/each}}
              </tbody>
            </table>
          </div>

          <div>
            <h3>{{i18n "yaks.admin.economy.sinks"}}</h3>
            <table class="yaks-stats-table">
              <thead>
                <tr>
                  <th>{{i18n "yaks.admin.economy.source"}}</th>
                  <th>{{i18n "yaks.admin.economy.amount"}}</th>
                  <th>{{i18n "yaks.admin.economy.events"}}</th>
                </tr>
              </thead>
              <tbody>
                {{#each this.economy.sinks as |sink|}}
                  <tr>
                    <td>{{sink.source}}</td>
                    <td>{{sink.amount}}</td>
                    <td>{{sink.count}}</td>
                  </tr>
                {{else}}
                  <tr><td colspan="3">{{i18n
                        "yaks.admin.economy.none"
                      }}</td></tr>
                {{/each}}
              </tbody>
            </table>
          </div>
        </div>

        <h2>{{i18n "yaks.admin.features.title"}}</h2>
        <table class="yaks-features-table">
          <thead>
            <tr>
              <th>{{i18n "yaks.admin.features.feature"}}</th>
              <th>{{i18n "yaks.admin.features.cost"}}</th>
              <th>{{i18n "yaks.admin.features.duration"}}</th>
              <th>{{i18n "yaks.admin.features.category"}}</th>
              <th>{{i18n "yaks.admin.features.enabled"}}</th>
              <th>{{i18n "yaks.admin.features.actions"}}</th>
            </tr>
          </thead>
          <tbody>
            {{#each this.features as |feature|}}
              <tr>
                <td>
                  <strong>{{feature.feature_name}}</strong>
                  <br />
                  <small>{{feature.description}}</small>
                </td>
                <td>{{feature.cost}} {{i18n "yaks.admin.features.yaks"}}</td>
                <td>{{this.featureDuration feature}}</td>
                <td>{{feature.category}}</td>
                <td>{{if
                    feature.enabled
                    (i18n "yaks.admin.yes")
                    (i18n "yaks.admin.no")
                  }}</td>
                <td>
                  <DButton
                    @action={{fn this.editFeature feature}}
                    @translatedLabel={{i18n "yaks.admin.edit"}}
                    @icon="pencil"
                    class="btn-small"
                  />
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>
    {{/if}}

    {{#if this.earningRules}}
      <div class="admin-yaks-earning-rules">
        <h3>{{i18n "yaks.admin.earning_rules.title"}}</h3>
        <table class="yak-earning-rules-table">
          <thead>
            <tr>
              <th>{{i18n "yaks.admin.earning_rules.action"}}</th>
              <th>{{i18n "yaks.admin.earning_rules.description"}}</th>
              <th>{{i18n "yaks.admin.earning_rules.amount"}}</th>
              <th>{{i18n "yaks.admin.earning_rules.daily_cap"}}</th>
              <th>{{i18n "yaks.admin.earning_rules.min_trust_level"}}</th>
              <th>{{i18n "yaks.admin.earning_rules.enabled"}}</th>
              <th>{{i18n "yaks.admin.actions"}}</th>
            </tr>
          </thead>
          <tbody>
            {{#each this.earningRules as |rule|}}
              <tr>
                <td>{{rule.action_name}}</td>
                <td>{{rule.description}}</td>
                <td>{{rule.amount}} {{i18n "yaks.currency"}}</td>
                <td>{{if
                    rule.daily_cap
                    rule.daily_cap
                    (i18n "yaks.admin.earning_rules.no_cap")
                  }}</td>
                <td>TL{{rule.min_trust_level}}</td>
                <td>{{if
                    rule.enabled
                    (i18n "yaks.admin.yes")
                    (i18n "yaks.admin.no")
                  }}</td>
                <td>
                  <DButton
                    @action={{fn this.editEarningRule rule}}
                    @translatedLabel={{i18n "yaks.admin.edit"}}
                    @icon="pencil"
                    class="btn-small"
                  />
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>
    {{/if}}
  </template>
}
