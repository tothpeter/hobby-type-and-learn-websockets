ENV['RACK_ENV'] = 'test'

require 'puma'
require 'rspec/em'

require './app'

class App
  def log *args
  end
end


WebSocketSteps = RSpec::EM.async_steps do
  def start_server &callback
    app = App.new

    events = Puma::Events.new(StringIO.new, StringIO.new)
    binder = Puma::Binder.new(events)
    binder.parse(["tcp://0.0.0.0:#{port}"], app)
    
    @server = Puma::Server.new(app, events)
    @server.binder = binder
    @server.run

    EM.add_timer(0.1, &callback)
  end

  def stop_server &callback
    @server.stop(true)
    EM.next_tick(&callback)
  end
  
  
  def open_browser_socket message, &callback
    @websocket = Faye::WebSocket::Client.new("ws://localhost:#{port}/", [], :proxy => {:origin => @proxy_url})

    @websocket.on :open do
      @websocket.send JSON.generate message
    end

    EM.add_timer(0.1, &callback)
  end

  def listen_for_messages_from_server &callback
    @websocket.on :message do |message|
      @message = message.data
    end

    EM.add_timer(0.1, &callback)
  end

  def send_unix_socket_message message, &callback
    client = UNIXSocket.open("/tmp/websocekts_puma.sock")
    client.print JSON.generate(message)
    client.close

    EM.add_timer(0.1, &callback)
  end

  def check_response_from_server lambda, &callback
    lambda.call @message
    callback.call
  end
end


describe App do
  include WebSocketSteps

  let(:port) { 4180 }

  before  { start_server }
  after  { stop_server }

  let(:message_from_browser) {
    {
      type:"subscribe",
        event: {
          type: "cards.import.finished", 
          user_id: 1
        }
    }
  }

  let(:message_from_delayed_job) {
    {
      type: "event",
      event: {
        type: "cards.import.finished",
        user_id: 1
      }
    }
  }

  describe "cards.import.finished event" do
    context "when browser connects first before unix socket" do
      it "sends the event back to the browser" do

        open_browser_socket message_from_browser
        send_unix_socket_message message_from_delayed_job

        listen_for_messages_from_server
        
        check_response_from_server ->(message) do
          json_message = JSON.parse message
          event = json_message["event"]
          
          expect(json_message["type"]).to eq "event"
          
          expect(event["type"]).to eq message_from_delayed_job[:event][:type]
          expect(event["user_id"]).to eq message_from_delayed_job[:event][:user_id]
        end
        
      end
    end

    context "when unix socket connects first before browser" do
      it "sends the event back to the browser" do

        send_unix_socket_message message_from_delayed_job
        open_browser_socket message_from_browser

        listen_for_messages_from_server
        
        check_response_from_server ->(message) do
          json_message = JSON.parse message
          event = json_message["event"]
          
          expect(json_message["type"]).to eq "event"
          
          expect(event["type"]).to eq message_from_delayed_job[:event][:type]
          expect(event["user_id"]).to eq message_from_delayed_job[:event][:user_id]
        end
        
      end
    end
  end

end