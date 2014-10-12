Hippodrome.assert = (condition, message, args...) ->
  if not condition
    # TODO: Don't report in non-dev mode
    argIndex = 0;
    error = new Error('Assertion Failed: ' +
                      message.replace(/%s/g, -> args[argIndex++]))

    # Ignore assert's frame
    error.framesToPop = 1
    throw error

  condition
