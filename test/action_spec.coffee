Hippodrome = require('../dist/hippodrome')

describe 'Actions', ->
  it 'are assigned ids that include their name', ->
    action = Hippodrome.createAction
      displayName: 'my action'
      build: -> {}

    expect(action.id).toMatch(/my action/g)

  it 'are assigned unique ids', ->
    action1 = Hippodrome.createAction
      displayName: 'action'
      build: -> {}
    action2 = Hippodrome.createAction
      displayName: 'action'
      build: -> {}

    expect(action1.id).not.toEqual(action2.id)

  it 'returns their id from toString', ->
    action = Hippodrome.createAction
      displayName: 'action'
      build: -> {}

    expect(action.toString()).toEqual(action.id)

  it 'can build their payload', ->
    action = Hippodrome.createAction
      displayName: 'action'
      build: (x) ->
        x: x

    payload =
      _action: action.id
      x: 5

    expect(action.buildPayload(5)).toEqual(payload)

  it 'fail to create with no build property', ->
    create = ->
      Hippodrome.createAction({})

    expect(create).toThrow()

  it 'fail to create with non-function build property', ->
    create = ->
      Hippodrome.createAction(build: 'not a fn')

    expect(create).toThrow()
