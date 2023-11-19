require 'socket'

module RubyExpressMethods
  private
  class Request
    def initialize(req)
        @req=req;
        @global={}
    end
    def globals
      return @global
    end
    def headers
      return @req[:headers]
    end
    def query
      return @req[:query]
    end
    def method
      return @req[:method]
    end
    def path
      return @req[:path]
    end
    def url
      return @req[:url]
    end
    def search
      return @req[:search]
    end
    def rawHeaders
      return @req[:rawHeaders]
    end
    def rawBody
      return @req[:rawBody]
    end
    def http
      return @req[:http]
    end
  end
  class Response
    def initialize(req, client, callback, n, foo)
        @foo=foo;
        @callback=callback;
        @req=req;
        @_req=Request.new(@req);
        @headerSent=false;
        @responseSent=false;
        @client=client;
        @status = 200;
        @http = "HTTP/1.1";
        @headers = "";
        @arr_pos = n;

        @callback.call(@_req,self)
    end
    def setStatus(code)
      if(@headerSent)
        return log("headers sent already")
      end
      @status = Integer(code)
      if(code>600||code<200)
        return log("incorrect status code")
      end
    end
    def setHeader(key, val)
      if(@headerSent)
        return log("headers sent already")
      end
      key = key.gsub(/\\r\\n|\\n/,'').gsub(/:/,'%3A')

      _key=key.gsub(/(\W)/,"\\\\\\1")+":"
      reg=Regexp.new("((?:^|\\r\\n|\\n)#{_key}).*(\\r\\n|\\n|$)","i")
      val = val.gsub(/\\r\\n|\\n/,'')

      if(@headers.match(reg))
        @headers=@headers.sub(reg,"\\1 #{val} \\2")
      else
        @headers+="#{key}: #{val}\r\n"
      end
    end
    def next()
      if(@responseSent)
        return log("response sent already, invalid \"next\"")
      end
      @foo.call(@arr_pos,[@_req,self, ->(n){
        @arr_pos=n
      }]);
    end
    def send(bytes)
      self.end(bytes)
    end
    def write(bytes)
      if(@responseSent)
        return log("response sent already")
      end
      !@headerSent && sendHeaders;
      @client.write(bytes)
    end
    def end(bytes)
      if(@responseSent)
        return log("response sent already")
      end
      !@headerSent && sendHeaders;
      !@responseSent && (@responseSent=true);
      bytes && @client.write(bytes);
      @client.close()
    end
    private
    def sendHeaders
      if(@headerSent)
        return log("headers sent already")
      end
      @headerSent=true
      @client.write("#{@http} #{@status}\r\n")
      @client.write(@headers)
      @client.write("\r\n")
    end
    def log(msg)
      puts("\n")
      puts(msg)
      puts("\n")
    end
  end

  def log(msg)
    puts("\n")
    puts(msg)
    puts("\n")
  end
  def ChkPattern(pattern)
    if pattern.class === "String"
      pattern=pattern.strip
      len = pattern.length;
      if len===0
        pattern = ".*"
      else
        pattern = pattern.gsub('*','.*')
      end
      pattern = Regexp.new("^"+pattern+"$")
    else
      print "Unexpected!!\n"
      pattern =/^.*/
    end
    return pattern
  end
  def ParseReq(req)
    req=req.strip().split(/\n([\w\W]+)/)
    req_stat= req[0].split("\s");
    # @do decode url (req_stat)

    header = req[1];
    path = req_stat[1].split(/\?([\w\W]+)/);
    query = path[1]||""
    obj = {
      method:req_stat[0].upcase,
      url:req_stat[1],
      path:path[0],
      search:query,
      query:{},
      http:req_stat[2],
      rawHeaders: header,
      rawBody: "",
      headers:{}
    }

    header = header.split(/\r\n|\n/)
    header.each{|val|
      val = val.split(":")
      obj[:headers][val[0].strip().downcase]=val[1].strip
      val=0
    }

    query=query.split("&")
    query.each{|val|
      val = val.split("=")
      obj[:query][val[0].strip]=val[1]
      val=0
    }

    # free memory
    req_stat = req = header = query = path=0
    return obj
  end
  def MatchClient(request, client, n, argv)
    req_method_obj = @RPaths[request[:method].downcase]
    if(req_method_obj.length<1)
      return
    end

    for i in n..req_method_obj.length-1
      val = req_method_obj[i]
      is_match = !(!request[:path].match(val[:pattern]))
      if(is_match)
        if argv
          argv[2].call(i+1)
          val[:callback].call(argv[0],argv[1])
        else
          Response.new(request, client, val[:callback], i+1, ->(n, argv){
            MatchClient(request, client, n, argv)
          });
        end
        break
      end
    end
  end

  def Client(client)
    # client.readpartial(@MAX_READ)
    request = client.readpartial(@MAX_READ)
    # for i in 0..300
    #   str = client.gets;
    #   if(str)
    #     request+=str;
    #   else
    #     break;
    #   end
    # end
    # puts request
      request = ParseReq(request)
      MatchClient(request, client, 0, false)
  end
end


class RubyExpress
  include RubyExpressMethods
  
  def initialize(port:5000)
    @MAX_READ = 10024;
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
    Thread.new(->(client){
      Client(client)
    }) { |foo|
      server = TCPServer.open(@port)
      loop{
        client=server.accept
        foo.call(client)
      }
  }.join
  end
end

