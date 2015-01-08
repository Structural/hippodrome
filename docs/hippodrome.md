# Hippodrome structure and API

First, read
[Facebook's explanation of Flux](https://github.com/facebook/flux/blob/master/README.md).
Hippodrome builds off those ideas, so understanding them will make much of what
follows clearer.

Good?  Good. Now here's Hippdrome:

![Hippodrome Data Flow Diagram](./img/hippodrome-diagram.png)

Hippodrome's structure is very similar to stock Flux, with the addition of
Deferred Tasks, which we'll cover in more detail later.  Two things to note:
First, the dashed lines represent asynchronous operations.  Second, the boxes
with white backgrounds aren't strictly part of the Hippodrome+React system, but
need to be there in order to complete the picture of how data moves around.

## Actions

Starting at the left of the diagram, a Hippodrome Action is a function that
builds a payload out of some arguments, then sends that payload to the
Dispatcher for consumption by Stores and Tasks. Declare them like this:

```coffeescript
ProfileEditor.Actions.updateName = Hippodrome.createAction
  displayName: 'Update Name'
  build: (newName) -> {name: newName}
```

The `displayName` property, like the one on React components, is used mostly for
debugging and error messages.  All Hippodrome objects can take a `displayName`
option.  The `build` option is a function that returns the payload object for
the action.  Payload builder functions should be as simple and pure as possible.
Avoid using `_action` as a property in your payloads - Hippodrome adds that
property automatically for the Dispatcher's use.

```coffeescript
# Sends a similar payload to the Dispatcher
#
# { _action: 'Action_ID_1_Update Name'
#   name: 'Alice'
# }

ProfileEditor.Actions.updateName('Alice')
```

Once you've created them, all actions are functions that build their payloads
and send them to the Dispatcher.  Arguments to an action are the same as the
arguments to the `build` function you defined.

## The Dispatcher

Continuing clockwise, we come to Hippodrome's Dispatcher.  There's only one
Dispatcher - it gets created when Hippodrome loads up and Actions, Stores and
Tasks all automatically register themselves with it.  For the most part, you
don't have to interact with it at all, but it's worth knowing what it does.

```coffeescript
id = Hippodrome.Dispatcher.register(
  Actions.updateName,
  (payload) -> @name = payload.name
)

id = Hippodrome.Dispatcher.register(
  Actions.changeActiveItem,
  (payload) -> @details = Stores.AllItems.byId(Stores.ActiveItem.id())
  [Stores.AllItems, Stores.ActiveItems]
)
```

To register a callback with the Dispatcher, give it the Action that the
callback is for and the callback to run.  The Dispatcher will run the callback
each time that Action is dispatched.  Optionally, include a list of other
Stores that the callback for this Store depends on - the Dispatcher will ensure
that the callbacks for those Stores are run before this one.

```coffeescript
Hippodrome.Dispatcher.unregister(Actions.updateName, id)
```

Unregister a callback (referenced by the id returned from `register`) from the
Dispatcher.

```coffeescript
# Get an Action payload manually by calling buildPayload
#
# payload = Actions.updateName.buildPayload('Bob')

Hippodrome.Dispatcher.dispatch(payload)
```

Send an Action payload to the Dispatcher.

```coffeescript
Hippodrome.Dispatcher.waitFor(
  Actions.changeActiveItem,
  [Stores.AllItems, Stores.ActiveItem]
)
```

While dispatching, run the callbacks that the given stores have registered
before returning to the current one.  `waitFor` will make sure to only run each
callback once during an Action's dispatch, and that any circular dependencies
throw an error rather than running forever.

# Stores

A Hippodrome Store encapsulates all the Dispatcher operations above and exposes
hooks for React views to get change events and new data out of the Store.
Declare one like so

```coffeescript
Stores.UserProfile = Hippodrome.createStore
  displayName: 'User Profile'

  initialize: (options) ->
    @_name = undefined
    @_email = undefined

    @dispatch(Actions.updateName).to(@updateName)
    @dispatch(Actions.updateEmail)
      .after(Stores.EmailService)
      .to(@updateEmail)

  updateName: (payload) ->
    @_name = payload.name
    @trigger()

  updateEmail: (payload) ->
    @_email = Stores.EmailService.address()
    @trigger()

  public:
    info: -> {name: @_name, email: @_email}
```

The `initialize` method on Stores has two functions.  First, Stores should use
it to set up their empty state before the app has filled them with data and
second, to register their callbacks with the Dispatcher for the relevant
actions.  Note that `initialize` isn't run until you call `Hippodrome.start`,
discussed later.

`this.dispatch` takes an action, and returns an object with a `to` closure.
`to` takes a function (or the name of a function on the store object) and
registers that function with the Dispatcher for the action.  `dispatch` also
returns an `after` closure that takes one or more other Stores that register
for this action, and automatically makes sure that those stores run their
callbacks first.

Note the @trigger function.  React components (and, I suppose, other things)
can register callbacks to run whenever the store changes - @trigger runs those
callbacks.  You should call it at the end of your action functions whenever
you've updated the Store's state.

The only fields available on the Store object returned from Hippodrome.Store
are those under the `public` key.  Hippodrome's stance is that views shouldn't
access Store data directly, Stores should expose a domain-specific API that
can, at least partially, insulate views from the structure of the underlying
data.

To consume a Store's data in a React view, do something like this

```coffeescript
{div, span} = React.DOM

Components.Profile = React.createClass
  displayName: 'Profile'

  mixins: [
    Stores.UserProfile.listen('info' Stores.UserProfile.info)
    Stores.ProfileStatus.listenWith('onProfileStatusUpdate')
  ]

  onProfileStatusUpdate: ->
    return {
      saved: Stores.ProfileStatus.isSaved(true)
      pending: Stores.ProfileStatus.isPending(true)
    }

  render: ->
    div {className: 'profile'},
      Components.StatusIndicator({
        saved: @state.saved,
        pending: @state.pending
      })
      span({className: 'name'}, @state.info.name),
      span({className: 'email'}, @state.info.email)
```

When you consume a Store's data in a React component, you almost always want
to have the component re-render itself when the Store's data changes. To make
that easy, all Stores expose the `listen` and `listenWith` functions that
return React mixins that manage updating component state.

`listen` takes the name of a state property and a function (usually, this is
a public function on the store you're listening to, but it could be any
function of no arguments).  It defines @getInitialState so that the return
value of the function is available at that property for the component's first
render, and will call @setState whenever the Store run @trigger.

`listenWith` takes the name of a function (defined on the component) and uses
that function to determine the state object it should update the component with.
This is a little less clean than `listen`, but useful when you need to
pass arguments to a function, pull more than one property out of a store, or
use more than one store to calculate a property.  Note that the function you
give to `listenWith` doesn't call @setState directly - it returns an object
that can be passed to it (and to @getInitialState).

```coffeescript
Components.Profile = React.createClass
  componentDidMount: ->
    Stores.UserProfile.register(@onProfileInfoChange)

  componentWillUnmount: ->
    Stores.UserProfile.unregister(@onProfileInfoChange)
```

If, for whatever reason, you don't want to use the `listen` or `listenWith`
mixins, you can register and unregister from a Store directly.  Make sure to
always register in `componentDidMount` and unregister in `componentWillUnmount`
to avoid React errors from trying to update an unmounted component.

## Deferred Tasks

A Deferred Task (or just Task for short) is in many ways the dual of a Store.
Stores expose data to other parts of the system, Tasks can only hold internal
state.  Store callbacks should always run quickly and synchronously, Task
callbacks are always run asynchronously.  Stores can't dispatch new actions
during their callbacks, the point of Task callbacks is generally to send one
or more new actions.

Declare a Task like this:

```coffeescript
Tasks.SaveUserName = Hippodrome.createDeferredTask
  displayName: 'Save User Name'

  action: Actions.updateName

  task: (payload) ->
    successCallback = -> Actions.updateSuccess()
    errorCallback = -> Actions.apiError()
    Api.saveUserProfile({name: payload.name}, successCallback, errorCallback)

Tasks.Autosave = Hippodrome.createDeferredTask
  displayName: 'Autosave'

  initialize: (options) ->
    @dispatch(Actions.startEditing).to(@startEditing)
    @dispatch(Actions.doneEditing).to('doneEditing')

  startEditing: (payload) ->
    @intervalId = setInterval(doAutosave, 30000)

  doneEditing: (payload) ->
    clearInterval(@intervalId)
    @intervalID = undefined
```

Tasks are in many ways the dual of Stores.  They both respond to Actions, but
for different purposes.  Unlike Store functions, Task functions are
automatically deferred before running - Stores cannot wait on them, and there's
no guarantee exactly when they'll execute (though it will always be after any
Stores have finished).

