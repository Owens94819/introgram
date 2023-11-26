module RubyExpressRequest
    private
    class Request
        def initialize(req,res, client)
            @req=req;
            @socket=client;
            prev_timeout=@timeout=4;
            @global={}
            @read_length=0;
            foo=->(time){
              sleep(time)
              if(res.responseSent||@timeout<=0)
                @thread.kill()
                return
              end
              _timeout = @timeout-prev_timeout;
              if(_timeout>0)
                prev_timeout=@timeout
                foo.call(_timeout);
              else
                log("Session timeout(#{@timeout}): #{path}")
                if(res.headerSent)
                  res.end("")
                else
                  res.setStatus(504).end("")
                end
                @thread.kill()
              end
            }

            @thread=Thread.new do
              foo.call(@timeout)
            end
        end
        def socket
          return @socket
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
        def param
          return @req[:param]
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
        def rawRequest
          return @req[:rawRequest]
        end
        def rawBody(index)
          return @req[:rawBody].call(index)
          # c_length=(headers["content-length"]||"0").to_i;
          # if(@read_length>=c_length)
          #   return ""
          # end
          # if(index>c_length&&@read_length===0)
          #   index=c_length
          # end
          # @read_length+=index
          # begin
          #   return @socket.readpartial(index)
          # rescue(EOFError)
          #   return ""
          # end
        end
        def timeout()
          return @timeout
        end
        def body()
          return @req[:body]
        end
        def http
          return @req[:http]
        end
        def timeout=(sec)
          @timeout = Integer(sec)
        end
        def body=(body)
          if("#{body.class}"==="Hash")
            @req[:body]=body
          end
        end
      end
end
