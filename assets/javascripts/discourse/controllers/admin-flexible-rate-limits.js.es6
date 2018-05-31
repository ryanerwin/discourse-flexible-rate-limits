import computed from "ember-addons/ember-computed-decorators";
import showModal from "discourse/lib/show-modal";
import { ajax } from "discourse/lib/ajax";

export default Ember.Controller.extend({

  actions: {
    addCategoryGroup() {
      this.set("model.category_group", null);
      showModal("edit-category-group", { model: this.get("model") });
    },

    editCategoryGroup(categoryGroup) {
      this.set("model.category_group", categoryGroup);
      showModal("edit-category-group", { model: this.get("model") });
    },

    deleteCategoryGroup(categoryGroup) {
      this.get("model.category_groups").removeObject(categoryGroup);
    },

    saveCategoryGroups() {
      if (!this.get("model.category_groups")) return;
      this.save();
    }

  },

  save() {
    const categoryGroups = JSON.stringify({ category_groups: this.get("model.category_groups") });
    const args = { type: "POST", dataType: "json", contentType: "application/json", data: categoryGroups }

    ajax("/admin/flexible-rate-limits/save.json", args).then(data => this.set("model", data));
  }

});