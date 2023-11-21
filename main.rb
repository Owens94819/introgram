
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
.use('/__socket__', ->(req, res){
    if(req.headers["upgrade"] != "websocket")
        res.next()
        return
    end
    WebSocketServer.new(req, res, true)
    .on("connect",->(ws){
        puts "websock2"
        ws.on("message",->(msg){
            puts "data: #{msg}"
            ws.broadCast(msg)
        })
        .on('close', ->(msg){
            puts "@closing... #{msg}"
        })
    })
    .start()
})
.use('', ->(req, res){
    res.setHeader('content-type', 'text/html')
    res.send('404:'+req.path)
})
.on("connect", ->(server){
    puts "served @ #{server.port()}"
})
.on("close",->(server){
    puts "closing"
})
.listen()