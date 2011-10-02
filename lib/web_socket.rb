require 'em-websocket'
require 'json'

unless defined?(WebSocket)
  WebSocket = Object.new
  WebSocket.instance_eval do
    @sockets = []

    def run!(options)
      options[:host] ||= '0.0.0.0'

      EventMachine::WebSocket.start(options) do |ws|
        ws.onopen  { @sockets << ws }
        ws.onclose { @sockets.delete(ws) }
      end
    end

    def send(action, payload)
      message = {:action => action, :payload => payload}.to_json
      @sockets.each { |socket| socket.send(message) }
    end
  end
end
