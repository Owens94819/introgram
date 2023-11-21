module WebSocket
    SOCKETS=[]
    def self.push(socket)
      socket.on("connect", ->(socket){
        SOCKETS.push(socket)
        socket_id=SOCKETS.length-1
        socket.on("close", ->(msg){
            SOCKETS.popIndex(socket_id)
        })
      })
        return SOCKETS.length
    end
    def self.pop(index)
        SOCKETS.popIndex(index)
    end
end