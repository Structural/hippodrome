(function() {
  var Hippodrome, IdFactory, actionIds, assert, bindToContextIfFunction, createAction, createDeferredTask, createDispatcher, createStore, dispatcherIds, isNode, makeDeferredFunction, makeToFn, _,
    __slice = [].slice;

  isNode = typeof window === 'undefined';

  if (isNode) {
    _ = require('lodash');
  } else {
    _ = this._;
  }

  Hippodrome = {};

  assert = function() {
    var argIndex, args, condition, error, message;
    condition = arguments[0], message = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    if (!condition) {
      argIndex = 0;
      error = new Error('Assertion Failed: ' + message.replace(/%s/g, function() {
        return args[argIndex++];
      }));
      error.framesToPop = 1;
      throw error;
    }
    return condition;
  };

  IdFactory = function(prefix) {
    this._lastId = 1;
    return this._prefix = prefix;
  };

  IdFactory.prototype.next = function() {
    return "" + this._prefix + "_" + (this._lastId++);
  };

  actionIds = new IdFactory('Action_ID');

  createAction = function(options) {
    var action, buildPayload, id;
    assert(options.build instanceof Function, "Action " + options.displayName + " did not define a build function.");
    id = "" + (actionIds.next()) + "_" + options.displayName;
    buildPayload = function() {
      var payload;
      payload = options.build.apply(null, arguments);
      payload._action = id;
      return payload;
    };
    action = function() {
      var payload;
      payload = buildPayload.apply(null, arguments);
      return Hippodrome.Dispatcher.dispatch(payload);
    };
    action.buildPayload = buildPayload;
    action.displayName = options.displayName;
    action.id = id;
    action.toString = function() {
      return id;
    };
    return action;
  };

  Hippodrome.createAction = createAction;

  dispatcherIds = new IdFactory('Dispatcher_ID');

  createDispatcher = function() {
    var dispatcher;
    dispatcher = {
      _callbacksByAction: {},
      _isStarted: {},
      _isFinished: {},
      _isDispatching: false,
      _payload: null
    };
    dispatcher.register = function(action, callback, prerequisites) {
      var id, _base;
      if (prerequisites == null) {
        prerequisites = [];
      }
      if ((_base = this._callbacksByAction)[action] == null) {
        _base[action] = {};
      }
      id = dispatcherIds.next();
      this._callbacksByAction[action][id] = {
        callback: callback,
        prerequisites: prerequisites
      };
      return id;
    };
    dispatcher.unregister = function(action, id) {
      assert(this._callbacksByAction && this._callbacksByAction[action][id], "Dispatcher.unregister(" + action.displayName + ", " + id + ") does not map to a registered callback.");
      return delete this._callbacksByAction[action][id];
    };
    dispatcher.waitFor = function(action, stores) {
      assert(this._isDispatching, "Dispatcher.waitFor must be called while dispatching.");
      return _.forEach(stores, (function(_this) {
        return function(store) {
          var id;
          id = store._storeImpl.dispatcherIdsByAction[action];
          if (_this._isStarted[id]) {
            assert(_this._isFinished[id], "Dispatcher.waitFor encountered circular dependency trying to wait for " + id + " during action " + action.displayName + ".");
            return;
          }
          assert(_this._callbacksByAction[action][id], "Dispatcher.waitFor " + id + " is not a registered callback for " + action.displayName + ".");
          return _this.invokeCallback(action, id);
        };
      })(this));
    };
    dispatcher.dispatch = function(payload) {
      var action;
      assert(!this._isDispatching, "Dispatcher.dispatch cannot be called during dispatch.");
      this.startDispatching(payload);
      try {
        action = payload._action;
        return _.forEach(this._callbacksByAction[action], (function(_this) {
          return function(callback, id) {
            if (_this._isStarted[id]) {
              return;
            }
            return _this.invokeCallback(action, id);
          };
        })(this));
      } finally {
        this.stopDispatching();
      }
    };
    dispatcher.invokeCallback = function(action, id) {
      var callback, prerequisites, _ref;
      this._isStarted[id] = true;
      _ref = this._callbacksByAction[action][id], callback = _ref.callback, prerequisites = _ref.prerequisites;
      this.waitFor(action, prerequisites);
      callback(this._payload);
      return this._isFinished[id] = true;
    };
    dispatcher.startDispatching = function(payload) {
      this._isStarted = {};
      this._isFinished = {};
      this._payload = payload;
      return this._isDispatching = true;
    };
    dispatcher.stopDispatching = function() {
      this._payload = null;
      return this._isDispatching = false;
    };
    return dispatcher;
  };

  Hippodrome.Dispatcher = createDispatcher();

  makeDeferredFunction = function(context, fn) {
    if (typeof fn === 'string') {
      fn = context[fn];
    }
    return function() {
      var args;
      args = arguments;
      return setTimeout((function() {
        return fn.apply(context, args);
      }), 1);
    };
  };

  createDeferredTask = function(options) {
    var task;
    assert(!options.action || options.task, "Deferred Task " + options.displayName + " declared an action, it must declare a task.");
    assert(!options.task || options.action, "Deferred Task " + options.displayName + " declared a task, it must declare an action.");
    task = {};
    _.assign(task, _.omit(options, 'initialize', 'action', 'task'), bindToContextIfFunction(task));
    task.dispatch = function(action) {
      var to;
      assert(task._dispatcherIdsByAction[action.id] === void 0, "Deferred Task " + task.displayName + " attempted to register twice for action " + action.displayName + ".");
      to = function(callback) {
        var id;
        callback = makeDeferredFunction(task, callback);
        id = Hippodrome.Dispatcher.register(action.id, callback);
        task._dispatcherIdsByAction[action.id] = id;
        return id;
      };
      return {
        to: to
      };
    };
    task._dispatcherIdsByAction = {};
    if (options.initialize) {
      task.dispatch(Hippodrome.start).to(options.initialize);
    }
    if (options.action && options.task) {
      task.dispatch(options.action).to(options.task);
    }
    return task;
  };

  Hippodrome.createDeferredTask = createDeferredTask;

  bindToContextIfFunction = function(context) {
    return function(objValue, srcValue) {
      if (srcValue instanceof Function) {
        return srcValue.bind(context);
      } else {
        return srcValue;
      }
    };
  };

  makeToFn = function(context, action, prerequisites) {
    if (prerequisites == null) {
      prerequisites = [];
    }
    return function(callback) {
      var id;
      if (typeof callback === 'string') {
        callback = context[callback];
      }
      callback = callback.bind(context);
      id = Hippodrome.Dispatcher.register(action.id, callback, prerequisites);
      return context.dispatcherIdsByAction[action] = id;
    };
  };

  createStore = function(options) {
    var store, storeImpl;
    storeImpl = {
      dispatcherIdsByAction: {},
      callbacks: [],
      trigger: function() {
        return _.each(this.callbacks, function(callback) {
          return callback();
        });
      },
      dispatch: function(action) {
        var after, context;
        assert(this.dispatcherIdsByAction[action] === void 0, "Store " + this.displayName + " attempted to register twice for action " + action.displayName + ".");
        context = this;
        after = function() {
          var prerequisites;
          prerequisites = arguments;
          return {
            to: makeToFn(context, action, prerequisites)
          };
        };
        return {
          after: after,
          to: makeToFn(context, action)
        };
      }
    };
    store = {
      _storeImpl: storeImpl,
      displayName: options.displayName,
      register: function(callback) {
        return this._storeImpl.callbacks.push(callback);
      },
      unregister: function(callback) {
        return _.remove(this._storeImpl.callbacks, function(cb) {
          return cb === callback;
        });
      },
      listen: function(property, fn) {
        var callback, getState;
        store = this;
        getState = function() {
          var state;
          state = {};
          state[property] = fn();
          return state;
        };
        callback = function() {
          return this.setState(getState());
        };
        return {
          componentWillMount: function() {
            callback = callback.bind(this);
            return callback();
          },
          componentDidMount: function() {
            return store.register(callback);
          },
          componentWillUnmount: function() {
            return store.unregister(callback);
          }
        };
      },
      listenWith: function(stateFnName) {
        var callback;
        store = this;
        callback = function() {
          return this.setState(this[stateFnName]());
        };
        return {
          componentWillMount: function() {
            callback = callback.bind(this);
            return callback();
          },
          componentDidMount: function() {
            return store.register(callback);
          },
          componentWillUnmount: function() {
            return store.unregister(callback);
          }
        };
      }
    };
    _.assign(storeImpl, _.omit(options, 'initialize', 'public'), bindToContextIfFunction(storeImpl));
    if (options["public"]) {
      _.assign(store, options["public"], bindToContextIfFunction(storeImpl));
      _.assign(storeImpl, options["public"], bindToContextIfFunction(storeImpl));
    }
    if (options.initialize) {
      storeImpl.dispatch(Hippodrome.start).to(options.initialize);
    }
    return store;
  };

  Hippodrome.createStore = createStore;

  Hippodrome.start = new Hippodrome.createAction({
    displayName: 'start Hippodrome',
    build: function(options) {
      return options || {};
    }
  });

  if (isNode) {
    module.exports = Hippodrome;
  } else {
    this.Hippodrome = Hippodrome;
  }

}).call(this);
