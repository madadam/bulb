require 'json'
require 'sinatra'
require 'sass'

get '/' do
  erb :main
end

get '/ideas' do
  data = [
    {:id => 1, :text => 'Add persistence'},
    {:id => 2, :text => 'Fancier animations'},
    {:id => 3, :text => 'Keyboard shortcuts'}
  ]

  content_type :json
  data.to_json
end

post '/ideas' do
  content_type :json
  {:id => rand(10000), :text => params[:value].to_s}
end

put '/ideas/:id' do
  content_type :json
  {:id => params[:id], :text => params[:value].to_s}
end

delete '/ideas/:id' do

end

get '/styles.css' do
  content_type :css
  scss :styles
end
