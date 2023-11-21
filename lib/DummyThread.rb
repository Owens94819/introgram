
class Dummy_thread
    def initialize(level)
        @level=0;
        @threads=[];
        for i in 1..level
            @threads.push({list:[], init:false, thread:Thread.new(->(foo,i){
                thread=@threads[i]
                thread[:thread_cb]=foo
                thread[:list].each{|foo|
                    thread[:thread_cb].call(foo)
                }
                @init=true;
                @list=[];
            }, @threads.length-1) { |foo, i|
                foo.call(->(foo){
                    foo.call();
                },i)
            }})
        end
    end
    def push(foo)
        thread = @threads[@level]
        if(!thread)
            if(thread === 0)
                @level+=1;
                push(foo)
                return
            end
            @level=0;
            push(foo)
            return
        else
            @level+=1
        end

        if(thread[:init])
            thread[:thread_cb].call(foo)
        else
            thread[:list].push(foo)
        end
    end
    def kill(level)
        thread = @threads[level]
        if(thread)
            thread[:thread].kill()
            @threads[level]=0
        end
    end
end


