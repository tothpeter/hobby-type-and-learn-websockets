#\ -s puma -E production

require 'faye/websocket'
require 'socket'
require 'json'


module Faye
  class WebSocket
    attr_accessor :user_id
  end
end

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
          web_clients.find {|socket| socket.user_id == json_message["event"]["user_id"]}.send message
        end

        client.close
      }
    end
  end

  def call env

    @env = env

    if socket_request? env
      socket = spawn_socket
      web_clients << socket
      
      socket.rack_response
    else
      [400, {"Content-Type" => "text/html"}, ["This service only usef for web sockets"]]
    end

  end

  private
  
  def socket_request? env
    Faye::WebSocket.websocket? env
  end

  def spawn_socket
    socket = Faye::WebSocket.new env

    socket.on :open do
      socket.send "Welcome in Raaaaaack"
      p "Open ---------------------------------"
    end

    socket.on :message do |event|
      message = JSON.parse event.data

      # Expect something similar: {"type":"subscribe", "event":{"type": "cards.import.finished", "user_id": 1}}
      if message["type"] == "subscribe" && message["event"]["type"] == "cards.import.finished"
        socket.user_id = message["event"]["user_id"]
      end
    end

    socket.on :close do
      web_clients.delete socket
    end

    socket
  end
end

run App.new