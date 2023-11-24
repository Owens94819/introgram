module WebSocketList
    SOCKETS={}
    ID=[0]

    def self.push(socket)
      id=ID[0]+=1
      socket.on("connect", ->(socket){
        SOCKETS[id]=socket
        socket.on("close", ->(msg){
          SOCKETS.delete(id)
        })
      })
      return id
    end
    def self.pop(id)
        SOCKETS.delete(id)
    end
end
