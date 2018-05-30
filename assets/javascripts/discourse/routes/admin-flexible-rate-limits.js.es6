export default Discourse.Route.extend({

  titleToken() {
    return I18n.t("flexible_rate_limits.admin.title");
  },

  model() {
    return ajax("/admin/flexible-rate-limits.json");
  },

  setupController(controller, model) {
    controller.set("model", model);
  }

});