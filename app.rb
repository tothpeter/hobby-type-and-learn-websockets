require 'faye/websocket'
require 'socket'
require 'json'

require './lib/logger'


module Faye
  class WebSocket
    attr_accessor :user_id, :thread
  end
end

class App
  attr_accessor :wait_before_remove_event, :wait_before_close_browser_socket
  attr_reader :env, :web_clients, :events

  Thread.abort_on_exception = true

  def initialize
    @web_clients = []
    @events = []
    @wait_before_remove_event = 20
    @wait_before_close_browser_socket = 20
    listen_for_unix_socket
  end

  def call env
    @env = env

    if socket_request? env
      socket = spawn_socket_from_browser
      web_clients << socket

      socket.rack_response
    else
      [400, {"Content-Type" => "text/html"}, ["This service only used for websockets"]]
    end

  end

  private

  def listen_for_unix_socket
    input_api_socket_path = "/tmp/websockets_unix.sock"

    if File.exist? input_api_socket_path
      File.delete input_api_socket_path
    end

    server = UNIXServer.new input_api_socket_path

    Thread.start do
      loop {
        client = server.accept
        message = client.read
        json_message = JSON.parse(message)

        Logger.info "Unix socket connected"

        if json_message["type"] == "event"
          handle_event_from_unix json_message["event"]
        end

        client.close
      }
    end
  end

  def handle_event_from_unix event
    socket = web_clients.find {|socket| socket.user_id == event["user_id"]}
    event["created_at"] = Time.now

    if socket
      send_event_to_browser event, socket
    else
      spawn_event_from_unix event
    end
  end

  def send_event_to_browser event, socket
    Thread.kill event[:thread] if event[:thread]
    Thread.kill socket.thread if socket.thread
    event.delete :thread

    message = {
      type: "event",
      event: event
    }

    Logger.success "Send event to browser"
    Logger.info message

    socket.send JSON.generate(message)

    events.delete event
  end

  def spawn_event_from_unix event
    thread = Thread.start do
      sleep wait_before_remove_event
      Logger.error "Browser has not subscribed for the unix event after #{wait_before_remove_event}s remove it"
      events.delete event
    end

    Logger.log "Incoming event from unix", :cyan
    Logger.info event

    event[:thread] = thread
    events << event
  end

  def socket_request? env
    Faye::WebSocket.websocket? env
  end

  def spawn_socket_from_browser
    socket = Faye::WebSocket.new env

    socket.on :open do
      socket.send '{"message":"Welcome in Type and Learn Websocket Service"}'
      Logger.info "Browser connected"

      socket.thread = Thread.start do
        sleep wait_before_close_browser_socket
        Logger.error "Browser has not sent any message after #{wait_before_close_browser_socket}s, force close connection"
        socket.close
      end
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
