require 'socket'
require 'uri'
require "./Lib/Event.rb"
require "./Lib/MimeType.rb"
require './RubyExpress/RubyExpressMethods.rb'
module RubyExpressFoo
  MIME_TYPE=MimeType.new()
  def useDir(path)
    # exist=File.exist?(path)
    return ->(req,res){
      file = path+req.path
      exist=File.exist?(file)&&!file.match?("\\.\\.")
      if(!exist)
        res.next()
        return
      end
      res.setHeader("content-type", MIME_TYPE.lookUp(file))
      File.open(file, 'r').each_line do |bytes|
        res.write(bytes+"\r\n")
      end
      res.end("")
    }
  end

end


class RubyExpress
  extend RubyExpressFoo
  include RubyExpressMethods
  def initialize(port:ENV['PORT'])
    @MAX_READ = 1024;
    @port = port;
    @RPaths = {};
    @SERVED = false;
    @POSTS=@RPaths["post"]=[]
    @GETS=@RPaths["get"]=[]
    @USE=@RPaths["use"]=[]
    @event=Event.new()
  end
  def use(pattern, callback, useThread:true)
    pattern= ChkPattern(pattern);
    obj = {
              pattern:pattern,
              callback:callback, 
              type: "use",
              useThread:useThread
          }
    @RPaths.each{|key,val| 
      val.push(obj)
    }
    return self
  end
  def get(pattern, callback, useThread:true)
    pattern= ChkPattern(pattern);
    @GETS.push({
            pattern:pattern,
            callback:callback,
            type: "get",
            useThread:useThread
          })
    return self
  end
  def post(pattern, callback, useThread:true)
    pattern= ChkPattern(pattern);
    @POSTS.push({
            pattern:pattern,
            callback:callback,
            type: "get",
            useThread:useThread
          })
    return self
  end
  def port
    return @port
  end
  def on(name, cb)
    @event.on(name,cb)
    return self
  end
  def listen
    if(@SERVED)
      return 0
    end
    @SERVED = true
    
      server = TCPServer.open(@port)
      @event.emit("connect",self)

      loop{
        client=server.accept
        Client(client)
      }
      return self
  rescue Interrupt
    @event.emit("close",self)
  end
end

