import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsDiscourseYaksIndexRoute extends DiscourseRoute {
  async model() {
    return await ajax("/admin/plugins/yaks/stats.json");
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set("model", model);
  }
}
