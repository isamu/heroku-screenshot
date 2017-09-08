require 'bundler'
Bundler.require

set :env, (ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development)

require './app'

run App

