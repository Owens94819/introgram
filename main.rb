require "./RubyExpress.rb"
require "./dummy_thread.rb"

dummy_thread=Dummy_thread.new(2);

server = RubyExpress.new(port: 8080);


server.use('/__socket__', ->(req, res){
    res.setHeader('content-type', 'text/html')
    res.send('GET req')
})
server.post('/home', ->(req, res){
    res.setHeader('content-type', 'text/html')
    res.send('POST req')
})

server.use('', ->(req, res){
    res.send('404')
})

puts "server at port 8080"
server.listen()