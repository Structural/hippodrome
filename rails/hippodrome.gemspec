# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hippodrome/version'

Gem::Specification.new do |spec|
  spec.name          = "hippodrome"
  spec.version       = Hippodrome::VERSION
  spec.authors       = ["Sean Kermes", "William Lubelski"]
  spec.email         = ["skermes@gmail.com", "will.lubelski@gmail.com"]
  spec.summary       = %q{Your data, like your chariots, go around and around in
                          one direction in this, a Flux implementation that only
                          Ben Hur could love.}
  spec.description   = %q{Your data, like your chariots, go around and around in
                          one direction in this, a Flux implementation that only
                          Ben Hur could love.}
  spec.homepage      = "https://github.com/Structural/hippodrome"
  spec.license       = "MIT"

  spec.files         = Dir["{lib,app}/**/*"] + ["LICENSE.txt", "README.md"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_dependency "railties", "~> 4.0"
  spec.add_dependency "lodash-rails", "~> 2.4.1"
end
