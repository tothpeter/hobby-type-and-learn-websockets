#\ -s puma -E production

require 'faye/websocket'
require 'socket'
require 'json'

class App
  attr_reader :env, :web_clients

  def initialize
    @web_clients = []
    listen_for_unix_socket
  end

  def listen_for_unix_socket
    File.delete "tmp/sockets/web_socekts.sock"
    server = UNIXServer.new("tmp/sockets/web_socekts.sock")

    Thread.abort_on_exception = true
    Thread.start do
      loop {
        client = server.accept
        message = client.read
        json_message = JSON.parse(message)

        if json_message["type"] == "event"
          web_clients.first.send message
        end

        client.close
      }
    end
  end

  def call env

    @env = env

    if socket_request? env
      # socket = spawn_socket
      socket = Faye::WebSocket.new env
      web_clients << socket

      socket.on :open do
        socket.send "Welcome in Raaaaaack"
        p "Open ---------------------------------"
      end

      socket.on :message do |event|
        p "Message From Browser ---------------------------------"
        p event.data
      end

      socket.on :close do
        # p "---------------------------------"
        # p "closed"
        # p "---------------------------------"
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