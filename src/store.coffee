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
    trigger: -> _.each(@callbacks, (callback) -> callback())
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

    register: (callback) ->
      @_storeImpl.callbacks.push(callback)
    unregister: (callback) ->
      _.remove(@_storeImpl.callbacks, (cb) -> cb == callback)

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
          callback = callback.bind(this)
          callback()
        componentDidMount: ->
          store.register(callback)
        componentWillUnmount: ->
          store.unregister(callback)
      }
    listenWith: (stateFnName) ->
      store = this
      callback = () ->
        @setState(this[stateFnName]())
      return {
        componentWillMount: ->
          callback = callback.bind(this)
          callback()
        componentDidMount: ->
          store.register(callback)
        componentWillUnmount: ->
          store.unregister(callback)
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
