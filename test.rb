require "./RubyExpress.rb"
server = RubyExpress.new(port: 8080);

server.use('/home*', ->(req, res){
    res.setHeader('content-type', 'text/html')
    res.send('hello world<b>kk')
})

server.use('', ->(req, res){
    res.send('404')
})

puts "server at port 8080"
server.listen()