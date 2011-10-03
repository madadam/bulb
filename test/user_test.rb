require 'helper'

class UserTest < Test::Unit::TestCase
  def setup
    DB.select 1
    DB.flushdb
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

  test 'User.get_by_email returns user with the given email' do
    user = User.create :email => 'alice@example.com'

    assert_equal user, User.get_by_email('alice@example.com')
  end

  test 'User.get_by_email returns nil if email does not exist' do
    assert_nil User.get_by_email('invalid@example.com')
  end
end
