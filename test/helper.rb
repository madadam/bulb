ENV['RACK_ENV'] = 'test'

require 'setup'
require 'test/unit'
require 'friendly_test_names'

CONFIG[:web_socket_port] = 4001

class Test::Unit::TestCase
  private

  def setup_redis
    @redis = Persistent::REDIS
    @redis.select 1
    @redis.flushdb
  end
end
