require 'json'

module Hippodrome
  VERSION = JSON.load(File.open('package.json', 'r'))['version']
end
