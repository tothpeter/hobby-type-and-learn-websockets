#\ -s puma -E production


# class Rack::Lint::HijackWrapper
#   def to_int
#     @io.to_i
#   end
# end

# run -> env {[200, {"Content-Type" => "text/html"}, ["<h1>Hello World</h1>"]]}
# require 'bundler'
require 'faye/websocket'
require 'socket'

class App
  attr_reader :env, :web_clients

  def initialize
    @web_clients = []
    listen_for_unix_socket
  end

  def listen_for_unix_socket
    # p "--------------"
    # serv = UNIXServer.new("tmp/sockets/web_socekts.sock")
    # s = serv.accept
    # p s.read
    # p "--------------"

    File.delete "tmp/sockets/web_socekts.sock"
    server = UNIXServer.new("tmp/sockets/web_socekts.sock")

    Thread.start do
      loop {                          # Servers run forever
        Thread.start(server.accept) do |client|
          p client.read
          web_clients.first.send "From threeeead"
          # client.puts(Time.now.ctime) # Send the time to the client
          # client.puts "Closing the connection. Bye!"
          client.close                # Disconnect from the client
        end
      }
    end
  end

  def call env

    p "---------------------------------123"

    @env = env

    if socket_request? env
      # socket = spawn_socket
      socket = Faye::WebSocket.new env
      web_clients << socket

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