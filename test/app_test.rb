require 'helper'
require 'rack/test'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    $redis.select 1
    $redis.flushdb
  end

  test 'GET /' do
    get '/'
    assert_equal 200, last_response.status
  end

  test 'GET /ideas' do
    Idea.create('collect underpants')
    Idea.create('?')
    Idea.create('profit')

    get '/ideas'
    assert_equal 200, last_response.status

    ideas = JSON.parse(last_response.body)
    assert_equal 3, ideas.size

    assert_equal 1, ideas[0]['id']
    assert_equal 'collect underpants', ideas[0]['text']

    assert_equal 2, ideas[1]['id']
    assert_equal '?', ideas[1]['text']

    assert_equal 3, ideas[2]['id']
    assert_equal 'profit', ideas[2]['text']
  end

  test 'POST /ideas' do
    post '/ideas', :value => 'build spaceship'
    assert_equal 201, last_response.status

    hash = JSON.parse(last_response.body)
    assert_equal 1, hash['id']
    assert_equal 'build spaceship', hash['text']

    idea = Idea.all.first
    assert_equal 1, idea.id
    assert_equal 'build spaceship', idea.text
  end

  test 'PUT /ideas/:id' do
    idea = Idea.create('spawn zombies')

    put "/ideas/#{idea.id}", :value => 'spawn atomic zombies'
    assert_equal 200, last_response.status

    hash = JSON.parse(last_response.body)
    assert_equal idea.id, hash['id']
    assert_equal 'spawn atomic zombies', hash['text']

    idea = Idea.get(idea.id)
    assert_equal 'spawn atomic zombies', idea.text
  end

  test 'DELETE /ideas/:id' do
    idea = Idea.create('create black hole')

    delete "/ideas/#{idea.id}"
    assert_equal 200, last_response.status

    assert_nil Idea.get(idea.id)
  end

  test 'POST /ideas/:id/up' do
    idea = Idea.create('foo')

    post "/ideas/#{idea.id}/up"
    assert_equal 200, last_response.status
    assert_equal 'application/json', last_response.content_type
    assert_equal 1, Idea.get(idea.id).votes
  end

  test 'POST /ideas/:id/down' do
    idea = Idea.create('foo')
    idea.vote!(3)

    post "/ideas/#{idea.id}/down"
    assert_equal 200, last_response.status
    assert_equal 'application/json', last_response.content_type
    assert_equal 2, Idea.get(idea.id).votes
  end
end
