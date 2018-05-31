//import { default as computed, on } from "ember-addons/ember-computed-decorators";
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
    }
  }

});