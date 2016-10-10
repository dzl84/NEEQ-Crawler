require 'mongoid'

Mongoid.load!("../mongoid.yml", ENV["MONGOID_ENV"])

require_relative 'storage/last_update'
require_relative 'storage/disclosure'
