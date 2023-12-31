module WebsocketHandler
    CallBack =->(req, res){
        if(req.headers["upgrade"] != "websocket")
            res.next()
            return
        end
        WebSocketServer.new(req, res, true)
        .on("connect",->(ws){
            # log("connected")
            ws.on(":message",->(msg){
                puts ws.id
                puts "data: #{msg}"
                ws.broadCast("message",msg)
            })
            .on('close', ->(msg){
                puts "@closing... #{msg}"
                res.end("")
            })
        })
        .start()
    }
end