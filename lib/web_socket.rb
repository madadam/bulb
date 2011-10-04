require 'em-websocket'
require 'json'

module WebSocket
  SOCKETS = Set.new

  def self.run!(options = {})
    options = { :host => '0.0.0.0',
                :port => CONFIG[:web_socket_port] }.merge(options)

    EventMachine::WebSocket.start(options) do |ws|
      ws.onopen  { SOCKETS << ws }
      ws.onclose { SOCKETS.delete(ws) }
    end
  end

  def self.send(action, payload)
    message = {:action => action, :payload => payload}.to_json
    SOCKETS.each { |socket| socket.send(message) }
  end
end
