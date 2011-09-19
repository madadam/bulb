require 'bundler'
Bundler.require

get '/' do
  erb :main
end

get '/styles.css' do
  content_type 'text/css'
  scss :styles
end
