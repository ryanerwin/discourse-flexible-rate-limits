import Composer from "discourse/models/composer";
import { default as computed, on, observes } from "ember-addons/ember-computed-decorators";
import { ajax } from "discourse/lib/ajax";
import showModal from "discourse/lib/show-modal";

export default Ember.Component.extend({
  classNames: ["frl-composer-info"],

  rawData: null,

  didInsertElement() {
    this.setupFetcher();
  },

  @computed("rawData", "limitType")
  data(rawData, limitType) {
    if (!rawData || !limitType) return;

    return rawData[limitType];
  },

  @computed("siteSettings.flexible_rate_limits_debug")
  debugEnabled(enabled) {
    return enabled;
  },

  @computed("model.action")
  limitType(action) {
    return (action === Composer.CREATE_TOPIC) ? "topic" : (action === Composer.REPLY) ? "post" : null;
  },

  @observes("model.categoryId", "model.action", "model.privateMessage")
  _setupFetcher() {
    if (this.get("model.privateMessage")) return;
    this.set("rawData", null);
    this.setupFetcher();
  },

  @observes("rawData")
  _addClass() {
    if (this.get("rawData")) {
      $(".wmd-controls").addClass("with-frl-composer-info");
    } else {
      $(".wmd-controls").removeClass("with-frl-composer-info");
    }
  },

  setupFetcher() {
    this.cancelRunner();
    const fetcher = Ember.run.scheduleOnce("afterRender", () => {
      this.fetchData();
    });
    this.set("fetcher", fetcher);
  },

  fetchData() {
    const categoryId  = this.get("model.categoryId") || this.site.get("uncategorized_category_id");
    const limitType   = this.get("limitType");

    if (limitType) {
      ajax(`/flexible_rate_limits/${categoryId}/${limitType}.json`, { type: "POST" })
        .then( result => this.set("rawData", result) )
        .catch((e) => {
          console.error(e);
          this.set("rawData", null);
        }).finally( () => this.countDown() );
    }
  },

  countDown() {
    if (!this.get("showCounter")) return;

    const path = `rawData.${this.get("limitType")}.wait`;

    const counter = Ember.run.later(this, () => {
      this.set(path, this.get(path) - 1);
      this.updateModalClock();
      this.countDown();
    }, 1000);

    this.set("counter", counter);
  },

  updateModalClock() {
    const modal = this.get("modal");
    if (modal) {
      modal.set("model.data.wait", this.get("data.wait"));
      modal.set("model.showCounter", this.get("showCounter"));
    }
  },

  @computed("data.wait", "showCounter")
  formatedCounter(wait, showCounter) {
    if (wait >= 3600) return `${parseInt(wait / 3600)}h`;

    if (wait >= 60) return `${parseInt(wait / 60)}m`;

    return wait + "s";
  },

  @computed("data.remaining", "data.wait")
  showCounter(remaining, wait) {
    return ((typeof remaining == "number") && remaining < 1 && wait > 0);
  },

  willDestroyElement() {
    $(".wmd-controls").removeClass("with-frl-composer-info");
    this.cancelRunner();
  },

  cancelRunner() {
    ["fetcher", "counter"].forEach((i) => {
      if (this.get(i)) Ember.run.cancel(this.get(i));
    });
  },

  actions: {
    showDebugModal() {
      if (!this.siteSettings.flexible_rate_limits_debug) return;

      const model = {
        limitType: this.get("limitType"),
        data: this.get("data"),
        newUser: this.get("rawData.new_user"),
        showCounter: this.get("showCounter")
      }

      this.set("modal", showModal("frl-debug-modal", { model }));
    }
  }
});
