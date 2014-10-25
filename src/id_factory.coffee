IdFactory = (prefix) ->
  @_lastId = 1
  @_prefix = prefix

IdFactory::next = ->
  "#{@_prefix}_#{@_lastId++}"
