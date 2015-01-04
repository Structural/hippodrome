dispatcherIds = new IdFactory('Dispatcher_ID')

createDispatcher = () ->
  dispatcher =
    _callbacksByAction: {}
    _isStarted: {}
    _isFinished: {}
    _isDispatching: false
    _payload: null

  dispatcher.register = (action, callback, prerequisites=[]) ->
    @_callbacksByAction[action] ?= {}

    id = dispatcherIds.next()
    @_callbacksByAction[action][id] = {
      callback: callback
      prerequisites: _.map(prerequisites,
                           (pr) -> pr._storeImpl.dispatcherIdsByAction[action])
    }

    return id

  dispatcher.unregister = (action, id) ->
    assert(@_callbacksByAction and @_callbacksByAction[action][id],
           "Dispatcher.unregister(#{action.displayName}, #{id}) does not map
            to a registered callback.")
    delete @_callbacksByAction[action][id]

  dispatcher.waitFor = (action, ids) ->
    assert(@_isDispatching
           "Dispatcher.waitFor must be called while dispatching.")
    _.forEach ids, (id) =>
      if @_isStarted[id]
        assert(@_isFinished[id],
               "Dispatcher.waitFor encountered circular dependency trying to
                wait for #{id} during action #{action.displayName}.")
        return

      assert(@_callbacksByAction[action][id]
             "Dispatcher.waitFor #{id} is not a registered callback for
              #{action.displayName}.")
      @invokeCallback(action, id)

  dispatcher.dispatch = (payload) ->
    assert(not @_isDispatching,
           "Dispatcher.dispatch cannot be called during dispatch.")
    @startDispatching(payload)
    try
      action = payload._action
      _.forEach @_callbacksByAction[action], (callback, id) =>
        if @_isStarted[id]
          return

        @invokeCallback(action, id)
    finally
      @stopDispatching()

  dispatcher.invokeCallback = (action, id) ->
    @_isStarted[id] = true
    {callback, prerequisites} = @_callbacksByAction[action][id]
    @waitFor(action, prerequisites)
    callback(@_payload)
    @_isFinished[id] = true

  dispatcher.startDispatching = (payload) ->
    @_isStarted = {}
    @_isFinished = {}
    @_payload = payload
    @_isDispatching = true

  dispatcher.stopDispatching = ->
    @_payload = null
    @_isDispatching = false

  return dispatcher

Hippodrome.Dispatcher = createDispatcher()
