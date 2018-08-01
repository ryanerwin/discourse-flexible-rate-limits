import ModalFunctionality from "discourse/mixins/modal-functionality";
import computed from "ember-addons/ember-computed-decorators";

export default Ember.Controller.extend(ModalFunctionality, {

  @computed("model.limitType")
  title(limitType) {
    return `flexible_rate_limits.debug_modal.title.${limitType}`;
  }

});
