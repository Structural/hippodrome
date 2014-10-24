bindToContextIfFunction = (context) ->
  (objValue, srcValue) ->
    if srcValue instanceof Function
      srcValue.bind(context)
    else
      srcValue

Store = (options) ->
  @storeImpl = {}
  @storeImpl.dispatcherIdsByAction = {}
  @storeImpl.callbacks = []
  _.assign(@storeImpl, _.omit(options, 'initialize', 'dispatches', 'public'), bindToContextIfFunction(@storeImpl))

  if options.public
    _.assign(this, options.public, bindToContextIfFunction(@storeImpl))

  if options.initialize
    options.initialize.call(@storeImpl)

  if options.dispatches
    _.forEach options.dispatches, (dispatch) =>
      {action, after, callback} = dispatch

      assert(not @storeImpl.dispatcherIdsByAction[action.id],
             'Each store can only register one callback for each action.')

      if typeof callback == 'string'
        callback = @storeImpl[callback]
      callback = callback.bind(@storeImpl)

      id = Hippodrome.Dispatcher.register(this, action.id, after, callback)
      @storeImpl.dispatcherIdsByAction[action.id] = id

  this

Store.prototype.register = (callback) ->
  @storeImpl.callbacks.push(callback)

Store.prototype.unregister = (callback) ->
  @storeImpl.callbacks = _.reject(@storeImpl.callbacks, (cb) -> cb == callback)

# register/unregister are completely general, this is tailored for React mixins.
Store.prototype.listen = (callbackName) ->
  store = this
  return {
    componentDidMount: ->
      store.register(this[callbackName])
    componentWillUnmount: ->
      store.unregister(this[callbackName])
  }

Store.prototype.trigger = ->
  _.forEach(@storeImpl.callbacks, (callback) -> callback())

Hippodrome.Store = Store
