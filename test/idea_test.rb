require 'helper'
require 'idea'

class IdeaTest < Test::Unit::TestCase
  def setup
    $redis.select 1
    $redis.flushdb
  end

  test 'Idea.create stores the idea in redis' do
    Idea.create('fly to mars')
    assert_equal 1, $redis.hlen('ideas')
  end

  test 'Idea.update updates an idea' do
    idea = Idea.create('fly to jupiter')
    Idea.update(idea.id, 'fly to uranus')
    idea = Idea.get(idea.id)

    assert_equal 'fly to uranus', idea.text
  end

  test 'Idea.delete deletes an idea' do
    idea = Idea.create('create artificial inteligence')
    Idea.delete(idea.id)

    assert_nil Idea.get(idea.id)
  end

  test 'Idea.get retrieves idea by id' do
    idea1 = Idea.create('create wormhole')
    idea2 = Idea.get(idea1.id)

    assert_equal idea1, idea2
  end

  test 'Idea.all retrieves all previously created ideas' do
    Idea.create('invent time travel')
    Idea.create('travel to future')
    Idea.create('go back and profit')

    ideas = Idea.all

    assert_equal 3, ideas.size

    assert_equal 1, ideas[0].id
    assert_equal 'invent time travel', ideas[0].text

    assert_equal 2, ideas[1].id
    assert_equal 'travel to future', ideas[1].text

    assert_equal 3, ideas[2].id
    assert_equal 'go back and profit', ideas[2].text
  end

  test 'Idea.all retrieves the ideas sorted' do
    idea1 = Idea.create('foo')
    idea2 = Idea.create('bar')
    idea3 = Idea.create('baz')

    idea2.vote!(1)
    idea3.vote!(2)

    ideas = Idea.all

    assert_equal 'baz', ideas[0].text
    assert_equal 'bar', ideas[1].text
    assert_equal 'foo', ideas[2].text
  end

  test 'Idea#to_json' do
    idea = Idea.create('take over the world')

    expected = {:id        => 1,
                :timestamp => idea.timestamp,
                :text      => 'take over the world',
                :votes     => 0}

    assert_equal expected.to_json, idea.to_json
  end

  test 'ideas are created with zero votes' do
    idea = Idea.create('foo')
    assert_equal 0, idea.votes
  end

  test 'Idea#vote!' do
    idea = Idea.create('foo')

    idea.vote!(1)
    assert_equal 1, idea.votes

    idea.vote!(-1)
    assert_equal 0, idea.votes
  end

  test 'Idea#vote! with negative number does nothing if there are zero votes' do
    idea = Idea.create('foo')
    idea.vote!(-1)

    assert_equal 0, idea.votes
  end

  test 'votes are preserved' do
    idea = Idea.create('foo')
    idea.vote!(3)

    idea = Idea.get(idea.id)
    assert_equal 3, idea.votes
  end

  test 'older idea is before a younger one if they have the same votes' do
    idea1 = Idea.create('foo')
    idea2 = Idea.create('bar')

    idea1.timestamp = Time.local(2011, 9, 27, 22, 10, 11)
    idea2.timestamp = Time.local(2011, 9, 27, 22, 10, 21)
    assert idea1 < idea2

    idea1.vote!(4)
    idea2.vote!(4)
    assert idea1 < idea2
  end

  test 'idea with more votes is before one with less votes' do
    idea1 = Idea.create('foo')
    idea2 = Idea.create('bar')

    idea1.vote!(2)
    idea2.vote!(3)
    assert idea2 < idea1
  end
end
