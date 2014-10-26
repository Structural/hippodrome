bindToContextIfFunction = (context) ->
  (objValue, srcValue) ->
    if srcValue instanceof Function
      srcValue.bind(context)
    else
      srcValue

Store = (options) ->
  @_storeImpl = {
    trigger: -> _.each(@callbacks, (callback) -> callback())
  }
  @_storeImpl.dispatcherIdsByAction = {}
  @_storeImpl.callbacks = []
  _.assign(@_storeImpl, _.omit(options, 'initialize', 'dispatches', 'public'), bindToContextIfFunction(@_storeImpl))

  if options.public
    _.assign(this, options.public, bindToContextIfFunction(@_storeImpl))
    _.assign(@_storeImpl, options.public, bindToContextIfFunction(@_storeImpl))
  @displayName = options.displayName

  if options.initialize
    options.initialize.call(@_storeImpl)

  if options.dispatches
    _.forEach options.dispatches, (dispatch) =>
      {action, after, callback} = dispatch

      assert(not @_storeImpl.dispatcherIdsByAction[action.id],
             "Store #{@displayName} registered two callbacks for action #{action.displayName}")

      if typeof callback == 'string'
        callback = @_storeImpl[callback]
      callback = callback.bind(@_storeImpl)

      id = Hippodrome.Dispatcher.register(this, action.id, after, callback)
      @_storeImpl.dispatcherIdsByAction[action.id] = id

  this

Store::register = (callback) ->
  @_storeImpl.callbacks.push(callback)

Store::unregister = (callback) ->
  @_storeImpl.callbacks = _.reject(@_storeImpl.callbacks, (cb) -> cb == callback)

# register/unregister are general purpose, this is tailored for React mixins.
Store::listen = (callbackName) ->
  store = this
  return {
    componentDidMount: ->
      store.register(this[callbackName])
    componentWillUnmount: ->
      store.unregister(this[callbackName])
  }

Store::trigger = ->
  @_storeImpl.trigger()

Hippodrome.Store = Store
