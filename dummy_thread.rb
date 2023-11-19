
class Dummy_thread
    def initialize(n)
        @index=0;
        @threads=[];
        for i in 1..n
            @threads.push({list:[], init:false})
            Thread.new(->(foo,i){
                thread=@threads[i]
                thread[:thread]=foo
                thread[:list].each{|foo|
                    thread[:thread].call(foo)
                }
                @init=true;
                @list=[];
            }, @threads.length-1) { |foo, i|
                foo.call(->(foo){
                    foo.call();
                },i)
            }
        end
    end
    def push(foo)
        thread = @threads[@index]
        if(!thread)
            @index=0;
            push(foo)
            return
        else
            @index+=1
        end

        if(thread[:init])
            thread[:thread].call(foo)
        else
            thread[:list].push(foo)
        end
    end
end