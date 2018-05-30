import { default as computed, on } from "ember-addons/ember-computed-decorators";

export default Ember.Component.extend({
  
  @on("didReceiveAttrs")
  _setup() {
    this.set("categoryGroupName", this.get("model.category_group.name"));
  },

  actions: {
    save() {
      this.set("errorMsg", null);

      if (this.get("disabled")) return;

      const categoryGroupName = this.get("formatedCategoryGroupName");

      if (categoryGroupName == this.get("model.category_group.name")) {
        this._closeModal();
        return;
      }

      if (this.get("categoryGroupNames").includes(categoryGroupName)) {
        this.set("errorMsg", I18n.t("flexible_rate_limits.admin.error.duplicate_category_group_name"));
        return;
      }

      if (this.get("model.category_group")) {
        this.set("model.category_group.name", categoryGroupName);
      } else {
        this.get("model.category_groups").addObject(Ember.Object.create({ name: categoryGroupName }));
      }

      this._closeModal();
    }
  },

  @computed("formatedCategoryGroupName")
  disabled(categoryGroupName) {
    return Ember.isEmpty(categoryGroupName);
  },

  @computed("categoryGroupName")
  formatedCategoryGroupName(categoryGroupName) {
    return (categoryGroupName || "").toLowerCase().trim();
  },

  @computed("model.category_groups")
  categoryGroupNames(categoryGroups) {
    if (!categoryGroups) return [];

    return categoryGroups.map((cg) => {
      return cg.get("name");
    });
  },

  _closeModal() {
    this.sendAction("closeModal");
  }
});