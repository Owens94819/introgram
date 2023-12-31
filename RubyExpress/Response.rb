require("./Lib/StatusCodes.rb")
require './RubyExpress/Request.rb'
require 'json'
module RubyExpressResponse
   private
    class Response
        include RubyExpressRequest
        def initialize(req, client, callback, n, foo,handle_bar, useThread)
            @req=req;
            @handle_bar=handle_bar;
            @client=client;
            @callback=callback;
            @arr_pos = n;
            @foo=foo;
            @_req=Request.new(@req,self,@client);
            @headerSent=false;
            @responseSent=false;
            @status = 200;
            @status_msg = STATUS_CODES[:"#{@status}"];
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
            log("headers sent already")
            return self
          end
          @status = Integer(code)
          status_msg = STATUS_CODES[:"#{@status}"];
          if(!status_msg)
            log("incorrect status code")
            return self
          end
          @status_msg=status_msg
          return self
        end
        def setHeader(key, val)
          if(@headerSent)
            log("headers sent already")
            return self
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
          return self
        end
        def pipe(io_stream)
          if("#{io_stream.class}"==="File")
            io_stream.each do |char|
              write(char)
            end
            io_stream.close()
          else
            throw "pipe error (pipe)"
          end

          return self
        end
        def render(path, data)
          if(@handle_bar["handler"])
            @handle_bar["handler"].call(path,data, @_req, self)
          end
          return self
        end
        def send(bytes)
          self.end(bytes)
          return self
        end
        def sendStatus(code)
          setStatus(code).end(STATUS_CODES[:"#{@status}"])
          return self
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
          return self
        end
        def next()
          if(@responseSent)
            return log("response sent already, invalid \"next\"")
          end
          @foo.call(@arr_pos,[@_req,self, ->(n){
            @arr_pos=n
          }]);
          return self
        end
        def writeJSON(json)
          json=JSON.unparse(json)
          write(json)
          return self
        end
        def write(bytes)
          if(@responseSent)
            return log("response sent already (write)\ndata: #{bytes}\n---")
          end
          !@headerSent && sendHeaders;
          @client.write(bytes)
          return self
        rescue Errno::EPIPE
          puts "Errno::EPIPE (write)"
          terminate()
          return self
        end
        def end(bytes)
          if(@responseSent)
            log("response sent already (end), data: #{bytes}\n---")
            return self;
          end
          !@headerSent && sendHeaders;
          !@responseSent && (@responseSent=true);
          bytes && @client.write(bytes);
          terminate()
          return self;
        rescue Errno::EPIPE
          puts "Errno::EPIPE (end)"
          terminate()
          return self
        end
        def __setRawHeaders(headers)
          if(@headerSent)
            log("headers sent already")
            return self
          end
          @headerSent=true
          @client.write(headers)
          @client.write("\r\n\r\n")
          return self
        end
        def killThread
          @thread&&@thread.kill()
          return self
        end
        def sendHeaders
          if(@headerSent)
            log("headers sent already")
            return self
          end
          @headerSent=true
          @client.write("#{@http} #{@status} #{@status_msg}\r\n")
          @client.write(@headers)
          @client.write("\r\n")
          return self
        rescue Errno::EPIPE
          puts "Errno::EPIPE (sendHeaders)"
          terminate()
          return self
        end
        def responseSent
                    return @responseSent
        end
        def headerSent
          return @headerSent
        end
        private
        def terminate
          @client.close()
          killThread();
          return self
        end
      end
end
