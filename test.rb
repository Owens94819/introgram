require "./RubyExpress.rb"
server = RubyExpress.new(port: 8080);


server.get('/home', ->(req, res){
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