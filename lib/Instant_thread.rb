class Instant_thread
    def initialize(foo)
        thread = Thread.new(foo,->{thread.kill()}){|foo, kill|
                foo.call()
                kill.call()
            }
    end
end