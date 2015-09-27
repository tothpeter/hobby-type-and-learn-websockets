require 'socket'
client = UNIXSocket.open("tmp/sockets/web_socekts.sock")
client.puts "1"

client.close
# sleep 9
# client.puts "2"
# client.puts "3"
# client.puts "4"