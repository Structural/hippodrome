Hippodrome = require('../dist/hippodrome')

describe 'Stores', ->
  it 'don\'t expose properties not in public', ->
    store = Hippodrome.createStore
      propOne: 'one'

      public:
        propTwo: 'two'

    expect(store.propOne).toBe(undefined)
    expect(store.propTwo).toBe('two')

  it 'functions in public have access to non-public properties', ->
    store = Hippodrome.createStore
      prop: 'value'

      public:
        fn: () -> "My Property Is: #{@prop}"

    expect(store.fn()).toBe('My Property Is: value')

  it 'run registered functions on trigger', ->
    store = Hippodrome.createStore
      public:
        doTrigger: () -> @trigger()

    ran = false
    store.register(() -> ran = true)
    store.doTrigger()

    expect(ran).toBe(true)

  it 'don\'t run unregistered functions on trigger', ->
    store = Hippodrome.createStore
      public:
        doTrigger: () -> @trigger()

    ran = false
    callback = () -> @trigger()
    store.register(callback)
    store.unregister(callback)
    store.doTrigger()

    expect(ran).toBe(false)

  it 'run initialize on Hippodrome start', ->
    store = Hippodrome.createStore
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

    store = Hippodrome.createStore
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

    store = Hippodrome.createStore
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

    store = Hippodrome.createStore
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

    first = Hippodrome.createStore
      initialize: ->
        @dispatch(action).to(@doAction)

      x: 0
      doAction: (payload) ->
        @x = payload.n * payload.n

      public:
        value: () -> @x

    second = Hippodrome.createStore
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

  it 'fail when stores create a circular dependency', ->
    action = Hippodrome.createAction
      build: -> {}

    one = Hippodrome.createStore
      initialize: ->
        @dispatch(action).after(three).to(@doAction)

      doAction: (payload) ->
        @ran = true

    two = Hippodrome.createStore
      initialize: ->
        @dispatch(action).after(one).to(@doAction)

      doAction: (payload) ->
        @ran = true

    three = Hippodrome.createStore
      initialize: ->
        @dispatch(action).after(two).to(@doAction)

      doAction: (payload) ->
        @ran = true

    Hippodrome.start()
    expect(action).toThrow()

  it 'fail when the prerequisite store does not handle action', ->
    action = Hippodrome.createAction
      build: -> {}

    one = Hippodrome.createStore
      displayName: 'one'

    two = Hippodrome.createStore
      initialize: ->
        @dispatch(action).after(one).to(@doAction)

      doAction: ->
        @ran = true

    Hippodrome.start()
    expect(action).toThrow()
