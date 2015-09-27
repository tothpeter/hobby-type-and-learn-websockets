#\ -s puma -E production


# class Rack::Lint::HijackWrapper
#   def to_int
#     @io.to_i
#   end
# end

# run -> env {[200, {"Content-Type" => "text/html"}, ["<h1>Hello World</h1>"]]}
# require 'bundler'
require 'faye/websocket'

class App
  def call env

    @env = env

    if socket_request? env
      # socket = spawn_socket
      socket = Faye::WebSocket.new env

      socket.on :open do
        socket.send "Raaaaaack"
        p "Open---------------------------------"
      end

      socket.on :message do |event|
        p "Message---------------------------------"
        p event.data
      end

      socket.on :close do
        p "---------------------------------"
        p "closed"
        p "---------------------------------"
      end

      socket.rack_response
    else
      [400, {"Content-Type" => "text/html"}, ["This service only usef for web sockets"]]
    end

  end

  private
  
  def socket_request? env
    Faye::WebSocket.websocket? env
  end
end

run App.new