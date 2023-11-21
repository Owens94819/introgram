
require "./lib/GlobalMethods.rb"
require "./RubyExpress/RubyExpress.rb"
require "./lib/DotENV.rb"
require "./lib/WebSocketServer.rb"
require "./lib/InstantThread.rb"
require "base64"
require "openssl"

Dot_env.new()

if(ENV["TEST_MODE"])
    require("./lib/TestScript")
end
RubyExpress.new()
.get('/home', ->(req, res){
    res.setHeader('content-type', 'text/html')
    res.sendFile('./.bin/page.html')
})
.use('/soc',->(req,res){
    socket = req.socket
    class Soc
        def initialize(req,socket)
            @req=req
            @sent=false
            @socket=socket
            puts "soc"
        end
        def gets
            puts "gets"
            if(@sent) 
                return ""
            end
            @sent=true
            return @req.rawRequest
        end
        def getbyte
            puts "getbyte"
            return @socket.getbyte
        end
        def read(index)
            puts "read"
            return @socket.read(index)
        end
        def write(bytes)
            puts "write"
            return @socket.write(bytes)
        end
        def close()
            puts "close"
            return @socket.close
        end
    end

    # puts Soc.new(req).gets
    # puts "\n\n-\n"
    # puts socket.gets
    # return res.end("")
    driver = WebSocket::Driver.server(io:Soc.new(req, socket))
    driver.on :connect do |event|
      # Handle the WebSocket connection
      puts 'WebSocket connected'
    end
  
    driver.on :message do |event|
      # Handle WebSocket messages
      message = event.data
      puts "Received message: #{message}"
  
      # Send a response
      driver.text('Server received: ' + message)
    end
  
    driver.on :close do |event|
      # Handle WebSocket connection close
      puts 'WebSocket closed'
      socket.close
    end
  
    driver.start
    # Thread.new do
    #     WebSocketServer.new(req, res)
    # end
})
.use('/web', ->(req, res){
    if(req.headers["upgrade"] != "websocket")
        res.send("websocket conn exp")
        return
    end
    WebSocketServer.new(req, res, true)
    .on("connect",->(ws){
        puts "websock2"
        ws.on("message",->(msg){
            puts "data: #{msg}"
        })
        .on('close', ->(msg){
            puts "@closing... #{msg}"
        })
    })
    .start()
})
.use('', ->(req, res){
    res.setHeader('4004', 'text/html')
    res.send('404:'+req.path)
})
.on("connect", ->(server){
    puts "served @ #{server.port()}"
})
.on("close",->(server){
    puts "closing"
})
.listen()