(function() {
  var Action, DeferredTask, Dispatcher, Hippodrome, IdFactory, Store, actionIds, assert, bindToContextIfFunction, dispatcherIds, isNode, makeDeferredFunction, _,
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

  Action = function(name, ctor) {
    var actionFn, buildPayload, id, send;
    id = "" + (actionIds.next()) + "_" + name;
    buildPayload = function() {
      var payload;
      payload = ctor.apply(null, arguments);
      payload.action = id;
      return payload;
    };
    send = function(payload) {
      return Hippodrome.Dispatcher.dispatch(payload);
    };
    actionFn = function() {
      var payload;
      payload = buildPayload.apply(null, arguments);
      return send(payload);
    };
    actionFn.buildPayload = buildPayload;
    actionFn.send = send;
    actionFn.displayName = name;
    actionFn.id = id;
    actionFn.toString = function() {
      return id;
    };
    return actionFn;
  };

  Hippodrome.Action = Action;

  Dispatcher = function() {
    this._callbacksByAction = {};
    this._isStarted = {};
    this._isFinished = {};
    this._isDispatching = false;
    return this._payload = null;
  };

  dispatcherIds = new IdFactory('Dispatcher_ID');

  Dispatcher.prototype.register = function() {
    var action, args, callback, id, prereqStores, store, _base;
    args = _.compact(arguments);
    if (args.length === 3) {
      return this.register(args[0], args[1], [], args[2]);
    } else {
      store = args[0], action = args[1], prereqStores = args[2], callback = args[3];
      if ((_base = this._callbacksByAction)[action] == null) {
        _base[action] = {};
      }
      id = dispatcherIds.next();
      this._callbacksByAction[action][id] = {
        callback: callback,
        prerequisites: _.map(prereqStores, function(ps) {
          return ps._storeImpl.dispatcherIdsByAction[action];
        })
      };
      return id;
    }
  };

  Dispatcher.prototype.unregister = function(action, id) {
    assert(this._callbacksByAction[action][id], 'Dispatcher.unregister(%s, %s) does not map to a registered callback.', action.displayName, id);
    return this._callbacksByAction[action][id] = null;
  };

  Dispatcher.prototype.waitFor = function(action, ids) {
    assert(this._isDispatching, 'Dispatcher.waitFor must be invoked while dispatching.');
    return _.forEach(ids, (function(_this) {
      return function(id) {
        if (_this._isStarted[id]) {
          assert(_this._isFinished[id], 'Dispatcher.waitFor encountered circular dependency while ' + 'waiting for `%s` during %s.', id, action.displayName);
          return;
        }
        assert(_this._callbacksByAction[action][id], 'Dispatcher.waitFor `%s` is not a registered callback for %s.', id, action.displayName);
        return _this.invokeCallback(action, id);
      };
    })(this));
  };

  Dispatcher.prototype.dispatch = function(payload) {
    var action;
    assert(!this._isDispatching, 'Dispatch.dispatch cannot be called during dispatch.');
    this.startDispatching(payload);
    try {
      action = payload.action;
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

  Dispatcher.prototype.invokeCallback = function(action, id) {
    var callback, prerequisites, _ref;
    this._isStarted[id] = true;
    _ref = this._callbacksByAction[action][id], callback = _ref.callback, prerequisites = _ref.prerequisites;
    this.waitFor(action, prerequisites);
    callback(this._payload);
    return this._isFinished[id] = true;
  };

  Dispatcher.prototype.startDispatching = function(payload) {
    this._isStarted = {};
    this._isFinished = {};
    this._payload = payload;
    return this._isDispatching = true;
  };

  Dispatcher.prototype.stopDispatching = function() {
    this._payload = null;
    return this._isDispatching = false;
  };

  Hippodrome.Dispatcher = new Dispatcher();

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

  DeferredTask = function(options) {
    var action, id, task;
    this.displayName = options.displayName;
    assert(options.action || options.dispatches, "Deferred Task " + this.displayName + " must include either an action key or dispatches list.");
    assert(!options.action || options.task, "Deferred Task " + this.displayName + " declared an action, it must declare a task.");
    _.assign(this, _.omit(options, 'dispatches', 'action', 'task'), bindToContextIfFunction(this));
    this._dispatcherIdsByAction = {};
    if (options.initialize) {
      options.initialize.call(this);
    }
    if (options.action && options.task) {
      action = options.action, task = options.task;
      task = makeDeferredFunction(this, task);
      id = Hippodrome.Dispatcher.register(this, action.id, [], task);
      this._dispatcherIdsByAction[action.id] = id;
    }
    if (options.dispatches) {
      _.forEach(options.dispatches, (function(_this) {
        return function(dispatch) {
          var callback;
          action = dispatch.action, callback = dispatch.callback;
          assert(!_this._dispatcherIdsByAction[action.id], "Deferred Task " + _this.displayName + " registered two callbacks for the action " + action.displayName + ".");
          callback = makeDeferredFunction(_this, callback);
          id = Hippodrome.Dispatcher.register(_this, action.id, [], callback);
          return _this._dispatcherIdsByAction[action.id] = id;
        };
      })(this));
    }
    return this;
  };

  Hippodrome.DeferredTask = DeferredTask;

  bindToContextIfFunction = function(context) {
    return function(objValue, srcValue) {
      if (srcValue instanceof Function) {
        return srcValue.bind(context);
      } else {
        return srcValue;
      }
    };
  };

  Store = function(options) {
    this._storeImpl = {
      trigger: function() {
        return _.each(this.callbacks, function(callback) {
          return callback();
        });
      }
    };
    this._storeImpl.dispatcherIdsByAction = {};
    this._storeImpl.callbacks = [];
    _.assign(this._storeImpl, _.omit(options, 'initialize', 'dispatches', 'public'), bindToContextIfFunction(this._storeImpl));
    if (options["public"]) {
      _.assign(this, options["public"], bindToContextIfFunction(this._storeImpl));
      _.assign(this._storeImpl, options["public"], bindToContextIfFunction(this._storeImpl));
    }
    this.displayName = options.displayName;
    if (options.initialize) {
      options.initialize.call(this._storeImpl);
    }
    if (options.dispatches) {
      _.forEach(options.dispatches, (function(_this) {
        return function(dispatch) {
          var action, after, callback, id;
          action = dispatch.action, after = dispatch.after, callback = dispatch.callback;
          assert(!_this._storeImpl.dispatcherIdsByAction[action.id], "Store " + _this.displayName + " registered two callbacks for action " + action.displayName);
          if (typeof callback === 'string') {
            callback = _this._storeImpl[callback];
          }
          callback = callback.bind(_this._storeImpl);
          id = Hippodrome.Dispatcher.register(_this, action.id, after, callback);
          return _this._storeImpl.dispatcherIdsByAction[action.id] = id;
        };
      })(this));
    }
    return this;
  };

  Store.prototype.register = function(callback) {
    return this._storeImpl.callbacks.push(callback);
  };

  Store.prototype.unregister = function(callback) {
    return this._storeImpl.callbacks = _.reject(this._storeImpl.callbacks, function(cb) {
      return cb === callback;
    });
  };

  Store.prototype.listen = function(callbackName) {
    var store;
    store = this;
    return {
      componentDidMount: function() {
        return store.register(this[callbackName]);
      },
      componentWillUnmount: function() {
        return store.unregister(this[callbackName]);
      }
    };
  };

  Store.prototype.trigger = function() {
    return this._storeImpl.trigger();
  };

  Hippodrome.Store = Store;

  if (isNode) {
    module.exports = Hippodrome;
  } else {
    this.Hippodrome = Hippodrome;
  }

}).call(this);
