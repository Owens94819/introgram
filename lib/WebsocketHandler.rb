module WebsocketHandler
    CallBack =->(req, res){
        if(req.headers["upgrade"] != "websocket")
            res.next()
            return
        end
        WebSocketServer.new(req, res, true)
        .on("connect",->(ws){
            ws.on("message",->(msg){
                puts ws.id
                puts "data: #{msg}"
                ws.broadCast(msg)
            })
            .on('close', ->(msg){
                puts "@closing... #{msg}"
            })
        })
        .start()
    }
end