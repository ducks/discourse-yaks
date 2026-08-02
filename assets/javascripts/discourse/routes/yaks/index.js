import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

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

  model() {
    return ajax("/yaks.json");
  }
}
