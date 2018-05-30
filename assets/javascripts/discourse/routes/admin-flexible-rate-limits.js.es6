import { ajax } from "discourse/lib/ajax";

export default Discourse.Route.extend({

  titleToken() {
    return I18n.t("flexible_rate_limits.admin.title");
  },

  model() {
    return ajax("/admin/flexible-rate-limits.json").then((data) => {
      return data;
    });
  },

  setupController(controller, model) {
    controller.set("model", model);
  }

});