var _WebSocket=window.WebSocket;

(function (WebSocket) {
    window.WebSocket=WebSocket
})(function(path) {
    var client=new _WebSocket(path)
    console.log(client);
    var self = this;
    var pending_msg =[]
    this.send=function (msg) {
        if(client.readyState === client.OPEN){
            msg=JSON.stringify(msg)
            client.send(msg)
        }else if(pending_msg){
            pending_msg.push(msg)
        }
    }
    
    this.close=function (code, reason) {
        client.close(code, reason)
    }

    this.on=function(name, foo) {
        client.addEventListener(name, function(ev) {
            foo(ev.data)
        })
    }

    client.onopen=function () {
        for (var i = 0; i < pending_msg.length; i++) {
            self.send(pending_msg[i])
        }
        pending_msg=null
    }
})