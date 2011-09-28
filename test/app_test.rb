require 'helper'
require 'rack/test'
require 'app'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App
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
    Idea.create(:text => 'collect underpants')
    Idea.create(:text => '?')
    Idea.create(:text => 'profit')

    get '/ideas'
    assert_equal 200, last_response.status

    ideas = JSON.parse(last_response.body)
    assert_equal 3, ideas.size

    idea = ideas.find { |i| i['id'] == 1 }
    assert_equal 'collect underpants', idea['text']

    idea = ideas.find { |i| i['id'] == 2 }
    assert_equal '?', idea['text']

    idea = ideas.find { |i| i['id'] == 3 }
    assert_equal 'profit', idea['text']
  end

  test 'PUT /ideas/:id with non-existing id' do
    id = 42

    put "/ideas/#{id}", :value => 'spawn vampires'
    assert_equal 200, last_response.status

    idea = Idea.get(id)
    assert_equal 'spawn vampires', idea.text
  end

  test 'PUT /ideas/:id with existing id' do
    idea = Idea.create(:text => 'spawn zombies')

    put "/ideas/#{idea.id}", :value => 'spawn atomic zombies'
    assert_equal 200, last_response.status

    idea = Idea.get(idea.id)
    assert_equal 'spawn atomic zombies', idea.text
  end

  test 'DELETE /ideas/:id' do
    idea = Idea.create(:text => 'create black hole')

    delete "/ideas/#{idea.id}"
    assert_equal 200, last_response.status

    assert_nil Idea.get(idea.id)
  end

  test 'POST /ideas/:id/up' do
    idea = Idea.create(:text => 'foo')

    post "/ideas/#{idea.id}/up"
    assert_equal 200, last_response.status
    assert_equal 1, Idea.get(idea.id).votes
  end

  test 'POST /ideas/:id/down' do
    idea = Idea.create(:text => 'foo')
    idea.vote!(3)

    post "/ideas/#{idea.id}/down"
    assert_equal 200, last_response.status
    assert_equal 2, Idea.get(idea.id).votes
  end
end
