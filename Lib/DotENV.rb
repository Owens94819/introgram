class Dot_env
    def initialize
        env=".env"
        if File.exist?(env)
            File.open(env, 'r') do |content|
                content.each_line { |line|
                    line = line.split('=')
                    line[0].strip!
                    if(!line[1])
                        line[1]=""
                    end
                    ENV[line[0]]=line[1].strip!
                }
            end
        end
    end
end
