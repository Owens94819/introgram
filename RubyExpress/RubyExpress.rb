require 'socket'
require 'uri'
require "./Lib/Event.rb"
require "./Lib/MimeTypes.rb"
require './RubyExpress/RubyExpressMethods.rb'
module RubyExpressFoo
  MIME_TYPES=MimeTypes.new()
  def useDir(path)
    # exist=File.exist?(path)
    return ->(req,res){
      file = File.join(path, req.path)
      begin
        exist=File.exist?(file)&&!File.directory?(file)&&!file.match?("\\.\\.")
        if(!exist)
          throw "no File"
        end
        res.setHeader("content-type", MIME_TYPES.lookUp(file))
        File.open(file, 'r').each_line do |bytes|
          res.write(bytes+"\r\n")
        end
      res.end("")
      rescue
        res.next();
      end
    }
  end
end


class RubyExpress < Event
  extend RubyExpressFoo
  include RubyExpressMethods
  def initialize(port:ENV['PORT'])
    super()
    @MAX_READ = 1024;
    @port = port;
    @RPaths = {};
    @SERVED = false;
    @POSTS=@RPaths["post"]=[]
    @GETS=@RPaths["get"]=[]
    @USE=@RPaths["use"]=[]
    # @event=self
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
  def listen
    if(@SERVED)
      return 0
    end
    @SERVED = true
    
      server = TCPServer.open(@port)
      self.emit("connect",self)

      loop{
        client=server.accept
        Client(client)
      }
      return self
  rescue Interrupt
    self.emit("close",self)
  end
end

