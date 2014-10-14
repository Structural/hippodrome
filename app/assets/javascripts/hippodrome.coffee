#= require lodash
#= require_self
#= require_tree .

if typeof window == 'undefined'
  module.exports = {
    Action: require('./action'),
    assert: require('./assert'),
    Dispatcher: require('./dispatcher'),
    SideEffect: require('./side_effect'),
    Store: require('./store')
  }
else
  this.Hippodrome = {}
