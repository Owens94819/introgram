require './RubyExpress/Response.rb'
module RubyExpressMethods
    include RubyExpressResponse
    private
    def ChkPattern(pattern)
      params=[] #{:prop:[], val:""}
      if pattern.class === "String"
        pattern.strip!
        len = pattern.length;
        pattern.sub!(/^[\/]?/,"/")
        #  .sub!(/[\/]?$/,"/")

        # param=pattern.match(/(?=[\\\/]\:([a-z]+)(?:[\\\/]|$))/, 3)
        param=pattern.split(/[^:]+(\:[a-z][a-z0-9]+)/i)
        pattern.gsub!(/(\(|\))/i,"\\\\\\1")
        pattern.gsub!(/:[a-z][a-z0-9]+/i,"([^/]+)/?")
        if(param&&param.length>1)
          param.each do |val|
            val.strip!
            if(val.size>1)
              val.sub!(/^\:/,"")
              params.push(val)
              # params[:prop].push(val)
              # params[:val]+="\\#{params[:prop].size},"
            end
          end
        end

        if len===0
          pattern = ".*"
        else
          pattern.gsub!('*','.*')
        end
        pattern = Regexp.new("^"+pattern+"$")
      else
        print "Unexpected!!\n"
        pattern =/^.*/
      end
      return [pattern, params]
    end
    def ParseReq(_req)
      req=_req.strip().split(/\r\n([\w\W]+)/)
      req_stat= req[0].split("\s");
  
      header = req[1];
      path = req_stat[1].split(/\?([\w\W]+)/);
      path[0]=URI.decode_www_form_component(path[0])#.sub(/[\/]?$/,"/")
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
        body:{},
        rawRequest: _req,
        headers:{},
        param:{}
      }
  
      header = header.split(/\r\n|\n/)
      header.each{|val|
        val = val.split(":")
        obj[:headers][val[0].strip().downcase]=val[1].strip
        val=nil
      }
  
      RubyExpressFoo::parseQuery(query, obj: obj[:query])
  
      # free memory
      req_stat = req = header = query = path=nil
      return obj
    end
    def MatchClient(request, client, n, argv)
      req_method_obj = @RPaths[request[:method].downcase]
      if(req_method_obj.length<1)
        return
      end
  
      for i in n..req_method_obj.length-1
        val = req_method_obj[i]
        pattern=val[:pattern]
        path=request[:path]
        is_match = path.match?(pattern[0])
        path=path.sub(/\/?$/,"/")
        if(is_match)
          params = path.split(pattern[0])
          # puts(path,pattern[0])
          if(params&&params.size>1)
            i=0
            params.each do |val|
              val.strip!
              if(val.size>0)
                param=pattern[1][i]
                i+=1
                request[:param][param]=val
              end
            end
          end
          if argv
            argv[2].call(i+1)
            val[:callback].call(argv[0],argv[1])
          else
            Response.new(request, client, val[:callback], i+1, ->(n, argv){
              MatchClient(request, client, n, argv)
            },val[:useThread]);
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