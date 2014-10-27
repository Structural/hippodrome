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
ProfileEditor.Actions.updateName = new Hippodrome.Action(
  'update Name',
  (newName) -> {name: newName}
)
```

The first argument is a name for the Action, which will show up in some error
messages and can be generally useful for figuring out what you're looking at
while debugging.  The second argument is a function that builds a payload with
the Action's data.  These functions should be as simple and pure as possible.
Avoid using the key `action` in your Action payloads - Hippodrome uses that
to identify which action the payload is from.

```coffeescript
# Sends the following object to the Dispatcher
#
# { action: 'Action_ID_1_update Name'
#   name: 'Alice'
# }

ProfileEditor.Actions.updateName('Alice')
```

## The Dispatcher

Continuing clockwise, we come to Hippodrome's Dispatcher.  There's only one
Dispatcher - it gets created when Hippodrome loads up and Actions, Stores and
Tasks all automatically register themselves with it.  For the most part, you
don't have to interact with it at all, but it's worth knowing what it does.

```coffeescript
id = Hippodrome.Dispatcher.register(
  Stores.UserProfile,
  Actions.updateName,
  (payload) -> @name = payload.name
)

id = Hippodrome.Dispatcher.register(
  Stores.ItemDetails,
  Actions.changeActiveItem,
  [Stores.AllItems, Stores.ActiveItem],
  (payload) -> @details = Stores.AllItems.byId(Stores.ActiveItem.id())
)
```

To register a callback with the Dispatcher, give it the Store (or Task) that
the callback is for, the Action that the callback is for and the callback to
run.  The Dispatcher will run the callback each time that Action is dispatched.
Optionally, include a list of other Stores that the callback for this Store
depends on - the Dispatcher will ensure that the callbacks for those Stores are
run before this one.

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
  [allItemsId, activeItemId]
)
```

While dispatching, run the listed callbacks before returning to the current
one.  `waitFor` will make sure to only run each callback once during an Action's
dispatch, and that any circular dependencies throw an error rather than running
forever.

# Stores

A Hippodrome Store encapsulates all the Dispatcher operations above and exposes
hooks for React views to get change events and new data out of the Store.
Declare one like so

```coffeescript
Stores.UserProfile = new Hippodrome.Store
  displayName: 'User Profile'

  initialize: ->
    @name = undefined
    @email = undefined

  dispatches: [{
    action: Actions.updateName,
    callback: (payload) -> @name = payload.name; @trigger()
  }, {
    action: Actions.updateEmail,
    after: [Stores.EmailService]
    callback: 'updateEmail'
  }]

  updateEmail: (payload) ->
    @email = payload.email
    @trigger()

  public:
    info: -> {name: @name, email: @email}
```

The Store's `displayName` is optional, but useful for debugging and error
messages.  The `initialize` function is run once, when the Store is declared,
and is used to set up the Store's state.  Generally, this is the empty state
before the app has any data.

The `dispatches` list is the meat of a Store.  It defines all the Actions and
callbacks that a Store should register with the Dispatcher.  Callbacks can be
either defined inline as an anonymous function, or as a string that names a
function defined on the Store.  In addition, any Stores named in the `after`
key will be automatically `waitFor`ed by the Dispatcher before running this
Store's callback.

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
    Stores.UserProfile.listen('onProfileInfoChange')
  ]

  getInitialState: -> {info: Stores.UserProfile.info()}

  onProfileInfoChange: ->
    @setState(info: Stores.UserProfile.info())

  render: ->
    div {className: 'profile'},
      span({className: 'name'}, @state.info.name),
      span({className: 'email'}, @state.info.email)
```

All Stores expose a `listen` mixin that takes the name of a function and
registers that function to be called by the Store whenever its data changes.
(Strictly speaking, whenever the Store's `trigger` method is called, which
should be whenever you change the data.)  If you prefer, you can register and
unregister a component from a store directly:

```coffeescript
Components.Profile = React.createClass
  componentDidMount: ->
    Stores.UserProfile.register(@onProfileInfoChange)

  componentWillUnmount: ->
    Stores.UserProfile.unregister(@onProfileInfoChange)
```

## Deferred Tasks

A Deferred Task (or just Task for short) is in many ways the dual of a Store.
Stores expose data to other parts of the system, Tasks can only hold internal
state.  Store callbacks should always run quickly and synchronously, Task
callbacks are always run asynchronously.  Stores can't dispatch new actions
during their callbacks, the point of Task callbacks is generally to send one
or more new actions.

Declare a Task like this:

```coffeescript
Tasks.SaveUserName = new Hippodrome.DeferredTask
  displayName: 'Save User Name'
  action: Actions.updateName
  task: (payload) ->
    successCallback = -> Actions.updateSuccess()
    errorCallback = -> Actions.apiError()
    Api.saveUserProfile({name: payload.name}, successCallback, errorCallback)
```

Again, `displayName` is used for debugging and error messages.  Each task can
only be run from one Action, named in the `action` key.  The function in the
`task` key is run every time the Dispatcher gets sent that action.  Unlike
Store functions, Task functions are automatically deferred before running -
Stores cannot wait on them, and there's no guarantee exactly when they'll
execute (though it will always be after any Stores have finished).

Stores are for holding your application's state, Tasks are for all the things
you need to do over time - making network requests to your API to get or save
data, running code periodically (like autosave) or repeatedly, like with
requestAnimationFrame.  Tasks can also be used when one action needs to spawn
more actions (remember, Stores cannot dispatch actions), such as an `appStart`
action getting picked up by a `BootstrapData` Task that rebroadcasts Actions
for each piece of bootstrap data sent by the server.

The role of Stores, Actions and the Dispatcher are relatively well understood,
or at least well defined by Facebook's description of Flux.  Tasks, being
Hippodrome's own invention, are more speculative.  We expect them to change
as we understand more of what we need out of them, and out of the system as a
whole.
