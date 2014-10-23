SideEffect = (options) ->
  assert(options.action,
         'SideEffect must register for exactly one action.')
  assert(options.effect,
         'SideEffect must supply exactly one effect to run')

  {action, effect} = options

  if typeof effect == 'string'
    effect = this[effect]
  effect = _.defer.bind(this, effect)

  id = Hippodrome.Dispatcher.register(this, action.hippoName, [], effect)
  @dispatcherIdsByAction = {}
  @dispatcherIdsByAction[action.hippoName] = id

  this

Hippodrome.SideEffect = SideEffect
