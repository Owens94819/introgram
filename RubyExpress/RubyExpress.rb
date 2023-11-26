require 'socket'
require 'uri'
require "./Lib/Event.rb"
require "./Lib/MimeTypes.rb"
require './RubyExpress/RubyExpressMethods.rb'
module RubyExpressFoo
  MIME_TYPES=MimeTypes.new()
  def self.parseQuery(query, obj:{})
    query=query.split("&")
      query.each{|val|
        val = val.split("=")
        obj[val[0].strip]=val[1]
        val=nil
      }
      return obj
  end
  def useDir(path)
    # exist=File.exist?(path)
    return ->(req,res){
      file = File.join(path, req.path)
      begin
        exist=File.exist?(file)&&!File.directory?(file)&&!file.match?("\\.\\.")
        if(!exist)
          throw "no File"
        end
        res.setHeader("content-type", MIME_TYPES.lookUp(file))
        File.open(file, 'r').each_line do |bytes|
          res.write(bytes+"\r\n")
        end
        res.end("")
      rescue UncaughtThrowError
        res.next();
      end
    }
  end
  def useBody()
    return ->(_self:,handle_bar:){
      return ->(req,client){
      read_length=0
      req[:rawBody]=rawBody=->(index){
        c_length=(req[:headers]["content-length"]||"0").to_i;
        if(read_length>=c_length)
          return ""
        end
        if(index>c_length&&read_length===0)
          index=c_length
        end
        read_length+=index
        begin
          return client.readpartial(index)
        rescue(EOFError)
          return ""
        end
      }

        if(req[:method]!= "POST")
          return
        end
        # socket=req.socket
        type=req[:headers]["content-type"]||""
        if(type === "application/x-www-form-urlencoded")
          data=RubyExpressFoo::parseQuery(rawBody.call(1024), obj:req[:body])
        elsif(type.match?(/^application\/(ld+)?json5?$/))
          data=req[:body]=JSON.parse(rawBody.call(1024))
        else
          # data={}
          # req.body(body: data)
        end
    }
  }
  end
  def useXJSX(path)
    return ->(_self:,handle_bar:){
          _self.get("/template/:name", ->(req, res){
            name=req.param["name"].split(",")
            res.setHeader("Content-Type","application/javascript")
            begin
              res.write(
                "if(window.XJSX){"\
                "(function(){var tmp;"\
                "var j;"
                )
              name.each do |val|

                if(val.strip! === "")
                                  next
                end
                _temp = File.join(handle_bar["view"],"pages")
                temp=""

                (File.exist?(temp=File.join(_temp,val+".xjsx"))||File.exist?(temp=File.join(_temp,val+".xjsx.html"))||File.exist?(temp=File.join(_temp,val))||temp=nil)
                  exist=temp&&!File.directory?(temp)&&!temp.match?("\\.\\.")
                  if(!exist)
                    next
                  end
                  val.gsub!("'","\\\\'")
                  res.write("\ntmp=document.createElement('template')")
                  .write("\nXJSX.customTemplates['#{val}']=tmp")
                  .write("\ntmp.innerHTML=`")
                  file = File.open(temp, 'r').each do |val|
                          val.gsub!("`","\\\\`")
                          res.write(val+"\r\n")
                  end
                  res.write(
                    "`;"
                  )
                  # res.write(
                  #   "`;\n"\
                  #   "j=tmp.content.querySelectorAll(\"meta,script,link,style\");"\
                  #   "for(var i=0; i<j.length;i++){"\
                  #   "j[i].remove()"\
                  #   "}"
                  #   )
              end
              res.end(
                "tmp=j=void 0;"\
                "})()}else{"\
                "console.warn('XJSX is needed')"\
                "}")
            rescue UncaughtThrowError
              res.end("")
            end
          })
          _self.get("/xjsx", ->(req, res){
            _modules=req.query["modules"]||"print"
            debugger=req.query["debugger"]
            _modules=_modules.split(",")
            res.setHeader("Content-Type","application/javascript")
            begin
              xjsx = File.join(handle_bar["view"],debugger&&"XJSX/xjsx.js"||"XJSX/xjsx-min.js")
              exist=File.exist?(xjsx)&&!File.directory?(xjsx);#&&!xjsx.match?("\\.\\.")
              if(!exist)
                    throw "!exist"
              end
              # res.write(
              #   "var meta = document.getElementById(\"XJSX-META\");"\
              #   "try{"\
              #   " meta = JSON.parse(meta.innerHTML);"\
              #   "for(var key in meta){"\
              #   "window[key]=meta[key]"\
              #   "}"\
              #   "meta=void 0;"\
              #   "}catch(err){console.log(err)}"\
              #   )
              res.pipe(File.open(xjsx, 'r'))
              res.write(";")
              _modules.each do |_module|
                _module=File.join(handle_bar["view"],"XJSX/modules",_module+".js")
                exist=File.exist?(_module)&&!File.directory?(_module)&&!_module.match?("\\.\\.")
                if(!exist)
                  next
                end
                res.pipe(File.open(_module, 'r'))
                res.write(";")
              end
              res.end("")
            rescue UncaughtThrowError
              res.end("")
            end
          })
          handle_bar["view"]=path
          handle_bar["handler"]=->(path, data, req, res){
            path = File.join(handle_bar["view"],"pages", path)
            begin
              exist=File.exist?(path)&&!File.directory?(path)#&&!file.match?("\\.\\.")
              if(!exist)
                throw "no File"
              end
              res.setHeader("Content-Type","text/html")
              res.write("<script>")
              data.each do |key,val|
                key="#{key}"
                val="#{val}"
                key.gsub!("\"","\\\\\"")
                val.gsub!("`","\\\\`")
                res.write("window[\"#{key}\"]=`#{val}`;")
              end
              res.write("</script>")
              # res.write(
              #   "<script type=\"application/json\" id=\"XJSX-META\">"\
              #   "#{JSON.unparse(data)}"\
              #   "</script>"\
              # )
              res.pipe(File.open(path, 'r')).end("")
            rescue UncaughtThrowError
              log("Error (render())")
            end
          }
          return false
    }
  end
