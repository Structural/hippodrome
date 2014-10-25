actionIds = new IdFactory('Action_ID')

Action = (name, ctor) ->
  id = "#{actionIds.next()}_#{name}"

  buildPayload = ->
    payload = ctor.apply(null, arguments)
    payload.action = id
    payload

  send = (payload) ->
    Hippodrome.Dispatcher.dispatch(payload)

  actionFn = ->
    payload = buildPayload.apply(null, arguments)
    send(payload)

  actionFn.buildPayload = buildPayload
  actionFn.send = send

  actionFn.displayName = name
  actionFn.id = id
  actionFn.toString = -> id

  actionFn

Hippodrome.Action = Action
