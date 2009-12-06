# Load the environment
require 'fileutils'
ENV['RAILS_ENV'] = 'test'
require 'rubygems'
require 'active_support'
require 'action_controller'
# Load the testing framework
require 'test_help'
silence_warnings { RAILS_ENV = ENV['RAILS_ENV'] }


gem 'shoulda'
gem 'mocha'
require 'shoulda'
require 'shoulda/action_view'
require 'shoulda/action_controller'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'health_monitor'


test_dir = File.expand_path(File.dirname(__FILE__) + '/../tmp')
FileUtils.mkdir_p(test_dir) unless File.exist?(test_dir)
RAILS_LOGGER = Logger.new(test_dir + '/test.log')
ActionController::Base.logger = nil

class Test::Unit::TestCase
end
