require 'socket'
require 'json'

client = UNIXSocket.open("tmp/sockets/web_socekts.sock")

message = {
  type: "event",
  event: {
    type: "cards.import.finished",
    user_id: 1
  }
  
}

client.print JSON.generate(message)
client.close