Stores are for holding your application's state, Tasks are for all the things
you need to do over time - making network requests to your API to get or save
data, running code periodically (like autosave) or repeatedly, like with
requestAnimationFrame.

Tasks can also be used when one action needs to spawn more actions (remember,
Stores cannot dispatch actions), such as an `appStart` action getting picked up
by a `BootstrapData` Task that rebroadcasts Actions for each piece of bootstrap
data sent by the server.

Many tasks only need to register for one action.  For those tasks, you can
set `action` and `task` properties when you create the task, and it'll register
the callback automatically.  For more complicated tasks, register your callbacks
like Stores, with `@dispatch` in `initialize`.  Note that Tasks cannot wait on
Stores or other Tasks, so there's no `after` option here.

The role of Stores, Actions and the Dispatcher are relatively well understood,
or at least well defined by Facebook's description of Flux.  Tasks, being
Hippodrome's own invention, are more speculative.  We expect them to change
as we understand more of what we need out of them, and out of the system as a
whole.

Start your Hippodrome app like this:

```
Hippodrome.start()

Hippodrome.start
  id: 12345
  name: 'Alice'
```

The `initialize` functions of Stores and Tasks aren't run when they're declared,
but only when you call `Hippodrome.start()`.  This allows you to, for example,
have one Store's action wait on another Store that isn't declared yet.

I generally call `Hippodrome.start` right after I call `React.renderComponent`
on my top-level app component, but you could probably do it almost anywhere.
If you pass an options object to `start`, that object will be passed as the
first (and only) argument to all Store and Task `initialize` functions.

Behind the scenes, `start` is an Action that Stores and Tasks are automatically
subscribed to, but note that since you can't subscribe to the same action more
than once in a given Store or Task, don't try to subscribe to it yourself.

Also don't call it more than once, or all your Stores will try to subscribe to
their actions again and complain at you about it.
