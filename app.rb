require 'faye/websocket'
require 'socket'
require 'json'

require './lib/logger'


module Faye
  class WebSocket
    attr_accessor :user_id
  end
end

class App
  attr_reader :env, :web_clients, :events

  def initialize
    @web_clients = []
    @events = []
    listen_for_unix_socket
  end

  def call env
    @env = env

    if socket_request? env
      socket = spawn_socket
      web_clients << socket
      
      socket.rack_response
    else
      [400, {"Content-Type" => "text/html"}, ["This service only used for websockets"]]
    end

  end

  private

  def listen_for_unix_socket
    input_api_socket = "/tmp/websockets_unix.sock"

    if File.exist? input_api_socket
      File.delete input_api_socket
    end
    
    server = UNIXServer.new input_api_socket

    Thread.abort_on_exception = true
    Thread.start do
      loop {
        client = server.accept
        message = client.read
        json_message = JSON.parse(message)

        Logger.info "Unix socket connected"

        if json_message["type"] == "event"
          incoming_event_from_unix json_message["event"]
        end

        client.close
      }
    end
  end

  def incoming_event_from_unix event
    socket = web_clients.find {|socket| socket.user_id == event["user_id"]}
    event["created_at"] = Time.now

    if socket
      send_event_to_browser event, socket
    else
      spawn_event event
    end
  end

  def send_event_to_browser event, socket
    message = {
      type: "event",
      event: event
    }

    Logger.success "Send event to browser"
    Logger.info message

    socket.send JSON.generate(message)

    events.delete event
  end

  def spawn_event event
    events << event
    Logger.log "Incoming event from unix", :cyan
    Logger.info event

    # TODO: remove event after a certain time
  end
  
  def socket_request? env
    Faye::WebSocket.websocket? env
  end

  def spawn_socket
    socket = Faye::WebSocket.new env

    socket.on :open do
      socket.send '{"message":"Welcome in Type and Learn Websocket Service"}'

      Logger.info "Browser connected"
    end

    socket.on :message do |event|
      Logger.log "Message recived from browser", :magenta
      Logger.info event.data
      
      message = JSON.parse event.data

      # Expect something similar: {"type":"subscribe", "event":{"type": "cards.import.finished", "user_id": 1}}
      if message["type"] == "subscribe" && message["event"]["type"] == "cards.import.finished"
        socket.user_id = message["event"]["user_id"]

        event = events.find {|event| event["user_id"] == message["event"]["user_id"]}
        if event
          send_event_to_browser event, socket
        end
      end
    end

    socket.on :close do
      Logger.info "Close websocket"
      web_clients.delete socket
    end

    socket
  end
end