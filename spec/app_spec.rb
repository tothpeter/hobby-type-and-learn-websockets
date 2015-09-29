ENV['RACK_ENV'] = 'test'

require 'puma'
require './app'

require 'socket'
require 'json'


class App
  def log *args
  end
end

describe App do
  after  { stop }

  it "does something" do
    port = 4180
    app = App.new

    events = Puma::Events.new(StringIO.new, StringIO.new)
    binder = Puma::Binder.new(events)
    binder.parse(["tcp://0.0.0.0:#{port}"], app)
    @server = Puma::Server.new(app, events)
    @server.binder = binder
    @server.run




    client = UNIXSocket.open("/tmp/websocekts_puma.sock")

    message = {
      type: "event",
      event: {
        type: "cards.import.finished",
        user_id: 2
      }
      
    }

    client.print JSON.generate(message)
    client.close

    # sleep 1


    done = false

    resume = lambda do |open|
      unless done
        done = true
        @open = open
        # callback.call
        asd
      end
    end

    @ws = Faye::WebSocket::Client.new("ws://localhost:#{port}/", ["foo", "echo"], :proxy => {:origin => @proxy_url})



    @ws.on(:open) { |e| resume.call(true); p "open shit ----------------" }
    @ws.onclose = lambda { "close ----------------" }

    sleep 2


  end

  def stop
    p "stoooop ------"
    case @server
    when Puma::Server then @server.stop(true)
    else @server.stop
    end
  end
end






      










# ENV['RACK_ENV'] = 'test'

# require './app'
# require './echo_server'

# # require 'rspec'
# # require 'rack/test'

# describe 'The HelloWorld App' do
#   # include Rack::Test::Methods
#   include WebSocketSteps

#   def app
#     App.new
#   end

#   # it "says hello" do
#   #   get '/'
#   #   # expect(last_response).to be_ok
#   #   expect(last_response.body).to eq('This service only used for websockets')
#   # end

#   it "does something" do
#     open_socket "ws://localhost:9292/", ["foo", "echo"]
#   end


#   def open_socket(url, protocols, &callback)
#     done = false

#     resume = lambda do |open|
#       unless done
#         done = true
#         @open = open
#         callback.call
#       end
#     end

#     @ws = Faye::WebSocket::Client.new(url, protocols, :proxy => {:origin => @proxy_url})

#     @ws.on(:open) { p "open --------------------" }
#     @ws.onclose = lambda { "close ----------------" }

#     p @ws

#     # @ws.on(:open) { |e| resume.call(true) }
#     # @ws.onclose = lambda { |e| resume.call(false) }
#   end
# end














# WebSocketSteps = RSpec::EM.async_steps do
#   def server(port, backend, secure, &callback)
#     @echo_server = EchoServer.new
#     @echo_server.listen(port, backend, secure)
#     EM.add_timer(0.1, &callback)
#   end

#   def stop(&callback)
#     @echo_server.stop
#     EM.next_tick(&callback)
#   end

#   def proxy(port, &callback)
#     @proxy_server = ProxyServer.new
#     @proxy_server.listen(port)
#     EM.add_timer(0.1, &callback)
#   end

#   def stop_proxy(&callback)
#     @proxy_server.stop
#     EM.next_tick(&callback)
#   end

#   def open_socket(url, protocols, &callback)
#     done = false

#     resume = lambda do |open|
#       unless done
#         done = true
#         @open = open
#         callback.call
#       end
#     end

#     @ws = Faye::WebSocket::Client.new(url, protocols, :proxy => {:origin => @proxy_url})

#     @ws.on(:open) { |e| resume.call(true); p "open shit ----------------" }
#     @ws.onclose = lambda { |e| resume.call(false) }
#   end

#   def open_socket_and_close_it_fast(url, protocols, &callback)
#     @ws = Faye::WebSocket::Client.new(url, protocols)

#     @ws.on(:open) { |e| @open = @ever_opened = true }
#     @ws.onclose = lambda { |e| @open = false }

#     @ws.close

#     callback.call
#   end

#   def close_socket(&callback)
#     @ws.onclose = lambda do |e|
#       @open = false
#       callback.call
#     end
#     @ws.close
#   end

#   def check_open(&callback)
#     expect(@open).to be(true)
#     callback.call
#   end

#   def check_closed(&callback)
#     expect(@open).to be(false)
#     callback.call
#   end

#   def check_never_opened(&callback)
#     expect(!!@ever_opened).to be(false)
#     callback.call
#   end

#   def check_protocol(protocol, &callback)
#     expect(@ws.protocol).to eq(protocol)
#     callback.call
#   end

#   def listen_for_message(&callback)
#     @ws.add_event_listener('message', lambda { |e| @message = e.data })
#     start = Time.now
#     timer = EM.add_periodic_timer 0.1 do
#       if @message or Time.now.to_i - start.to_i > 5
#         EM.cancel_timer(timer)
#         callback.call
#       end
#     end
#   end

#   def send_message(message, &callback)
#     EM.add_timer(0.5) { @ws.send(message) }
#     EM.next_tick(&callback)
#   end

#   def check_response(message, &callback)
#     expect(@message).to eq(message)
#     callback.call
#   end

#   def check_no_response(&callback)
#     expect(@message).to eq(nil)
#     callback.call
#   end

#   def wait(seconds, &callback)
#     EM.add_timer(seconds, &callback)
#   end
# end