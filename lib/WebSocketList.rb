module WebSocketList
    SOCKETS=[]
    ID=[0]

    def self.push(socket)
      socket.on("connect", ->(socket){
        SOCKETS.push(socket)
        socket_id=SOCKETS.length-1
        socket.on("close", ->(msg){
            SOCKETS.popIndex(socket_id)
        })
      })
      ID[0]+=1
      return ID[0]
    end
    def self.pop(index)
        SOCKETS.popIndex(index)
    end
end
