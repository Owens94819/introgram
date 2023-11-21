require './RubyExpress/Request.rb'
module RubyExpressResponse
    private
    class Response
        include RubyExpressRequest
        def initialize(req, client, callback, n, foo, useThread)
            @req=req;
            @client=client;
            @callback=callback;
            @arr_pos = n;
            @foo=foo;
            @_req=Request.new(@req,@client);
            @headerSent=false;
            @responseSent=false;
            @status = 200;
            @status_msg = "";
            @http = "HTTP/1.1";
            @headers = "";
            @self = self;
            @thread
            if(useThread)
              @thread = Thread.new do
                @callback.call(@_req, self)
              rescue Errno::EPIPE
                # @self.end("")
                puts "Errno::EPIPE (thread)"
              end
            else
              @callback.call(@_req,self)
            end
        rescue Errno::EPIPE
          # @self.end("")
          puts "Errno::EPIPE"
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
        def sendFile(path)
          if File.exist?(path)
              File.open(path, 'r').each_line do |bytes|
                self.write(bytes+"\r\n")
              end
              self.end("")
          else
            self.end("")
          end
        end
        def write(bytes)
          if(@responseSent)
            return log("response sent already (write)")
          end
          !@headerSent && sendHeaders;
          @client.write(bytes)
        end
        def end(bytes)
          if(@responseSent)
            return log("response sent already (end)")
          end
          !@headerSent && sendHeaders;
          !@responseSent && (@responseSent=true);
          bytes && @client.write(bytes);
          @client.close()
          @thread&&@thread.kill()
        end
        def setRawHeaders(headers)
          if(@headerSent)
            return log("headers sent already")
          end
          @headerSent=true
          @client.write(headers)
          @client.write("\r\n\r\n")
        end
        def killThread
          @thread&&@thread.kill()
        end
        private
        def sendHeaders
          if(@headerSent)
            return log("headers sent already")
          end
          @headerSent=true
          @client.write("#{@http} #{@status} #{@status_msg}\r\n")
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