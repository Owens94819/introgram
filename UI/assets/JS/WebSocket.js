var _WebSocket=window.WebSocket;

(function (WebSocket) {
    window.WebSocket=WebSocket
})(function(path) {
    var df_type="message"
    var ready=false
    var id;
    var client=new _WebSocket(path)
    var custom_event=document.createEvent("CustomEvent")

    console.log(client);
    var self = this;
    var pending_msg =[]
    this.send=function (type,msg) {
        if(ready){
            try {
                type=type.toString().trim()||df_type
                msg=JSON.stringify({type:type,data:msg, to: ""})
            } catch (error) {
                msg ={data:msg,type:df_type, from:id}
            }
            client.send(msg)
        }else if(pending_msg){
            pending_msg.push([type,msg])
        }
    }
    
    this.close=function (code, reason) {
        client.close(code, reason)
    }

    this.on=function(name, foo) {
        client.addEventListener(name, function(ev) {
            data =ev.detail
            foo(data)
        })
    }

    this.on("connect", function (data) {
        ready=true
        id=data.id
        for (var i = 0; i < pending_msg.length; i++) {
            var arg=pending_msg[i]
            self.send(arg[0],arg[1])
        }
        pending_msg=null
    })

    client.addEventListener("message", function(ev) {
        data = ev.data
        try {
            data=JSON.parse(data)
        } catch (error) {
            data={data:data,type:df_type}
        }
        data.type=(data.default?"":":")+data.type
        custom_event.initCustomEvent(data.type, false, false, data.data);
        client.dispatchEvent(custom_event);
    })
})