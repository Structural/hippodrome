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

SideEffect = (options) ->
  assert(options.action,
         'SideEffect must register for exactly one action.')
  assert(options.effect,
         'SideEffect must supply exactly one effect to run')

  {action, effect} = options

  if typeof effect == 'string'
    effect = this[effect]
  effect = _.defer.bind(this, effect)

  id = Dispatcher.register(this, action.hippoName, [], effect)
  @dispatcherIdsByAction = {}
  @dispatcherIdsByAction[action.hippoName] = id

  this

if typeof window == 'undefined'
  module.exports = SideEffect
else
  Hippodrome.SideEffect = SideEffect
