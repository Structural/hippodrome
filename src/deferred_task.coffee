makeDeferredFunction = (context, fn) ->
  if typeof fn == 'string'
    fn = context[fn]
  # _.defer loses context, so we have to do it ourselves.
  () ->
    args = arguments
    setTimeout((() -> fn.apply(context, args)), 1)

createDeferredTask = (options) ->
  # not P or Q is the same as P implies Q, i.e., assert fails if P is true
  # and Q is false.
  assert(not options.action or options.task,
         "Deferred Task #{options.displayName} declared an action, it must
          declare a task.")
  assert(not options.task or options.action,
         "Deferred Task #{options.displayName} declared a task, it must declare
          an action.")

  task = {}
  _.assign(task,
           _.omit(options, 'initialize', 'action', 'task'),
           bindToContextIfFunction(task))

  task.dispatch = (action) ->
    to = (callback) ->
      callback = makeDeferredFunction(task, callback)
      id = Hippodrome.Dispatcher.register(task, action.id, [], callback)
      task._dispatcherIdsByAction[action.id] = id
      return id
    return {to: to}

  task._dispatcherIdsByAction = {}

  if options.initialize
    task.dispatch(Hippodrome.start).to(options.initialize)

  if options.action and options.task
    task.dispatch(options.action).to(options.task)

  return task

Hippodrome.createDeferredTask = createDeferredTask
