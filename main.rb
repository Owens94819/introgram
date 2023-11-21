
require "./Lib/GlobalMethods.rb"
require "./RubyExpress/RubyExpress.rb"
require "./Lib/DotENV.rb"
require "./Lib/WebSocketServer.rb"
require "./Lib/WebsocketHandler.rb"
require "./Lib/InstantThread.rb"
require "base64"
require "openssl"

Dot_env.new()

if(ENV["TEST_MODE"])
    require("./Lib/TestScript")
end
RubyExpress.new()
.get('/home', ->(req, res){
    res.setHeader('content-type', 'text/html')
    res.sendFile('./UI/page.html')
})
.use('/__socket__', WebsocketHandler::CallBack)
.use('/assets/*', RubyExpress.useDir("./UI"))
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