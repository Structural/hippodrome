makeDeferredFunction = (context, fn) ->
  if typeof fn == 'string'
    fn = context[fn]
  # _.defer loses context, so we have to do it ourselves.
  () -> setTimeout((() -> fn.call(context)), 1)

DeferredTask = (options) ->
  @displayName = options.displayName

  assert(options.action or options.dispatches,
         "Deferred Task #{@displayName} must include either an action key or
          dispatches list.")
  # not P or Q is equivalent to P implies Q
  assert(not options.action or options.task,
         "Deferred Task #{@displayName} declared an action, it must declare a
         task.")

  _.assign(this, _.omit(options, 'dispatches', 'action', 'task'), bindToContextIfFunction(this))

  @_dispatcherIdsByAction = {}

  if options.initialize
    options.initialize.call(this)

  if options.action and options.task
    {action, task} = options

    task = makeDeferredFunction(this, task)
    id = Hippodrome.Dispatcher.register(this, action.id, [], task)

    @_dispatcherIdsByAction[action.id] = id

  if options.dispatches
    _.forEach(options.dispatches, (dispatch) =>
      {action, callback} = dispatch

      assert(not @_dispatcherIdsByAction[action.id],
             "Deferred Task #{@displayName} registered two callbacks for the
              action #{action.displayName}.")

      callback = makeDeferredFunction(this, callback)
      id = Hippodrome.Dispatcher.register(this, action.id, [], callback)
      @_dispatcherIdsByAction[action.id] = id
    )

  this

Hippodrome.DeferredTask = DeferredTask
