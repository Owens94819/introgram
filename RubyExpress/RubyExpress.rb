require 'socket'
require 'uri'
require "./Dummy_thread.rb"
require './RubyExpress/Request.rb'
require './RubyExpress/Response.rb'
require './RubyExpress/RubyExpressMethods.rb'
DUMMY_THREAD1=Dummy_thread.new(1);



class RubyExpress
  include RubyExpressMethods
  def initialize(port:5000)
    @MAX_READ = 1024;
    @port = port;
    @RPaths = {};
    @SERVED = false;
    @POSTS=@RPaths["post"]=[]
    @GETS=@RPaths["get"]=[]
    @USE=@RPaths["use"]=[]

    # @server = TCPServer.open(@port)
  end
  def use(pattern, callback)
    pattern= ChkPattern(pattern);
    obj = {
              pattern:pattern,
              callback:callback, 
              type: "use"
          }
    @RPaths.each{|key,val| 
      val.push(obj)
    }
  end
  def get(pattern, callback)
    pattern= ChkPattern(pattern);
    @GETS.push({
            pattern:pattern,
            callback:callback,
            type: "get"
          })
  end
  def post(pattern, callback)
    pattern= ChkPattern(pattern);
    @POSTS.push({
            pattern:pattern,
            callback:callback,
            type: "get"
          })
  end
  def listen
    if(@SERVED)
      return 0
    end
    @SERVED = true
    
    DUMMY_THREAD1.push(->{
      server = TCPServer.open(@port)
      loop{
        client=server.accept
        Client(client)
      }
    })
    gets
  end
end

