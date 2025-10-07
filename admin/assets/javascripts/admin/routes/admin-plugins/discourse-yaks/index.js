import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsDiscourseYaksIndexRoute extends DiscourseRoute {
  model() {
    return ajax("/admin/plugins/discourse-yaks.json");
  }
}
