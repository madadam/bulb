# gems
require 'json'
require 'sinatra'
require 'sass'

require 'idea'

configure do
  enable :raise_errors
  disable :show_exceptions
end

helpers do
  def vote(points)
    idea = Idea.get(params[:id])
    idea.vote!(points)

    content_type :json
    {:votes => idea.votes}.to_json
  end
end

get '/' do
  erb :main
end

get '/ideas' do
  ideas = Idea.all

  content_type :json
  ideas.to_json
end

post '/ideas' do
  idea = Idea.create(params[:value])

  content_type :json
  status 201
  idea.to_json
end

put '/ideas/:id' do
  idea = Idea.update(params[:id], params[:value])

  content_type :json
  idea.to_json
end

delete '/ideas/:id' do
  Idea.delete(params[:id])

  status 200
end

post '/ideas/:id/up' do
  vote(1)
end

post '/ideas/:id/down' do
  vote(-1)
end

get '/styles.css' do
  content_type :css
  scss :styles
end
