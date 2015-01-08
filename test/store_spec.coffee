Hippodrome = require('../dist/hippodrome')
_ = require('lodash')

# This is annoying, but because the Dispatcher is a single instance across all
# tests, stores created in one test still have their callbacks registered in
# subsequent tests, unless we get rid of them like this.
unregisterStore = (store) ->
  _.forEach store._storeImpl.dispatcherIdsByAction, (id, action) ->
    Hippodrome.Dispatcher.unregister(action, id)

describe 'Stores', ->
  tempStores = []

  makeTempStore = (options) ->
    store = Hippodrome.createStore(options)
    tempStores.push(store)
    return store

  beforeEach ->
    tempStores = []

  afterEach ->
    _.forEach tempStores, unregisterStore

  it 'don\'t expose properties not in public', ->
    store = makeTempStore
      propOne: 'one'

      public:
        propTwo: 'two'

    expect(store.propOne).toBe(undefined)
    expect(store.propTwo).toBe('two')

  it 'functions in public have access to non-public properties', ->
    store = makeTempStore
      prop: 'value'

      public:
        fn: () -> "My Property Is: #{@prop}"

    expect(store.fn()).toBe('My Property Is: value')

  it 'run registered functions on trigger', ->
    store = makeTempStore
      public:
        doTrigger: () -> @trigger()

    ran = false
    store.register(() -> ran = true)
    store.doTrigger()

    expect(ran).toBe(true)

  it 'don\'t run unregistered functions on trigger', ->
    store = makeTempStore
      public:
        doTrigger: () -> @trigger()

    ran = false
    callback = () -> @trigger()
    store.register(callback)
    store.unregister(callback)
    store.doTrigger()

    expect(ran).toBe(false)

  it 'run initialize on Hippodrome start', ->
    store = makeTempStore
      initialize: ->
        @ran = true

      ran: false
      public:
        isRun: () -> @ran

    Hippodrome.start()

    expect(store.isRun()).toBe(true)

  it 'run initialize with options on Hippodrome start', ->
    store = Hippodrome.createStore
      initialize: (options) ->
        @x = options.n * 2

      public:
        value: () -> @x

    Hippodrome.start(n: 6)
    expect(store.value()).toBe(12)

  it 'run registered functions on action dispatch', ->
    action = Hippodrome.createAction
      displayName: 'test1'
      build: -> {}

    store = makeTempStore
      initialize: ->
        @dispatch(action).to(@doAction)

      ran: false
      doAction: (payload) ->
        @ran = true

      public:
        isRun: () -> @ran

    Hippodrome.start()
    action()

    expect(store.isRun()).toBe(true)

  it 'run registered functions by name on action dispatch', ->
    action = Hippodrome.createAction
      displayName: 'test2'
      build: -> {}

    store = makeTempStore
      initialize: ->
        @dispatch(action).to('doAction')

      ran: false
      doAction: (payload) ->
        @ran = true

      public:
        isRun: () -> @ran

    Hippodrome.start()
    action()

    expect(store.isRun()).toBe(true)

  it 'run registered functions with payload data', ->
    action = Hippodrome.createAction
      displayName: 'test3'
      build: (n) -> {n: n}

    store = makeTempStore
      initialize: ->
        @dispatch(action).to(@doAction)

      x: 0
      doAction: (payload) ->
        @x = payload.n * payload.n

      public:
        value: () -> @x

    Hippodrome.start()
    action(4)

    expect(store.value()).toBe(16)

  it 'run callbacks after other stores', ->
    action = Hippodrome.createAction
      displayName: 'test4'
      build: (n) -> {n: n}

    first = makeTempStore
      initialize: ->
        @dispatch(action).to(@doAction)

      x: 0
      doAction: (payload) ->
        @x = payload.n * payload.n

      public:
        value: () -> @x

    second = makeTempStore
      initialize: ->
        @dispatch(action).after(first).to(@doAction)

      x: 0
      doAction: (payload) ->
        @x = first.value() + payload.n

      public:
        value: () -> @x

    Hippodrome.start()
    action(5)

    expect(first.value()).toBe(25)
    expect(second.value()).toBe(30)

  it 'run callbacks after other stores no matter declaration order', ->
    action = Hippodrome.createAction
      displayName: 'test8'
      build: (n) -> {n: n}

    second = makeTempStore
      initialize: ->
        @x = 0
        @dispatch(action).after(first).to(@doAction)

      doAction: (payload) ->
        @x = payload.n + first.value()

      public:
        value: () -> @x

    first = makeTempStore
      initialize: ->
        @x = 0
        @dispatch(action).to(@doAction)

      doAction: (payload) ->
        @x = payload.n * 2

      public:
        value: () -> @x

    Hippodrome.start()
    action(3)

    expect(first.value()).toBe(6)
    expect(second.value()).toBe(9)

  it 'fail when stores create a circular dependency', ->
    action = Hippodrome.createAction
      build: -> {}

    one = makeTempStore
      initialize: ->
        @dispatch(action).after(three).to(@doAction)

      doAction: (payload) ->
        @ran = true

    two = makeTempStore
      initialize: ->
        @dispatch(action).after(one).to(@doAction)

      doAction: (payload) ->
        @ran = true

    three = makeTempStore
      initialize: ->
        @dispatch(action).after(two).to(@doAction)

      doAction: (payload) ->
        @ran = true

    Hippodrome.start()
    expect(action).toThrow()

  it 'fail when the prerequisite store does not handle action', ->
    action = Hippodrome.createAction
      build: -> {}

    one = makeTempStore
      displayName: 'one'

    two = makeTempStore
      initialize: ->
        @dispatch(action).after(one).to(@doAction)

      doAction: ->
        @ran = true

    Hippodrome.start()
    expect(action).toThrow()

  it 'fail when registering for same action more than once', ->
    action = Hippodrome.createAction
      build: -> {}

    store = makeTempStore
      initialize: ->
        @dispatch(action).to(->)
        @dispatch(action).to(->)

    expect(Hippodrome.start).toThrow()
