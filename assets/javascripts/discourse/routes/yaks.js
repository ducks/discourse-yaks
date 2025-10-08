import DiscourseRoute from "discourse/routes/discourse";
import { service } from "@ember/service";

export default class YaksRoute extends DiscourseRoute {
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
}
