ENV['RACK_ENV'] = 'test'

require 'setup'
require 'test/unit'
require 'friendly_test_names'

class Test::Unit::TestCase
  private

  def setup_redis
    @redis = Persistent.redis
    @redis.select 1
    @redis.flushdb
  end
end
