if typeof window == 'undefined'
  Hippodrome = require('hippodrome')
else
  Hippodrome = this.Hippodrome

describe 'Hippodrome', ->
  beforeEach ->
    @Actions =
      changeName: new Hippodrome.Action 'changeName',
                                             (name) -> {name: name}
      changeNameViaFn: new Hippodrome.Action 'changeNameViaFn',
                                                  (name) -> {name: name}
      run: new Hippodrome.Action 'run', -> {}
      dispatchDuringDispatch:
        new Hippodrome.Action 'dispatchDuringDispatch', -> {}
      circle: new Hippodrome.Action 'circle', -> {}
      badPrereq: new Hippodrome.Action 'badPrereq', -> {}
      task: new Hippodrome.Action 'task', -> {}
      trigger: new Hippodrome.Action 'trigger', -> {}

    @NameStore = new Hippodrome.Store
      initialize: ->
        @name = null
      dispatches: [
        {
          action: @Actions.changeName
          callback: (payload) -> @name = payload.name
        }
        {
          action: @Actions.changeNameViaFn
          callback: 'changeNameFn'
        }
      ]
      changeNameFn: (payload) -> @name = payload.name
      public:
        getName: -> @name

    @OtherNameStore = new Hippodrome.Store
      initialize: ->
        @otherName = null
      dispatches: [
        {
          action: @Actions.changeName
          callback: (payload) -> @otherName = "Other #{payload.name}"
        }
      ]
      public:
        getName: -> @otherName

    @StoreOne = new Hippodrome.Store
      initialize: ->
        @data = 3
      dispatches: [
        {
          action: @Actions.run
          callback: (payload) -> @data += 1
        }
        {
          action: @Actions.dispatchDuringDispatch
          callback: (payload) ->
            Hippodrome.Dispatcher.dispatch @Actions.run()
        }
      ]
      public:
        data: -> @data
    StoreOne = @StoreOne

    @StoreTwo = new Hippodrome.Store
      initialize: ->
        @data = null
      dispatches: [
        {
          action: @Actions.run
          after: [@StoreOne]
          callback: (payload) -> @data = StoreOne.data() * StoreOne.data()
        }
        {
          action: @Actions.circle
          after: [@StoreOne]
          callback: (payload) ->
        }
        {
          action: @Actions.badPrereq
          after: [@StoreOne]
          callback: (payload) ->
        }
      ]
      public:
        data: -> @data
    StoreTwo = @StoreTwo

    @StoreThree = new Hippodrome.Store
      initialize: ->
        @data = null
      dispatches: [
        {
          action: @Actions.run
          after: [@StoreOne, @StoreTwo]
          callback: (payload) -> @data = StoreOne.data() * StoreTwo.data()
        }
        {
          action: @Actions.circle
          after: [@StoreTwo]
          callback: (payload) ->
        }
      ]
      public:
        data: -> @data
    Hippodrome.Dispatcher.register(
      @StoreOne, @Actions.circle, [@StoreThree], ->)

    @StoreWithAPI = new Hippodrome.Store
      initialize: ->
        @data = {foo: 'Foo'}
      public:
        getFoo: -> @data.foo
        getBar: -> "#{@getFoo()}Bar"
      notVisibleToAPI: -> 'Bar'

    @StoreWithTrigger = new Hippodrome.Store
      initialize: ->
        @data = 0
      dispatches: [{
        action: @Actions.trigger
        callback: (payload) -> @data = 5; @trigger()
      }]
      public:
        data: -> @data

  it 'can send an action to a store', ->
    @Actions.changeName('Alice')

    expect(@NameStore.getName()).toBe('Alice')

  it 'can send an action to a store via named function', ->
    @Actions.changeName('Bob')

    expect(@NameStore.getName()).toBe('Bob')

  it 'can send an action to multiple stores', ->
    @Actions.changeName('Charlie')

    expect(@NameStore.getName()).toBe('Charlie')
    expect(@OtherNameStore.getName()).toBe('Other Charlie')

  it 'can have one store wait for another', ->
    @Actions.run()

    expect(@StoreOne.data()).toBe(4)
    expect(@StoreTwo.data()).toBe(16)
    expect(@StoreThree.data()).toBe(64)

  it 'can send an action to a deferred task', (done) ->
    tasked = false
    MyTask = new Hippodrome.DeferredTask
      action: @Actions.task
      task: (payload) -> tasked = true

    @Actions.task()

    # DeferredTasks execute after the current call stack is done, so in order to
    # test that they worked, we also have to bounce off the call stack.  This
    # is kind of a hack, but it works.
    test = ->
      expect(tasked).toBe(true)
      done()

    setTimeout(test, 100)

  it 'can register a deferred task for multiple actions', (done) ->
    tasked = false

    MultiTask = new Hippodrome.DeferredTask
      ran: false
      dispatches: [{
        action: @Actions.task
        callback: (payload) -> tasked = true
      }, {
        action: @Actions.run
        callback: 'onRun'
      }]
      onRun: (payload) -> @ran = true

    @Actions.task()
    @Actions.run()

    test = ->
      expect(tasked).toBe(true)
      expect(MultiTask.ran).toBe(true)
      done()

    setTimeout(test, 100)

  it 'can send an action in two steps.', ->
    payload = @Actions.changeName.buildPayload('Dave')
    @Actions.changeName.send(payload)

    expect(@NameStore.getName()).toBe('Dave')

  it 'can call public functions on a store', ->
    expect(@StoreWithAPI.getFoo()).toBe('Foo')

  it 'can call public functions from other public function', ->
    expect(@StoreWithAPI.getBar()).toBe('FooBar')

  it 'can\'t see functions not declared in public', ->
    expect(@StoreWithAPI.notVisibleToAPI).toBe(undefined)

  it 'doesn\'t run callbacks that weren\'t registered to the action', ->
    @Actions.changeName('Ephraim')
    expect(@NameStore.getName()).toBe('Ephraim')

    @Actions.run()
    expect(@NameStore.getName()).toBe('Ephraim')

  it 'runs callbacks registered to stores on trigger', ->
    triggered = false
    fn = -> triggered = true
    @StoreWithTrigger.register(fn)
    @Actions.trigger()

    expect(triggered).toBe(true)

  it 'fails when store prerequisites have a circular dependency', ->
    sendCircularDep = -> @Actions.circle()

    expect(sendCircularDep).toThrow()

  it 'fails when prerequisite store does not handle action', ->
    sendBadPrereq = -> @Actions.badPrereq()

    expect(sendBadPrereq).toThrow()

  it 'fails when dispatching during dispatch', ->
    sendDispatchDuringDispatch = -> @Actions.dispatchDuringDispatch()

    expect(sendDispatchDuringDispatch).toThrow()

  it 'fails when creating a deferred task with no action', ->
    makeBadDeferredTask = ->
      new Hippodrome.DeferredTask
        effect: (payload) ->

    expect(makeBadDeferredTask).toThrow()

  it 'fails when creating a deferred task with no effect', ->
    makeBadDeferredTask = ->
      new Hippodrome.DeferredTask
        action: @Actions.task

    expect(makeBadDeferredTask).toThrow()
