import DiscourseRoute from "discourse/routes/discourse";
import { service } from "@ember/service";

export default class YaksRoute extends DiscourseRoute {
  @service router;
  @service currentUser;

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

  async model() {
    try {
      const response = await fetch("/yaks.json");
      if (!response.ok) {
        throw new Error("Failed to fetch wallet data");
      }
      return await response.json();
    } catch (error) {
      console.error("Error loading yaks wallet:", error);
      return {
        balance: 0,
        lifetime_earned: 0,
        lifetime_spent: 0,
        transactions: [],
        features: [],
      };
    }
  }
}
