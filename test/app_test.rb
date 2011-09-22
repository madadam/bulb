require 'test/unit'
require 'rack/test'
require 'app'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    $redis.select 1
    $redis.flushdb
  end

  def test_get_root
    get '/'
    assert_equal 200, last_response.status
  end

  def test_get_ideas
    Idea.create('collect underpants')
    Idea.create('?')
    Idea.create('profit')

    get '/ideas'
    assert_equal 200, last_response.status

    expected = [{'id' => 1, 'text' => 'collect underpants'},
                {'id' => 2, 'text' => '?'},
                {'id' => 3, 'text' => 'profit'}]
    actual = JSON.parse(last_response.body)
    assert_equal expected, actual
  end

  def test_post_ideas
    post '/ideas', :value => 'build spaceship'
    assert_equal 201, last_response.status
    assert_equal %({"id":1,"text":"build spaceship"}), last_response.body

    idea = Idea.all.first
    assert_equal 1, idea.id
    assert_equal 'build spaceship', idea.text
  end

  def test_put_idea
    idea = Idea.create('spawn zombies')

    put "/ideas/#{idea.id}", :value => 'spawn atomic zombies'
    assert_equal 200, last_response.status
    assert_equal %({"id":#{idea.id},"text":"spawn atomic zombies"}), last_response.body

    idea = Idea.get(idea.id)
    assert_equal 'spawn atomic zombies', idea.text
  end

  def test_delete_idea
    idea = Idea.create('create black hole')

    delete "/ideas/#{idea.id}"
    assert_equal 200, last_response.status

    assert_nil Idea.get(idea.id)
  end
end
