require './RubyExpress/Request.rb'
module RubyExpressResponse
   private
   require("./Lib/StatusCodes.rb")
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
            @status_msg = StatusCodes[:"#{@status}"];
            @http = "HTTP/1.1";
            @headers = "";
            @closed = false;
            @self = self;
            @thread
            if(useThread)
              @thread = Thread.new do
                @callback.call(@_req, self)
              rescue Errno::EPIPE
                puts "Errno::EPIPE (thread)"
                terminate()
              end
            else
              @callback.call(@_req,self)
            end
        rescue Errno::EPIPE
          puts "Error (cb)"
          terminate()
        end
        def setStatus(code)
          if(@headerSent)
            return log("headers sent already")
          end
          @status = Integer(code)
          status_msg = StatusCodes[:"#{@status}"];
          if(!status_msg)
            return log("incorrect status code")
          end
          @status_msg=status_msg
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
        def send(bytes)
          self.end(bytes)
        end
        def sendFile(path)
          if File.exist?(path)
              File.open(path, 'r') do |file|
                file.each_line do |bytes|
                  self.write(bytes+"\r\n")
                end
              end
              self.end("")
          else
            self.end("")
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
        def write(bytes)
          if(@responseSent)
            return log("response sent already (write)\ndata: #{bytes}\n---")
          end
          !@headerSent && sendHeaders;
          @client.write(bytes)
        rescue Errno::EPIPE
          puts "Errno::EPIPE (write)"
          terminate()
        end
        def end(bytes)
          if(@responseSent)
            return log("response sent already (end) \ndata: #{bytes}\n---")
          end
          !@headerSent && sendHeaders;
          !@responseSent && (@responseSent=true);
          bytes && @client.write(bytes);
          terminate()
        rescue Errno::EPIPE
          puts "Errno::EPIPE (end)"
          terminate()
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
        def sendHeaders
          if(@headerSent)
            return log("headers sent already")
          end
          @headerSent=true
          @client.write("#{@http} #{@status} #{@status_msg}\r\n")
          @client.write(@headers)
          @client.write("\r\n")
        rescue Errno::EPIPE
          puts "Errno::EPIPE (sendHeaders)"
          terminate()
        end
        private 
        def terminate
          @client.close()
          killThread();
        end
      end
end