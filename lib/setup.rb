require 'rubygems'
require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

autoload :App,        'app'
autoload :CONFIG,     File.expand_path('../../config', __FILE__)
autoload :DB,         'db'
autoload :Idea,       'idea'
autoload :WebSocket,  'web_socket'
