IdFactory = (prefix) ->
  @lastId = 1
  @prefix = prefix

IdFactory::next = ->
  "#{@prefix}_#{@lastId++}"
