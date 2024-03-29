require 'helper'
require 'rack/test'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App
  end

  def setup
    setup_redis
    @alice = User.create(:email => 'alice@example.com', :password => 'foobar')
  end

  test 'successful authentication' do
    authorize 'alice@example.com', 'foobar'
    get '/'
    assert_equal 200, last_response.status
  end

  test 'authentication without credentials' do
    get '/'
    assert_equal 401, last_response.status
  end

  test 'authentication with invalid email' do
    authorize 'bob@example.com', 'bazqux'
    get '/'
    assert_equal 401, last_response.status
  end

  test 'authentication with invalid password' do
    authorize 'alice@example.com', 'bazqux'
    get '/'
    assert_equal 401, last_response.status
  end

  test 'GET /' do
    authenticate_as @alice
    get '/'
    assert_equal 200, last_response.status
  end

  test 'GET /ideas' do
    Idea.create(:text => 'collect underpants')
    Idea.create(:text => '?')
    Idea.create(:text => 'profit')

    authenticate_as @alice
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

  test 'GET /ideas response contains votes' do
    idea = Idea.create(:text => 'foo')
    user1 = @alice
    user2 = User.create
    user3 = User.create

    idea.upvote!(user1)
    idea.upvote!(user2)
    idea.downvote!(user3)

    authenticate_as user1
    get '/ideas'

    idea = JSON.parse(last_response.body).first

    assert_equal 1, idea['votes']
    assert_equal 'upvote', idea['my_vote']
  end

  test 'PUT /ideas/:id with non-existing id' do
    id = 42

    authenticate_as @alice
    put "/ideas/#{id}", :value => 'spawn vampires'
    assert_equal 200, last_response.status

    idea = Idea.get(id)
    assert_equal 'spawn vampires', idea.text
  end

  test 'PUT /ideas/:id with existing id' do
    idea = Idea.create(:text => 'spawn zombies')

    authenticate_as @alice
    put "/ideas/#{idea.id}", :value => 'spawn atomic zombies'
    assert_equal 200, last_response.status

    idea = Idea.get(idea.id)
    assert_equal 'spawn atomic zombies', idea.text
  end

  test 'DELETE /ideas/:id' do
    idea = Idea.create(:text => 'create black hole')

    authenticate_as @alice
    delete "/ideas/#{idea.id}"

    assert_equal 200, last_response.status
    assert_nil Idea.get(idea.id)
  end

  test 'POST /ideas/:id/toggle-upvote of not upvoted idea upvotes' do
    idea = Idea.create(:text => 'foo')

    authenticate_as @alice
    post "/ideas/#{idea.id}/toggle-upvote"

    assert_equal 200, last_response.status
    assert Idea.get(idea.id).upvoted_by?(@alice)
  end

  test 'POST /ideas/:id/toggle-upvote of upvoted idea removes the upvote' do
    idea = Idea.create(:text => 'foo')
    idea.upvote!(@alice)

    authenticate_as @alice
    post "/ideas/#{idea.id}/toggle-upvote"

    assert_equal 200, last_response.status
    assert !Idea.get(idea.id).upvoted_by?(@alice)
  end

  test 'POST /ideas/:id/toggle-upvote of downvoted idea upvotes' do
    idea = Idea.create(:text => 'foo')
    idea.downvote!(@alice)

    authenticate_as @alice
    post "/ideas/#{idea.id}/toggle-upvote"

    assert_equal 200, last_response.status
    assert Idea.get(idea.id).upvoted_by?(@alice)
  end

  test 'POST /ideas/:id/toggle-downvote of not downvoted idea downvotes' do
    idea = Idea.create(:text => 'foo')

    authenticate_as @alice
    post "/ideas/#{idea.id}/toggle-downvote"

    assert_equal 200, last_response.status
    assert idea.downvoted_by?(@alice)
  end

  test 'POST /ideas/:id/toggle-downvote of downvoted idea removes the downvote' do
    idea = Idea.create(:text => 'foo')
    idea.downvote!(@alice)

    authenticate_as @alice
    post "/ideas/#{idea.id}/toggle-downvote"

    assert_equal 200, last_response.status
    assert !idea.downvoted_by?(@alice)
  end

  test 'POST /ideas/:id/toggle-downvote of upvoted idea downvotes' do
    idea = Idea.create(:text => 'foo')
    idea.upvote!(@alice)

    authenticate_as @alice
    post "/ideas/#{idea.id}/toggle-downvote"

    assert_equal 200, last_response.status
    assert Idea.get(idea.id).downvoted_by?(@alice)
  end

  test 'POST /ideas/next-id' do
    authenticate_as @alice

    post '/ideas/next-id'
    post '/ideas/next-id'
    post '/ideas/next-id'

    assert_equal 200, last_response.status
    assert_equal 3, JSON.parse(last_response.body)['id']
  end

  private

  def authenticate_as(user)
    authorize user.email, user.password
  end
end
