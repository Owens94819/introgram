require "./RubyExpress/RubyExpress.rb"


server = RubyExpress.new(port: 8080);


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
    res.send('404')
})

# puts RubyExpressRequest::Request.new
puts "server at port 8080"
server.listen()