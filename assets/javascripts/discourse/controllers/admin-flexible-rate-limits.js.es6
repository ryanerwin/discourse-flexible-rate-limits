import computed from "ember-addons/ember-computed-decorators";
import showModal from "discourse/lib/show-modal";

export default Ember.Controller.extend({

  actions: {
    addCategoryGroup() {
      this.set("model.category_group", null);
      showModal("edit-category-group", { model: this.get("model") });
    },

    editCategoryGroup(categoryGroup) {
      this.set("model.category_group", categoryGroup);
      showModal("edit-category-group", { model: this.get("model") });
    }

  }

});