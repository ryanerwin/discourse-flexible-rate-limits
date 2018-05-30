export default Ember.Component.extend({
  
  @on("didReceiveAttrs")
  _setup() {
    this.set("categoryGroupName", this.get("categoryGroup.name"));
  },

  actions: {
    save() {
      if (this.get("disabled")) return;

      const categoryGroupName = this.get("categoryGroupName")
      if (!this.get("categoryGroupNames").includes(categoryGroupName)) {
        this.set("category_group.name", categoryGroupName);
      }
    }
  },

  @computed("categoryGroupName")
  disabled(categoryGroupName) {
    return Ember.isBlank(categoryGroupName) || Ember.isEmpty(categoryGroupName);
  }
});