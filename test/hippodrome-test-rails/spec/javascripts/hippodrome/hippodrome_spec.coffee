#= require ../helpers/spec_helper

if this.require
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
      effect: new Hippodrome.Action 'effect', -> {}

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

    @OtherNameStore = new Hippodrome.Store
      initialize: ->
        @otherName = null
      dispatches: [
        {
          action: @Actions.changeName
          callback: (payload) -> @name = "Other #{payload.name}"
        }
      ]

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
    StoreOne = @StoreOne

    @StoreTwo = new Hippodrome.Store
      initialize: ->
        @data = null
      dispatches: [
        {
          action: @Actions.run
          after: [@StoreOne]
          callback: (payload) -> @data = StoreOne.data * StoreOne.data
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
    StoreTwo = @StoreTwo

    @StoreThree = new Hippodrome.Store
      initialize: ->
        @data = null
      dispatches: [
        {
          action: @Actions.run
          after: [@StoreOne, @StoreTwo]
          callback: (payload) -> @data = StoreOne.data * StoreTwo.data
        }
        {
          action: @Actions.circle
          after: [@StoreTwo]
          callback: (payload) ->
        }
      ]
    Hippodrome.Dispatcher.register(
      @StoreOne, @Actions.circle.hippoName, [@StoreThree], ->)

    @StoreWithAPI = new Hippodrome.Store
      initialize: ->
        @data = {foo: 'Foo'}
      getFoo: ->
        @data.foo

  it 'can send an action to a store', ->
    @Actions.changeName('Alice')

    expect(@NameStore.name).toBe('Alice')

  it 'can send an action to a store via named function', ->
    @Actions.changeName('Bob')

    expect(@NameStore.name).toBe('Bob')

  it 'can send an action to multiple stores', ->
    @Actions.changeName('Charlie')

    expect(@NameStore.name).toBe('Charlie')
    expect(@OtherNameStore.name).toBe('Other Charlie')

  it 'can have one store wait for another', ->
    @Actions.run()

    expect(@StoreOne.data).toBe(4)
    expect(@StoreTwo.data).toBe(16)
    expect(@StoreThree.data).toBe(64)

  it 'can send an action to a side effect', (done) ->
    effected = false
    MyEffect = new Hippodrome.SideEffect
      action: @Actions.effect
      effect: (payload) -> effected = true

    @Actions.effect()

    # SideEffects execute after the current call stack is done, so in order to
    # test that they worked, we also have to bounce off the call stack.  This
    # is kind of a hack, but it works.
    test = ->
      expect(effected).toBe(true)
      done()

    setTimeout(test, 100)

  it 'can send an action in two steps.', ->
    payload = @Actions.changeName.buildPayload('Dave')
    @Actions.changeName.send(payload)

    expect(@NameStore.name).toBe('Dave')

  it 'can call other functions on a store', ->
    expect(@StoreWithAPI.getFoo()).toBe('Foo')

  it 'fails when store prerequisites have a circular dependency', ->
    sendCircularDep = -> @Actions.circle()

    expect(sendCircularDep).toThrow()

  it 'fails when prerequisite store does not handle action', ->
    sendBadPrereq = -> @Actions.badPrereq()

    expect(sendBadPrereq).toThrow()

  it 'fails when dispatching during dispatch', ->
    sendDispatchDuringDispatch = -> @Actions.dispatchDuringDispatch()

    expect(sendDispatchDuringDispatch).toThrow()

  it 'fails when creating a side effect with no action', ->
    makeBadSideEffect = ->
      new Hippodrome.SideEffect
        effect: (payload) ->

    expect(makeBadSideEffect).toThrow()

  it 'fails when creating a side effect with no effect', ->
    makeBadSideEffect = ->
      new Hippodrome.SideEffect
        action: @Actions.effect

    expect(makeBadSideEffect).toThrow()
