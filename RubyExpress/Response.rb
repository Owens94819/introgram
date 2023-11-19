
module RubyExpressResponse
    private
    class Response
        include RubyExpressRequest
        def initialize(req, client, callback, n, foo)
            @req=req;
            @client=client;
            @callback=callback;
            @arr_pos = n;
            @foo=foo;
            @_req=Request.new(@req,@client);
            @headerSent=false;
            @responseSent=false;
            @status = 200;
            @http = "HTTP/1.1";
            @headers = "";
    
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
end