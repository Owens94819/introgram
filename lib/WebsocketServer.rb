class WebSocketServer
  def initialize(req, res, global)
      @req=req
      @res=res
      @event=Event.new()

  end

  def on(name, cb)
    @event.on(name, cb)
    return self
  end

  def send(msg)
    send_websocket_frame(1, msg)
    return self
  end
  def close()
    _close("user-action")
  end
  def start
    process_client(@req.socket)
    return self
  end
  private
  def process_client(client)
      if @req.headers['upgrade'] == 'websocket'
          accept_websocket_connection(client)
      else
          @res.setStatus("404")
          @res.end("Not Found")
      end
  end

  def accept_websocket_connection(client)
    key = @req.headers['sec-websocket-key']
    accept_key = Base64.strict_encode64(OpenSSL::Digest::SHA1.digest(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'))

    response = "HTTP/1.1 101 Switching Protocols\r\n" \
               "Upgrade: websocket\r\n" \
               "Connection: Upgrade\r\n" \
               "Sec-WebSocket-Accept: #{accept_key}"
  
    @res.setRawHeaders(response)
    handle_websocket(client)
  end

  def handle_websocket(client)
    @event.emit('connect', self)
    loop do
      puts "socket"
      opcode = client.getbyte
      if(!opcode)
          _close("no opcode")
          break;
      end
      # 136 close
      # 130 blob/buffer
      if(opcode === 136)
          _close("closed: #{opcode||"null"}")
          break;
      end

      byte=client.getbyte
      payload_length = byte & 0b01111111

      # puts [opcode,byte,payload_length]

      case payload_length
      when 126
        payload_length = client.read(2).unpack('n')[0]
      when 127
        payload_length = client.read(8).unpack('Q>')[0]
      end

      mask = client.read(4).unpack('C*')
      data = client.read(payload_length).unpack('C*')

      decoded_data = data.each_with_index.map { |byte, i| byte ^ mask[i % 4] }.pack('C*')
      
      # puts "Received message: #{decoded_data}"
      @event.emit("message", decoded_data)
      data=mask=decoded_data=0
      # decoded_data=Base64.encode(decoded_data)
      # Example: Echo back the message
      # send_websocket_frame( 1, "decoded_data-#{decoded_data}")
    end
  # rescue EOFError, Errno::ECONNRESET, Errno::ECONNABORTED
  #   _close("err");
  # rescue EOFError, Errno::ECONNABORTED
  #     puts 'WebSocket connection aborted'
  #     @res.end("")
  end

  def send_websocket_frame( opcode, data)
    frame = [0x80 | opcode, data.bytesize, data].flatten.pack('CCA*')
    @res.write(frame)
  end
  def _close(msg)
     @event.emit("close", msg)
     @event.removeAll()
     msg=0
     @res.end("")
  end
end