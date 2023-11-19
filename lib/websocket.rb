require 'socket'
require 'websocket/driver'

server = TCPServer.new('localhost', 3000)

puts 'WebSocket server listening on port 3000...'

loop do
  socket = server.accept
  Thread.new(socket) { |client_socket|
    driver = WebSocket::Driver.server(client_socket)

    driver.on :connect { |event|
      # Handle the WebSocket connection
      puts 'WebSocket connected'
    }

    driver.on :message { |event|
      # Handle WebSocket messages
      message = event.data
      puts "Received message: #{message}"

      # Send a response
      driver.text('Server received: ' + message)
    }

    driver.on :close { |event|
      # Handle WebSocket connection close
      puts 'WebSocket closed'
      client_socket.close
    }

    driver.start
  }
end
