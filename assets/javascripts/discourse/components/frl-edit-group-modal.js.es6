import { default as computed, on } from "ember-addons/ember-computed-decorators";

export default Ember.Component.extend({

  @on("didReceiveAttrs")
  _setup() {
    this.set("selectedGroupId", this.get("group.id"));
    this.set("topicLimit", this.get("group.topic_limit"));
    this.set("postLimit", this.get("group.post_limit"));
  },

  actions: {
    save() {
      if (this.get("disabled")) return;

      const group = this.get("_group");

      if (this.get("group")) {
        this.get("group").setProperties(group);
      } else {
        this.get("currentGroups").addObject(Ember.Object.create(group));
      }

      this.sendAction("closeModal");
    }
  },

  @computed("selectedGroupId")
  formatedGroupId(selectedGroupId) {
    return parseInt(selectedGroupId);
  },

  @computed("topicLimit")
  formatedTopicLimit(topicLimit) {
    return parseInt(topicLimit);
  },

  @computed("postLimit")
  formatedPostLimit(postLimit) {
    return parseInt(postLimit);
  },

  @computed("formatedGroupId", "formatedTopicLimit", "formatedPostLimit")
  disabled(groupId, topicLimit, postLimit) {
    return isNaN(groupId) || (groupId < 1) || isNaN(topicLimit) || (topicLimit < 1) || isNaN(postLimit) || (postLimit < 1);
  },

  @computed("formatedGroupId", "formatedTopicLimit", "formatedPostLimit")
  _group(groupId, topicLimit, postLimit) {
    return {
      id: groupId,
      topic_limit: topicLimit,
      post_limit: postLimit
    };
  },

  @computed("groups", "currentGroups")
  availableGroups(groups, currentGroups) {
    const groupIds = (currentGroups || []).map(group => group.id);

    return groups.filter((group) => {
      return !groupIds.includes(group.id);
    });
  },

});