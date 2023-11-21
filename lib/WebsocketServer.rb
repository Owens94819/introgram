require("./lib/WebSocket.rb")

class WebSocketServer
  def initialize(req, res, global)
      @req=req
      @res=res
      @id=Date
      @client=@req.socket
      @event=Event.new()
      accept_websocket_connection()
      WebSocket::push(self)
  end

  def on(name, cb)
    @event.on(name, cb)
    return self
  end

  def send(msg)
    send_websocket_frame(1, msg)
    return self
  end
  def broadCast(msg)
    thread = Thread.new do
      WebSocket::SOCKETS.each do |socket|
        if(socket!=self)
          socket.send(msg)
        end
      end
      thread.kill()
    end
    return self
  end
  def close()
    _close("user-action")
  end
  def id 
    return @id
  end
  def start
    handle_websocket()
    return self
  end
  
  private

  def accept_websocket_connection()
    key = @req.headers['sec-websocket-key']
    accept_key = Base64.strict_encode64(OpenSSL::Digest::SHA1.digest(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'))

    response = "HTTP/1.1 101 Switching Protocols\r\n" \
               "Upgrade: websocket\r\n" \
               "Connection: Upgrade\r\n" \
               "Sec-WebSocket-Accept: #{accept_key}"
  
    @res.setRawHeaders(response)
  end

  def handle_websocket()
    @event.emit('connect', self)
    loop do
      opcode = @client.getbyte
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

      byte=@client.getbyte
      payload_length = byte & 0b01111111

      case payload_length
      when 126
        payload_length = @client.read(2).unpack('n')[0]
      when 127
        payload_length = @client.read(8).unpack('Q>')[0]
      end

      mask = @client.read(4).unpack('C*')
      data = @client.read(payload_length).unpack('C*')

      decoded_data = data.each_with_index.map { |byte, i| byte ^ mask[i % 4] }.pack('C*')
      
      @event.emit("message", decoded_data)
      data=mask=decoded_data=nil
    end
  end

  def send_websocket_frame( opcode, data)
    frame = [0x80 | opcode, data.bytesize, data].flatten.pack('CCA*')
    @res.write(frame)
  end

  def _close(msg)
     @event.emit("close", msg)
     @event.removeAll()
     msg=nil
     @res.end("")
  end
end