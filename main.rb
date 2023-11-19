
require "./RubyExpress/RubyExpress.rb"
require "./lib/Dotenv.rb"

Dot_env.new()

server = RubyExpress.new(port: ENV['PORT']);

server.use('/__socket__', ->(req, res){
    res.setHeader('content-type', 'text/html')
    res.send('GET req')
})
server.get('/home', ->(req, res){
    res.setHeader('content-type', 'text/html')
    res.write("...")
    # res.send('POST req')
})
server.use('', ->(req, res){
    res.setHeader('4004', 'text/html')
    res.send('404:'+req.path)
})

# puts RubyExpressRequest::Request.new
puts "server at port #{ENV["PORT"]}"

require('./db.rb')
server.listen()