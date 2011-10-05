class App < Sinatra::Base
  set :root, File.expand_path('../../', __FILE__)

  enable  :logging
  enable  :raise_errors
  disable :show_exceptions

  use Rack::Auth::Basic do |email, password|
    if user = User.authenticate(email, password)
      Thread.current[:user] = user
      true
    else
      false
    end
  end

  get '/' do
    erb :main
  end

  get '/ideas' do
    ideas = Idea.all.map { |idea| present_idea(idea) }

    content_type :json
    ideas.to_json
  end

  post '/ideas/next-id' do
    content_type :json
    {:id => Idea.next_id!}.to_json
  end

  put '/ideas/:id' do
    idea = Idea.get_or_create(params[:id])
    idea.text = params[:value]

    WebSocket.send 'ideas/put', present_idea(idea)

    status 200
  end

  delete '/ideas/:id' do
    Idea.delete(params[:id])
    WebSocket.send 'ideas/delete', :id => params[:id]

    status 200
  end

  post '/ideas/:id/toggle-upvote' do
    idea = Idea.get(params[:id])
    idea.toggle_upvote!(current_user)

    WebSocket.send 'ideas/vote', present_idea(idea)

    status 200
  end

  post '/ideas/:id/toggle-downvote' do
    idea = Idea.get(params[:id])
    idea.toggle_downvote!(current_user)

    WebSocket.send 'ideas/vote', present_idea(idea)

    status 200
  end

  get '/styles.css' do
    content_type :css
    scss :styles
  end

  helpers do
    def current_user
      Thread.current[:user]
    end
  end

  private

  def present_idea(idea)
    { :id         => idea.id,
      :text       => idea.text,
      :timestamp  => idea.timestamp,
      :votes      => idea.votes,
      :my_vote    => idea.vote_by(current_user) }
  end
end
