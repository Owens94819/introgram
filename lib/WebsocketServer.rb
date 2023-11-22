require("json")
require("./Lib/WebSocketList.rb")

class WebSocketServer < Event
  def initialize(req, res, global)
    super()
      @req=req
      @res=res
      @df_type="message"
      @client=@req.socket
      # @event=self
      @id= WebSocketList::push(self)
      @id=Base64.encode64(OpenSSL::Digest::SHA1.digest("#{@id}" + ENV["HASH"]))
      accept_websocket_connection()
  end

  def send(type, msg, default: false)
    msg=JSON.unparse({data:msg,type:"#{type}".strip()||@df_type,default: default})
    send_websocket_frame(1, msg)
    return self
  end
  def broadCast(type, msg, default: false)
    # log("total socket: #{WebSocketList::SOCKETS.size}")
    thread = Thread.new do
      for (id,socket) in WebSocketList::SOCKETS
        if(socket!=self)
          socket.send(type, msg, default: default)
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
    accept_key = Base64.strict_encode64(OpenSSL::Digest::SHA1.digest(key + ENV["HASH"]))
    @res.setStatus(101)
    @res.setHeader("Upgrade","Websocket")
    @res.setHeader("Connection","Upgrade")
    @res.setHeader("Sec-WebSocket-Accept",accept_key)
    @res.sendHeaders()
  end

  def handle_websocket()
    send("connect",{id:@id},default:true)
    self.emit('connect', self)
    loop do
      opcode = @client.getbyte
      if(!opcode)
          _close("no opcode")
          break;
      end
      # 136 close
      # 130 buffer
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

      begin
        decoded_data=JSON.parse(decoded_data)
      rescue
        json={}
        json["data"]=decoded_data
        json["type"]=@df_type
        # json["from"]=
        # json["to"]=
        decoded_data=json
      end
      self.emit(":#{decoded_data["type"]}", decoded_data["data"])
      data=mask=decoded_data=nil
    end

    log("a socket ended (this in unhandle and you should refer to code) filename: WebSocketServer.rb, line: (around 103), def_name: handle_websocket, pos: (at end of method)")
  
  end

  def send_websocket_frame( opcode, data)
    frame = [0x80 | opcode, data.bytesize, data].flatten.pack('CCA*')
    @res.write(frame)
  end

  def _close(msg)
    self.emit("close", msg)
    self.removeAll()
    msg=nil
    @res.end("")
  end
end