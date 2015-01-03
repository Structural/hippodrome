count = Hippodrome.createAction({
  displayName: 'count',
  build: function() {
    return {};
  }
});

counterStore = Hippodrome.createStore({
  displayName: 'counter store',
  initialize: function(options) {
    this.dispatch(count).to(this.increment);

    this._value = 0;
  },

  increment: function(payload) {
    this._value += 1;
    this.trigger();
  },

  public: {
    value: function() { return this._value; }
  }
});

div = React.DOM.div;

counterClass = React.createClass({
  displayName: 'counter',
  mixins: [
    counterStore.listen('count', counterStore.value)
  ],

  render: function() {
    return div({}, this.state.count);
  }
});
counter = React.createFactory(counterClass);

counterWithClass = React.createClass({
  displayName: 'counter With',
  mixins: [
    counterStore.listenWith('getCount')
  ],

  getCount: function() {
    return {
      count: counterStore.value()
    };
  },

  render: function() {
    return div({}, this.state.count);
  }
});
counterWith = React.createFactory(counterWithClass);

bothCountersClass = React.createClass({
  render: function() {
    return div({}, counter(), counterWith());
  }
});
bothCounters = React.createFactory(bothCountersClass);

document.addEventListener('DOMContentLoaded', function() {
  Hippodrome.start();
  React.render(bothCounters(), document.getElementById('root'));
});
