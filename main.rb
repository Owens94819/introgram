


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
.use('', RubyExpress.useBody())
.get('/', ->(req, res){
    res.setHeader('content-type', 'text/html').sendFile('./UI/page.html')
})
.post('/post', ->(req, res){
    # log(req.rawBody(233))
    # log("--")
    res.end("hello")
})
.use('/__socket__', WebsocketHandler::CallBack)
.use('/assets/*', RubyExpress.useDir("./UI"))
.use('', ->(req, res){
    res.sendStatus(404)
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