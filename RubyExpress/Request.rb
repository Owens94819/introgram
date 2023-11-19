module RubyExpressRequest
    private
    class Request
        def initialize(req, client)
            @req=req;
            @socket=client;
            @global={}
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
end