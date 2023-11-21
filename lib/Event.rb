class Event
    def initialize()
        @events={}
    end

    def on(name, cb)
        if(@events)
            event = @events[name]
            if(!event)
                event=@events[name]=[cb]
            else
                event.push(cb)
            end
        end
      return self
    end
    def emit(name, value)
        if(@events)
            event = @events[name];
            if(event)
                event.each do |val|
                val.call(value)
                end
            end
        end
    end
    def removeAll
        @events = nil
    end
end