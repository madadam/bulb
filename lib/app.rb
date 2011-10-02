class App < Sinatra::Base
  set :logging, true
  set :root,    File.expand_path('../../', __FILE__)

  enable  :raise_errors
  disable :show_exceptions

  get '/' do
    erb :main
  end

  get '/ideas' do
    ideas = Idea.all

    content_type :json
    ideas.to_json
  end

  post '/ideas/next-id' do
    content_type :json
    {:id => Idea.next_id}.to_json
  end

  put '/ideas/:id' do
    idea = Idea.get_or_create(params[:id])
    idea.text = params[:value]

    WebSocket.send 'ideas/put', idea

    status 200
  end

  delete '/ideas/:id' do
    Idea.delete(params[:id])
    WebSocket.send 'ideas/delete', :id => params[:id]

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

  private

  def vote(points)
    idea = Idea.get(params[:id])
    idea.vote!(points)

    WebSocket.send 'ideas/vote', :id => idea.id, :votes => idea.votes
    status 200
  end
end
