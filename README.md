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
includes Side Effects, objects that can respond to Actions (like Stores) but
instead of exposing data to views, do additional asynchronous work like
making a network request and possibly dispatching more actions based on the
response.

## Installation

Add this line to your application's Gemfile:

    gem 'hippodrome'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hippodrome

## Usage

In your javascript manifest file:

    //= require hippodrome

TODO: Explain how all the bits work.

## Contributing

1. Fork it ( http://github.com/structural/hippodrome/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
