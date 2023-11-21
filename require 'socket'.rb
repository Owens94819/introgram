require 'socket'
require 'base64'
require 'openssl'

class WebSocketServer
  def initialize
    @server = TCPServer.new('localhost', 3000)
    puts 'WebSocket server listening on http://localhost:3000'

    run_server
  end

  def run_server
    loop do
      client = @server.accept
      process_client(client)
    end
  end

  def process_client(client)
    headers = read_headers(client)

    if headers['Upgrade'] == 'websocket'
      accept_websocket_connection(client, headers)
    else
      respond_http(client)
      client.close
    end
  end

  def read_headers(client)
    headers = {}

    while (line = client.gets&.chomp)
      break if line.empty?
      key, value = line.split(': ', 2)
      headers[key] = value
    end

    headers
  end

  def accept_websocket_connection(client, headers)
    key = headers['Sec-WebSocket-Key']
    accept_key = Base64.strict_encode64(OpenSSL::Digest::SHA1.digest(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'))

    response = "HTTP/1.1 101 Switching Protocols\r\n" \
               "Upgrade: websocket\r\n" \
               "Connection: Upgrade\r\n" \
               "Sec-WebSocket-Accept: #{accept_key}\r\n\r\n"

    client.write(response)

    Thread.new do
      handle_websocket(client)
    end
  end

  def handle_websocket(client)
    loop do
      opcode = client.getbyte
      payload_length = client.getbyte & 0b01111111

      case payload_length
      when 126
        payload_length = client.read(2).unpack('n')[0]
      when 127
        payload_length = client.read(8).unpack('Q>')[0]
      end

      mask = client.read(4).unpack('C*')
      data = client.read(payload_length).unpack('C*')

      decoded_data = data.each_with_index.map { |byte, i| byte ^ mask[i % 4] }.pack('C*')
      
      puts "Received message: #{decoded_data}"

      # Example: Echo back the message
      send_websocket_frame(client, 1, decoded_data)
    end
  rescue EOFError, Errno::ECONNRESET
    puts 'WebSocket connection closed'
  end

  def send_websocket_frame(client, opcode, data)
    frame = [0x80 | opcode, data.bytesize, data].flatten.pack('CCA*')
    client.write(frame)
  end

  def respond_http(client)
    response = "HTTP/1.1 200 OK\r\n" \
               "Content-Type: text/plain\r\n" \
               "Connection: close\r\n\r\n" \
               "Hello, HTTP!\r\n"

    client.write(response)
  end
end

WebSocketServer.new
