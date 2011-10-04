require 'helper'

class Ninja
  include Persistent

  string  :name
  string  :weapon
  integer :kills

  index   :name
end

class Samurai
  include Persistent
end

class PersistentTest < Test::Unit::TestCase
  def setup
    setup_redis
  end

  test '.create stores id and attributes' do
    Ninja.create :id => 1, :name => 'takeshi', :weapon => 'katana'

    assert @redis.sismember('ninjas', 1)
    assert_equal 'takeshi', @redis.get('ninjas/1/name')
    assert_equal 'katana',  @redis.get('ninjas/1/weapon')
  end

  test '.create autogenerates id if not given' do
    record = Ninja.create :name => 'masaru', :weapon => 'shuriken'

    assert_not_nil record.id
    assert @redis.sismember('ninjas', record.id)
  end

  test '.get gets a record by id' do
    record = Ninja.create :id => 42, :name => 'takeshi'
    assert_equal record, Ninja.get(42)
  end

  test '.get returns nil if record with the given id does not exist' do
    assert_nil Ninja.get(43)
  end

  test '.get_or_create returns record with the given id if it exists' do
    record = Ninja.create :id => 8, :name => 'masaru'
    assert_equal record, Ninja.get_or_create(8)
  end

  test '.get_or_create creates new record with the given id if it does not exist' do
    record = Ninja.get_or_create(22)

    assert_not_nil record
    assert_equal 22, record.id
  end

  test '.all returns all records' do
    record1 = Ninja.create :name => 'kenta'
    record2 = Ninja.create :name => 'masaru'
    record3 = Ninja.create :name => 'takeshi'

    all = Ninja.all
    all.sort_by!(&:name) # Need to sort, because all does not have defined order

    assert_equal [record1, record2, record3], all
  end

  test '.all returns empty array if there are no record' do
    assert_equal [], Ninja.all
  end

  test '.key returns record collection key' do
    assert 'ninjas', Ninja.key
  end

  test '.next_id! returns new id every time it is called' do
    assert_equal 1, Ninja.next_id!
    assert_equal 2, Ninja.next_id!
    assert_equal 3, Ninja.next_id!
  end

  test 'records are equal if they are of the same class with the same id' do
    Ninja.create :id => 22, :name => 'takeshi'

    record1 = Ninja.get(22)
    record2 = Ninja.get(22)

    assert_equal record1, record2
  end

  test 'records are not equal if they have different id' do
    record1 = Ninja.create :id => 23, :name => 'takeshi'
    record2 = Ninja.create :id => 24, :name => 'kenta'

    assert_not_equal record1, record2
  end

  test 'records are not equal if they are of different class' do
    record1 = Ninja.create :id => 1
    record2 = Samurai.create :id => 1

    assert_not_equal record1, record2
  end

  test '#delete deletes all attributes of the record' do
    record = Ninja.create :id => 1, :name => 'masaru', :weapon => 'sai'
    record.delete

    assert_nil @redis.get('ninjas/1/name')
    assert_nil @redis.get('ninjas/1/weapon')
  end

  test '#delete removes record id from the id set' do
    record = Ninja.create :id => 2, :name => 'kenta'
    record.delete

    assert !@redis.sismember('ninjas', 2)
  end

  test '.attributes returns names of all attributes' do
    assert_equal [:name, :weapon, :kills], Ninja.attributes.to_a
  end

  test 'string attribute can be read' do
    record = Ninja.create :name => 'kenta'
    assert_equal 'kenta', record.name
  end

  test 'string attribute can be written' do
    record = Ninja.create :name => 'kenta'
    record.name = 'katashi'

    assert_equal 'katashi', record.name
  end

  test 'integer attribue can be read' do
    record = Ninja.create :kills => 992

    assert_equal 992, record.kills
  end

  test 'integer attribute can be written' do
    record = Ninja.create :kills => 992
    record.kills = 993

    assert_equal 993, record.kills
  end

  test '#increment! without amount increments integer attribute by one' do
    record = Ninja.create :kills => 22
    record.increment!(:kills)

    assert_equal 23, record.kills
  end

  test '#increment! with amount increments integer attribute by the given amount' do
    record = Ninja.create :kills => 22
    record.increment!(:kills, 100)

    assert_equal 122, record.kills
  end

  test 'indexes attributes' do
    Ninja.create :id => 24, :name => 'takeshi'
    assert_equal '24', @redis.hget('ninjas/by-name', 'takeshi')
  end

  test 'record can be retrieved by an indexed attribute' do
    record1 = Ninja.create :name => 'kenta'
    record2 = Ninja.create :name => 'masaru'

    assert_equal record1, Ninja.get_by_name('kenta')
  end

  test 'nil is returned if record with the given indexed attribute does not exist' do
    assert_nil Ninja.get_by_name('yukihiro')
  end

  test '#delete removes the record from the indices' do
    record = Ninja.create :id => 2, :name => 'masaru'
    record.delete

    assert_nil @redis.hget 'ninjas/by-name', 'masaru'
  end
end
