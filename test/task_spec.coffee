Hippodrome = require('../dist/hippodrome.js')

# Deferred Tasks run their callbacks outside the call stack that triggers them,
# so we have to do some awkwardness to test them.  In theory a callback could
# run more than 100 ms after it's been triggered, but in practice this works.
deferredExpect = (expect, done) ->
  test = ->
    expect()
    done()

  setTimeout(test, 100)

describe 'Deferred Tasks', ->
  it 'run a task for the action declared in options', (done) ->
    action = new Hippodrome.Action('run', -> {})
    task = Hippodrome.createDeferredTask
      ran: false
      action: action
      task: (payload) -> @ran = true

    action()

    deferredExpect((-> expect(task.ran).toBe(true)), done)

  it 'run a task with payload data', (done) ->
    action = new Hippodrome.Action('data', (x) -> {x: x})
    task = Hippodrome.createDeferredTask
      value: 0
      action: action
      task: (payload) -> @value = payload.x * payload.x

    action(5)

    deferredExpect((-> expect(task.value).toBe(25)), done)

  it 'run a task declared as a string', (done) ->
    action = new Hippodrome.Action('run', -> {})
    task = Hippodrome.createDeferredTask
      ran: false
      action: action
      task: 'doTask'
      doTask: (payload) -> @ran = true

    action()

    deferredExpect((-> expect(task.ran).toBe(true)), done)

  it 'run initialize on Hippodrome.start', (done) ->
    task = Hippodrome.createDeferredTask
      ran: false
      initialize: ->
        @ran = true

    Hippodrome.start()

    deferredExpect((-> expect(task.ran).toBe(true)), done)

  it 'call other task functions inside callbacks', (done) ->
    action = new Hippodrome.Action('run', -> {})
    task = Hippodrome.createDeferredTask
      ran: false
      action: action
      task: (payload) -> @doTask()
      doTask: () -> @ran = true

    action()

    deferredExpect((-> expect(task.ran).toBe(true)), done)

  it 'register for actions in initialize', (done) ->
    action = new Hippodrome.Action('run', -> {})
    task = Hippodrome.createDeferredTask
      ran: false
      initialize: ->
        @dispatch(action).to(@doTask)
      doTask: (payload) -> @ran = true

    Hippodrome.start()
    setTimeout((->
      action()
      deferredExpect((-> expect(task.ran).toBe(true)), done)
    ), 100)

  it 'register for the same task more than once', (done) ->
    action = new Hippodrome.Action('data', (x) -> {x: x})
    task = Hippodrome.createDeferredTask
      y: 0
      z: 0
      initialize: ->
        @dispatch(action).to((payload) -> @y = payload.x + 1)
        @dispatch(action).to((payload) -> @z = payload.x * 2)

    Hippodrome.start()
    setTimeout((->
      action(5)
      deferredExpect((-> expect(task.y).toBe(6)), ->)
      deferredExpect((-> expect(task.z).toBe(10)), done)
    ), 100)

  it 'fail to create with an action and no task', ->
    options =
      action: new Hippodrome.Action('a', -> {})

    create = ->
      Hippodrome.createDeferredTask(options)

    expect(create).toThrow()

  it 'fail to create with a task and no action', ->
    options =
      task: (payload) ->

    create = ->
      Hippodrome.createDeferredTask(options)

    expect(create).toThrow()
