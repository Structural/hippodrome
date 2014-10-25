Dispatcher = ->
  @_callbacksByAction = {}
  @_isStarted = {}
  @_isFinished = {}
  @_isDispatching = false
  @_payload = null

dispatcherIds = new IdFactory('Dispatcher_ID')

Dispatcher.prototype.register = ->
  args = _.compact(arguments)

  if args.length == 3
    @register(args[0], args[1], [], args[2])
  else
    [store, action, prereqStores, callback] = args
    @_callbacksByAction[action] ?= {}

    id = dispatcherIds.next()
    @_callbacksByAction[action][id] = {
      callback: callback,
      prerequisites: _.map(prereqStores,
                           (ps) -> ps._storeImpl.dispatcherIdsByAction[action])
    }
    id

Dispatcher::unregister = (action, id) ->
  assert(@_callbacksByAction[action][id],
         'Dispatcher.unregister(%s, %s) does not map to a registered callback.',
         action, id)
  @_callbacksByAction[action][id] = null

Dispatcher::waitFor = (action, ids) ->
  assert(@_isDispatching,
         'Dispatcher.waitFor must be invoked while dispatching.')
  _.forEach(ids, (id) =>
    if @_isStarted[id]
      assert(@_isFinished[id],
             'Dispatcher.waitFor encountered circular dependency while ' +
             'waiting for `%s` during %s.', id, action)
      return

    assert(@_callbacksByAction[action][id],
           'Dispatcher.waitFor `%s` is not a registered callback for %s.',
           id, action)
    @invokeCallback(action, id)
  )

Dispatcher::dispatch = (payload) ->
  assert(not @_isDispatching,
         'Dispatch.dispatch cannot be called during dispatch.')
  @startDispatching(payload)
  try
    action = payload.action
    _.forEach(@_callbacksByAction[action], (callback, id) =>
      if @_isStarted[id]
        return

      @invokeCallback(action, id)
    )
  finally
    @stopDispatching()

Dispatcher::invokeCallback = (action, id) ->
  @_isStarted[id] = true
  {callback, prerequisites} = @_callbacksByAction[action][id]
  @waitFor(action, prerequisites)
  callback(@_payload)
  @_isFinished[id] = true

Dispatcher::startDispatching = (payload) ->
  @_isStarted = {}
  @_isFinished = {}
  @_payload = payload
  @_isDispatching = true

Dispatcher::stopDispatching = ->
  @_payload = null
  @_isDispatching = false

Hippodrome.Dispatcher = new Dispatcher()
