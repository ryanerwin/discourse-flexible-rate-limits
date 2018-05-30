import { default as computed, on } from "ember-addons/ember-computed-decorators";

export default Ember.Component.extend({
  classNames: ["frl-category-group"],

  selectedGroupId: null,

  actions: {
    edit() {
      this.sendAction("editCategoryGroup", this.get("categoryGroup"));
    },

    addGroup() {
      if (this.get("addGroupDisabled")) return;

      const group = Ember.Object.create({ id: this.get("selectedGroupId") });

      this.get("categoryGroup.groups").addObject(group);
      this.set("selectedGroupId", null);
    },

    removeGroup(group) {
      this.get("categoryGroup.groups").removeObject(group);
    }
  },

  @computed("groups", "categoryGroup.groups")
  availableGroups(groups, currentGroups) {
    const groupIds = (currentGroups || []).map(group => group.get("id"));

    return groups.filter((group) => {
      return !groupIds.includes(group.get("id"));
    });
  },

  @computed("selectedGroupId")
  addGroupDisabled(selectedGroupId) {
    return Ember.isBlank(selectedGroupId) || Ember.isEmpty(selectedGroupId);
  }
});