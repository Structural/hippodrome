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
