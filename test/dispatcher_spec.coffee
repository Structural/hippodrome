Hippodrome = require('../dist/hippodrome')

describe 'Dispatcher', ->
  it 'calls a registered function', ->
    ran = false
    fn = () -> ran = true
    Hippodrome.Dispatcher.register('test1', fn)

    Hippodrome.Dispatcher.dispatch({_action: 'test1'})

    expect(ran).toBe(true)

  it 'doesn\'t call an unregistered function', ->
    ran = false
    fn = () -> ran = true
    id = Hippodrome.Dispatcher.register('test2', fn)
    Hippodrome.Dispatcher.unregister('test2', id)

    Hippodrome.Dispatcher.dispatch({_action: 'test2'})

    expect(ran).toBe(false)

  it 'fails to unregister a never-registered function', ->
    test = ->
      Hippodrome.Dispatcher.unregister('test3', 'qwer')

    expect(test).toThrow()

  it 'fails to dispatch while already dispatching', ->
    fn = () -> Hippodrome.Dispatcher.dispatch({_action: 'test5'})
    Hippodrome.Dispatcher.register('test4', fn)
    test = ->
      Hippodrome.Dispatcher.dispatch({_action: 'test4'})

    expect(test).toThrow()

