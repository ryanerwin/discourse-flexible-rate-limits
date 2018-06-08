import computed from "ember-addons/ember-computed-decorators";
import showModal from "discourse/lib/show-modal";

export default Ember.Component.extend({
  classNames: ["frl-category-group"],

  actions: {
    edit() {
      this.sendAction("editCategoryGroup", this.get("categoryGroup"));
    },

    delete() {
      this.sendAction("deleteCategoryGroup", this.get("categoryGroup"));
    },

    addGroup() {
      if (!this.get("categoryGroup.groups")) {
        this.set("categoryGroup.groups", []);
      }
      showModal("frl-edit-group", { model: { groups: this.get("groups"), currentGroups: this.get("categoryGroup.groups") } });
    },

    editGroup(group) {
      showModal("frl-edit-group", { model: { groups: this.get("groups"), currentGroups: this.get("categoryGroup.groups"), group: group } });
    },

    removeGroup(group) {
      this.get("categoryGroup.groups").removeObject(group);
    },

    addCategory() {
      const categoryId = this.get("formatedCategoryId");

      if (isNaN(categoryId)) return;
      if (!this.get("categoryGroup.categories")) this.set("categoryGroup.categories", []);

      this.get("categoryGroup.categories").addObject(categoryId);
      this.get("availableCategoryIds").removeObject(categoryId);
      this.set("selectedCategoryId", null);
    },

    deleteCategory(categoryId) {
      this.get("categoryGroup.categories").removeObject(categoryId);
      this.get("availableCategoryIds").addObject(categoryId);
    }
  },

  @computed("selectedCategoryId")
  formatedCategoryId(categoryId) {
    return parseInt(categoryId);
  }

});