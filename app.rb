# gems
require 'json'
require 'sinatra'
require 'sass'

require 'idea'

configure do
  enable :raise_errors
  disable :show_exceptions
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
end

get '/styles.css' do
  content_type :css
  scss :styles
end
