#= require ./dispatcher
#= require ./assert

if typeof window == 'undefined'
  _ = require('lodash')
  Dispatcher = require('./dispatcher')
  assert = require('./assert')
else
  _ = this._
  Dispatcher = Hippodrome.Dispatcher
  assert = Hippodrome.assert

bindToContextIfFunction = (context) ->
  (objValue, srcValue) ->
    if srcValue instanceof Function
      srcValue.bind(context)
    else
      srcValue

Store = (options) ->
  @dispatcherIdsByAction = {}
  @callbacks = []
  _.assign(this, _.omit(options, 'initialize', 'dispatches'), bindToContextIfFunction(this))

  if options.initialize
    options.initialize.call(@)

  if options.dispatches
    _.forEach(options.dispatches, (callbackDescription) =>
      {action, after, callback} = callbackDescription

      assert(not @dispatcherIdsByAction[action.hippoName]
             'Each store can only register one callback for each action.')

      if typeof callback == 'string'
        callback = @[callback]
      callback = callback.bind(@)

      id = Dispatcher.register(this, action.hippoName, after, callback)
      @dispatcherIdsByAction[action.hippoName] = id
    )

  this

Store.prototype.register = (callback) ->
  @callbacks.push(callback)

Store.prototype.unregister = (callback) ->
  @callbacks = _.reject(@callbacks, (cb) -> cb == callback)

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
  _.forEach(@callbacks, (callback) -> callback())

if typeof window == 'undefined'
  module.exports = Store
else
  Hippodrome.Store = Store
