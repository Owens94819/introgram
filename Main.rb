

require "base64"
require "openssl"

require "./Lib/GlobalMethods.rb"
require "./Lib/DotENV.rb"
require "./Lib/InstantThread.rb"
require "./RubyExpress/RubyExpress.rb"
require "./WebSocket/WebSocketServer.rb"
require "./WebSocket/WebsocketHandler.rb"

Dot_env.new()

RubyExpress.new()
.middleware(RubyExpress.useBody())
# .middleware(RubyExpress.useXJSX("./UI"))
.middleware(RubyExpress.useERB("./UI/pages"))
.get('/', ->(req, res){
    res.render("index.html.erb",{tmp:"index",path:req.path})
})
.post('/post', ->(req, res){
    res.render("post.html.erb",{path:req.path})
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
