class WebSocket
    def initialize()
        @sockets={}
        @index=0
    end
    def push(socket)
        @sockets[@index]=socket
        return @index
    end
    def pop(index)
        @sockets[@index]=0
    end
end