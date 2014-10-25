DeferredTask = (options) ->
  assert(options.action,
         'DeferredTask must register for exactly one action.')
  assert(options.task,
         'DeferredTask must supply exactly one task to run')

  {action, task} = options

  if typeof task == 'string'
    task = this[task]
  task = _.defer.bind(this, task)

  id = Hippodrome.Dispatcher.register(this, action.id, [], task)
  @_dispatcherIdsByAction = {}
  @_dispatcherIdsByAction[action.id] = id

  this

Hippodrome.DeferredTask = DeferredTask
