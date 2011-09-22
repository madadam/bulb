require 'test/unit'
require 'idea'

class IdeaTest < Test::Unit::TestCase
  def setup
    $redis.select 1
    $redis.flushdb
  end

  def test_create_stores_the_idea_in_redis
    Idea.create('fly to mars')

    assert_equal 1, $redis.hlen('ideas')
    assert_equal 'fly to mars', $redis.hget('ideas', '1')
  end

  def test_update_updates_an_idea
    idea = Idea.create('fly to jupiter')
    Idea.update(idea.id, 'fly to uranus')
    idea = Idea.get(idea.id)

    assert_equal 'fly to uranus', idea.text
  end

  def test_delete_deletes_an_idea
    idea = Idea.create('create artificial inteligence')
    Idea.delete(idea.id)

    assert_nil Idea.get(idea.id)
  end

  def test_get_retrieves_idea_by_id
    idea1 = Idea.create('create wormhole')
    idea2 = Idea.get(idea1.id)

    assert_equal idea1, idea2
  end

  def test_all_retrieves_all_previously_created_ideas
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

  def test_to_json
    idea = Idea.create('take over the world')

    assert_equal %({"id":1,"text":"take over the world"}), idea.to_json
  end
end
