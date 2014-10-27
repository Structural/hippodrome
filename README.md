# Hippodrome

> At last the herald with loud blare of trumpet calls forth the impatient teams
> and launches the fleet chariots into the field. The swoop of forked lightning,
> the arrow sped by Scythian string, the trail of the swiftly-falling star, the
> leaden hurricane of bullets whirled from Balearic slings has never so rapidly
> split the airy paths of the sky.&hellip; Thus they go once round, then a
> second time; thus goes the third lap, thus the fourth&hellip;
>
> &mdash; [Sidonius](http://skookumpete.com/chariots.htm)

Hippodrome is an implementation of Facebook's
[Flux](http://facebook.github.io/flux/docs/overview.html)
architecture.  It adds some more structure (especially to Stores) to the ideas
beyond what [Facebook's Flux](https://github.com/facebook/flux) has and
includes Deferred Tasks, objects that can respond to Actions (like Stores) but
instead of exposing data to views, do additional asynchronous work like
making a network request and possibly dispatching more actions based on the
response.

For a more in-depth explanation, [read this](./docs/hippodrome.md).

## Installation

### Rails

Add this line to your application's Gemfile:

    gem 'hippodrome'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hippodrome

### Node

    npm install --save hippodrome

## Usage

### Rails

In your javascript manifest file:

    //= require hippodrome

### Node

    Hippodrome = require('hippodrome')

## Contributing

The actual project code is in `src/`.  `js/` and `app/` are where the compiled
assets go to get picked up by npm and bundler, respectively.

In order to build the code, install [node](http://nodejs.org/) and
[gulp](http://gulpjs.com/), install the dev dependencies with `npm install` and
then build with `gulp build`.  This will deposit the compiled javascript to
`js/` and `app/assets/javascripts/` and build a .gem file in `pkg/`.

`test/hippodrome-test` is both a rails app and a node project that can run the
tests in
`test/hippodrome-test/specs/javascripts/hippodrome/hippodrome_spec.coffee`.

To run the tests under rails, first `gulp build` in the project root, then
`bundle` in the test project to install the gem, the either
`rake spec:javascript` to run the tests in the console or `rails s` to start a
WEBrick server and see the tests at
[http://localhost:3000/specs](http://localhost:300/specs).

To run the tests under node, first `gulp build` in the project root, then
`npm install` in the test directory (you may need to `rm -r node_modules/*` if
you want to install the package again without bumping the version number), then
`npm run test`.
