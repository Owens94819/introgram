# RubyExpress
```ruby 
server = RubyExpress.new(port: 8080);
```
the below methods about to be explained takes 2 parameters
- the first parameter is the pattern or routes to accept
- the second takes a lambda function
```
server.get(pattern, lambda)
```

## server.get
accepting a GET request from client
```ruby 
server.get('/path', ->(req, res){
    # res.setHeader('content-type', 'text/html')
    # res.send('GET req')
})
```
## server.post
accepting a POST request from client
```ruby 
server.post('/path', ->(req, res){
    # res.setHeader('content-type', 'text/html')
    # res.send('POST req')
})
```
## server.use
accepting all kinds of request from client
```ruby 
server.use('/path', ->(req, res){
    # res.setHeader('content-type', 'text/html')
    # res.send('ALL req')
})
```
## req
this object contains info from the client
### req.headers
 ```
  puts res.headers
 ```
### req.rawHeaders
 ```
  puts res.rawHeaders
 ```
 ### req.query
 ```
  puts res.query
 ```
### req.path
 ```
  puts res.path
 ```
### req.method
 ```
  puts res.method
 ```
### req.url
 ```
  puts res.url
 ```
### req.search
 ```
  puts res.search
 ```
## res
this object contains methods to initialize a response to the client
### res.setHeader
```
res.setHeader(name, value)
```
### res.setStatus
```
res.setStatus(code)
```
### res.next
this will move the client to the next matching pattern
```
res.next()
```
### res.send
this will automatically write the "msg" and end the response
```
res.send(msg)
```
### res.write
```
res.write(msg)
```
### res.end
```
res.end(msg)
```