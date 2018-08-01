import { default as computed, observes } from "ember-addons/ember-computed-decorators";

export default Ember.Component.extend({

  classNames: ["frl-clock"],

  hours: 0,
  minutes: 0,
  seconds: 0,

  didReceiveAttrs() {
    this._updateTimer();
  },

  _updateTimer() {
    const duration  = moment.duration(this.get("wait") * 1000);

    this.setProperties({
      hours: parseInt(duration.asHours()),
      minutes: duration.minutes(),
      seconds: duration.seconds()
    });
  },

  @computed("hours", "minutes", "seconds")
  formatedTime(hours, minutes, seconds) {
    return [hours, minutes, seconds].map( x => this._addZero(x) ).join(":");
  },

  _addZero(num) {
    return num > 9 ? num : "0" + num;
  }

});
