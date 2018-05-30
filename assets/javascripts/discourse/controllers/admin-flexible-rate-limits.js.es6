import showModal from "discourse/lib/show-modal";

export default Ember.Controller.extend({

  actions: {

    addCategoryGroup() {
      showModal("edit-category-group", { categoryGroup: {}, categoryGroupNames: this.get("categoryGroupNames") });
    }

  },

  @computed("model.category_groups")
  categoryGroupNames(categoryGroups) {
    if (!categoryGroups) return [];

    return categoryGroups.map((cg) => {
      return cg.get("name");
    });
  }

});