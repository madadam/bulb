require 'helper'

class UserTest < Test::Unit::TestCase
  def setup
    setup_redis
  end

  test 'User.authenticate returns user with the given email and password' do
    user = User.create :email => 'alice@example.com', :password => 'foobar'

    assert_equal user, User.authenticate('alice@example.com', 'foobar')
  end

  test 'User.authenticate returns nil if email is invalid' do
    assert_nil User.authenticate('invalid@example.com', 'invalid')
  end

  test 'User.authenticate returns nil if password is invalid' do
    User.create :email => 'alice@example.com', :password => 'foobar'

    assert_nil User.authenticate('alice@example.com', 'invalid')
  end
end
