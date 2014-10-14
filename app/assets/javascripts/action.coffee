#= require ./dispatcher

if typeof window == 'undefined'
  Dispatcher = require('./dispatcher')
else
  Dispatcher = Hippodrome.Dispatcher

Action = (name, ctor) ->
  buildPayload = ->
    payload = ctor.apply(null, arguments)
    payload.action = name
    payload

  send = (payload) ->
    Dispatcher.dispatch(payload)

  actionFn = ->
    payload = buildPayload.apply(null, arguments)
    send(payload)

  actionFn.buildPayload = buildPayload
  actionFn.send = send

  actionFn.hippoName = name
  actionFn.toString = -> name

  actionFn

if typeof window == 'undefined'
  module.exports = Action
else
  Hippodrome.Action = Action
