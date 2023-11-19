module RubyExpressMethods
    include RubyExpressResponse
    private
    def log(msg)
      puts("\n")
      puts(msg)
      puts("\n")
    end
    def ChkPattern(pattern)
      if pattern.class === "String"
        pattern=pattern.strip
        len = pattern.length;
        if len===0
          pattern = ".*"
        else
          pattern = pattern.gsub('*','.*')
        end
        pattern = Regexp.new("^"+pattern+"$")
      else
        print "Unexpected!!\n"
        pattern =/^.*/
      end
      return pattern
    end
    def ParseReq(req)
      req=req.strip().split(/\r\n([\w\W]+)/)
      req_stat= req[0].split("\s");
  
      header = req[1];
      path = req_stat[1].split(/\?([\w\W]+)/);
      path[0]=URI.decode_www_form_component(path[0])
      query = URI.decode_www_form_component(path[1]||"")
  
      obj = {
        method:req_stat[0].upcase,
        url:URI.decode_www_form_component(req_stat[1]),
        path:path[0],
        search:query,
        query:{},
        http:req_stat[2],
        rawHeaders: header,
        rawBody: "",
        headers:{}
      }
  
      header = header.split(/\r\n|\n/)
      header.each{|val|
        val = val.split(":")
        obj[:headers][val[0].strip().downcase]=val[1].strip
        val=0
      }
  
      query=query.split("&")
      query.each{|val|
        val = val.split("=")
        obj[:query][val[0].strip]=val[1]
        val=0
      }
  
      # free memory
      req_stat = req = header = query = path=0
      return obj
    end
    def MatchClient(request, client, n, argv)
      req_method_obj = @RPaths[request[:method].downcase]
      if(req_method_obj.length<1)
        return
      end
  
      for i in n..req_method_obj.length-1
        val = req_method_obj[i]
        is_match = !(!request[:path].match(val[:pattern]))
        if(is_match)
          if argv
            argv[2].call(i+1)
            val[:callback].call(argv[0],argv[1])
          else
            Response.new(request, client, val[:callback], i+1, ->(n, argv){
              MatchClient(request, client, n, argv)
            });
          end
          break
        end
      end
    end
    def Client(client)
      if client.eof
        client.close()
        return log("client.eof")
      end
  
      request=""
      while (line = client.gets&.chomp)
        break if line.empty?
        request+= line+"\r\n"
      end
      if !request
        client.close()
        return log("empty request")
      end
        request = ParseReq(request)
        MatchClient(request, client, 0, false)
    end
  end