end


class RubyExpress < Event
  extend RubyExpressFoo
  include RubyExpressMethods
  def initialize(port:ENV['PORT'])
    super()
    @MAX_READ = 1024;
    @port = port;
    @RPaths = {};
    @SERVED = false;
    @POSTS=@RPaths["post"] = [];
    @GETS=@RPaths["get"] = [];
    @_MIDDLEWARE_=@RPaths["_MIDDLEWARE_"] = [];
    @handle_bar={
      "view"=>"/",
      "handler"=> nil
    }
  end
  def setView(view)
        @handle_bar["view"]=view
  end
  def middleware(callback,useThread:true)
    @_MIDDLEWARE_.push({
            pattern:/^.*$/,
            callback:callback.call(_self:self,handle_bar:@handle_bar),
            type: "_MIDDLEWARE_",
            useThread:useThread
          })
    return self
  end
  def use(pattern, callback, useThread:true)
    pattern= ChkPattern(pattern);
    obj = {
              pattern:pattern,
              callback:callback,
              type: "use",
              useThread:useThread
          }
    @RPaths.each{|key,val|
      if(key!="_MIDDLEWARE_")
        val.push(obj)
      end
    }
    return self
  end
  def get(pattern, callback, useThread:true)
    pattern= ChkPattern(pattern);
    @GETS.push({
            pattern:pattern,
            callback:callback,
            type: "get",
            useThread:useThread
          })
    return self
  end
  def post(pattern, callback, useThread:true)
    pattern= ChkPattern(pattern);
    @POSTS.push({
            pattern:pattern,
            callback:callback,
            type: "get",
            useThread:useThread
          })
    return self
  end
  def port
    return @port
  end
  def listen
    if(@SERVED)
      return 0
    end
    @SERVED = true

      server = TCPServer.open(@port)
      self.emit("connect",self)

      loop{
        client=server.accept
        Client(client)
      }
      return self
  rescue Interrupt
    self.emit("close",self)
  end
end
