bindToContextIfFunction = (context) ->
  (objValue, srcValue) ->
    if srcValue instanceof Function
      srcValue.bind(context)
    else
      srcValue

makeToFn = (context, action, prerequisites=[]) ->
  (callback) ->
    if typeof callback == 'string'
      callback = context[callback]
    callback = callback.bind(context)

    id = Hippodrome.Dispatcher.register(action.id, callback, prerequisites)
    context.dispatcherIdsByAction[action] = id

createStore = (options) ->
  storeImpl = {
    dispatcherIdsByAction: {}
    callbacks: []
    trigger: -> _.each @callbacks, (spec) ->
      {callback, context} = spec
      if context
        callback.call(context)
      else
        callback()
    dispatch: (action) ->
      assert(@dispatcherIdsByAction[action] == undefined,
             "Store #{@displayName} attempted to register twice for action
              #{action.displayName}.")

      context = this
      after = () ->
        prerequisites = arguments
        return {to: makeToFn(context, action, prerequisites)}

      return {after: after, to: makeToFn(context, action)}
  }
  store = {
    _storeImpl: storeImpl
    displayName: options.displayName

    register: (callback, context=null) ->
      @_storeImpl.callbacks.push({
        callback: callback
        context: context
      })
    unregister: (callback) ->
      _.remove @_storeImpl.callbacks, (spec) ->
        cb = spec.callback
        return cb == callback

    listen: (property, fn) ->
      store = this
      getState = () ->
        state = {}
        state[property] = fn()
        return state
      callback = () ->
        @setState(getState())
      return {
        componentWillMount: ->
          callback.call(this)
        componentDidMount: ->
          store.register(callback, this)
        componentWillUnmount: ->
          store.unregister(callback, this)
      }
    listenWith: (stateFnName) ->
      store = this
      callback = () ->
        @setState(this[stateFnName]())
      return {
        componentWillMount: ->
          callback.call(this)
        componentDidMount: ->
          store.register(callback, this)
        componentWillUnmount: ->
          store.unregister(callback, this)
      }
  }

  _.assign(storeImpl,
           _.omit(options, 'initialize', 'public'),
           bindToContextIfFunction(storeImpl))

  if options.public
    _.assign(store, options.public, bindToContextIfFunction(storeImpl))
    _.assign(storeImpl, options.public, bindToContextIfFunction(storeImpl))

  if options.initialize
    storeImpl.dispatch(Hippodrome.start).to(options.initialize)

  return store

Hippodrome.createStore = createStore
