actionIds = new IdFactory('Action_ID')

createAction = (options) ->
  assert(options.build instanceof Function,
         "Action #{options.displayName} did not define a build function.")

  id = "#{actionIds.next()}_#{options.displayName}"

  buildPayload = ->
    payload = options.build.apply(null, arguments)
    payload.action = id
    return payload

  action = ->
    payload = buildPayload.apply(null, arguments)
    Hippodrome.Dispatcher.dispatch(payload)

  action.buildPayload = buildPayload
  action.displayName = options.displayName
  action.id = id
  action.toString = -> id

  return action

Hippodrome.createAction = createAction
