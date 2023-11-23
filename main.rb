


require "./Lib/GlobalMethods.rb"
require "./RubyExpress/RubyExpress.rb"
require "./Lib/DotENV.rb"
require "./Lib/WebSocketServer.rb"
require "./Lib/WebsocketHandler.rb"
require "./Lib/InstantThread.rb"
require "base64"
require "openssl"

Dot_env.new()

RubyExpress.new()
.get('/:test1/:test2', ->(req, res){
    puts req.param
    res.setHeader('content-type', 'text/html')
    res.sendFile('./UI/page.html')
})
.use('/__socket__', WebsocketHandler::CallBack)
.use('/assets/*', RubyExpress.useDir("./UI"))
.use('/*', ->(req, res){
    res.setHeader('content-type', 'text/html')
    # res.status
    res.send('404:'+req.path)
})
.on("connect", ->(server){
    puts "served @ #{server.port()}"
    if(ENV["TEST_MODE"])
        require("./Lib/TestScript")
    end
})
.on("close",->(server){
    puts "closing"
})
.listen()