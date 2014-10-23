Hippodrome =
  Action: Action
  Dispatcher: Dispatcher
  SideEffect: SideEffect
  Store: Store

isNode = typeof window == 'undefined'

if isNode
  module.exports = Hippodrome
else
  this.Hippodrome = Hippodrome
