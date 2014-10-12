Dispatcher = ->
  @callbacksByAction = {}
  @isStarted = {}
  @isFinished = {}
  @isDispatching = false
  @payload = null

prefix = 'Dispatcher_ID_'
lastId = 1
nextId = -> prefix + lastId++

Dispatcher.prototype.register = ->
  args = _.compact(arguments)

  if args.length == 3
    @register(args[0], args[1], [], args[2])
  else
    [store, action, prereqStores, callback] = args
    @callbacksByAction[action] ?= {}

    id = nextId()
    @callbacksByAction[action][id] = {
      callback: callback,
      prerequisites: _.map(prereqStores,
                           (ps) -> ps.dispatcherIdsByAction[action])
    }
    id

Dispatcher.prototype.unregister = (action, id) ->
  Hippodrome.assert(@callbacksByAction[action][id],
         'Dispatcher.unregister(%s, %s) does not map to a registered callback.',
         action, id)
  @callbacks[action][id] = null

Dispatcher.prototype.waitFor = (action, ids) ->
  Hippodrome.assert(@isDispatching,
         'Dispatcher.waitFor must be invoked while dispatching.')
  _.forEach(ids, (id) =>
    if @isStarted[id]
      Hippodrome.assert(@isFinished[id],
             'Dispatcher.waitFor encountered circular dependency while ' +
             'waiting for `%s` during %s.', id, action)
      return

    Hippodrome.assert(@callbacksByAction[action][id],
           'Dispatcher.waitFor `%s` is not a registered callback for %s.',
           id, action)
    @invokeCallback(action, id)
  )

Dispatcher.prototype.dispatch = (payload) ->
  Hippodrome.assert(not @isDispatching,
         'Dispatch.dispatch cannot be called during dispatch.')
  @startDispatching(payload)
  try
    action = payload.action
    _.forEach(@callbacksByAction[action], (callback, id) =>
      if @isStarted[id]
        return

      @invokeCallback(action, id)
    )
  finally
    @stopDispatching()

Dispatcher.prototype.invokeCallback = (action, id) ->
  @isStarted[id] = true
  {callback, prerequisites} = @callbacksByAction[action][id]
  @waitFor(action, prerequisites)
  callback(@payload)
  @isFinished[id] = true

Dispatcher.prototype.startDispatching = (payload) ->
  @isStarted = {}
  @isFinished = {}
  @payload = payload
  @isDispatching = true

Dispatcher.prototype.stopDispatching = ->
  @payload = null
  @isDispatching = false

Hippodrome.Dispatcher = new Dispatcher()