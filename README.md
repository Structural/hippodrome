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

### Bower

    bower install --save hippodrome

## Usage

### Rails

In your javascript manifest file:

    //= require hippodrome

### Node

    Hippodrome = require('hippodrome')

### Bower

Hippodrome will either set a top-level `window.Hippodrome` object or export
a node-style `Hippodrome = require('hippodrome')` module, depending on what
it detects in your environment.

## Contributing

The actual project code is in `src/`.  Running `gulp build` will compile the
coffeescript files into `dist/`.  `gulp test` runs a jasmine test suite on
the code in `dist`.  `gulp watch` will watch `src` for changes and run the
tests on each change.
