require 'socket'
require 'json'

client = UNIXSocket.open("/tmp/websockets_unix.sock")

message = {
  type: "event",
  event: {
    type: "cards.import.finished",
    user_id: 2
  }
  
}

client.print JSON.generate(message)
client.close
