Action = (name, ctor) ->
  buildPayload = ->
    payload = ctor.apply(null, arguments)
    payload.action = name
    payload

  send = (payload) ->
    Hippodrome.Dispatcher.dispatch(payload)

  actionFn = ->
    payload = buildPayload.apply(null, arguments)
    send(payload)

  actionFn.buildPayload = buildPayload
  actionFn.send = send

  actionFn.hippoName = name
  actionFn.toString = -> name

  actionFn

Hippodrome.Action = Action
