import DiscourseRoute from "discourse/routes/discourse";
import { service } from "@ember/service";

export default class YaksPurchaseRoute extends DiscourseRoute {
  @service router;
  @service currentUser;
  @service siteSettings;

  beforeModel() {
    if (!this.siteSettings.yaks_enabled) {
      this.router.transitionTo("discovery.latest");
      return;
    }

    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
  }

  model() {
    // Build packages array from site settings
    const packages = [];

    for (let i = 1; i <= 4; i++) {
      const amount = this.siteSettings[`yaks_package_${i}_amount`];
      const yaks = this.siteSettings[`yaks_package_${i}_yaks`];
      const bonus = this.siteSettings[`yaks_package_${i}_bonus`];

      if (amount && yaks) {
        packages.push({
          amount,
          yaks,
          bonus,
          total: yaks + bonus,
        });
      }
    }

    return { packages };
  }
}
