coffee_middleware = require('coffee-middleware')
express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

io.configure ->
  io.set("transports", ["xhr-polling"])
  io.set("polling duration", 10)

app.configure ->
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use require('stylus').middleware({src: "#{__dirname}/public"})
  app.use coffee_middleware({src: "#{__dirname}/public", compress: true})
  app.use app.router
  app.use express.static("#{__dirname}/public")

app.get '/', (req, res) ->
  console.log "Routing request"
  res.render 'index.jade',
    title: 'Chatroom'
    users: users

users = []

fetch_user = (id) ->
  for u in users
    return u if u.id is id

remove_user = (id) ->
  users.remove(users.indexOf(id))

update_user = (user) ->
  for u, i in users
    if u.id is user.id
      users[i] = user
      return user
  undefined

io.sockets.on 'connection', (socket) ->
  socket.on 'join', (data) ->
    console.info 'Join Event:', data.user_name
    users.push(data)
    io.sockets.emit 'user joined',
      user: data,
      users: users

  socket.on 'chat message', (data) ->
    console.info 'Message sent:', data.message
    io.sockets.emit 'chat message',
      id: socket.id
      message: data.message

  socket.on 'user name update', (data) ->
    console.info "Switching user_name from #{data.old_user_name} to #{data.new_user_name}"
    update_user(data.user)
    io.sockets.emit 'user updated',
      user: data.user
      users: users
      message: "#{data.old_user_name} has changed their username to #{data.new_user_name}"

  socket.on 'disconnect', (data) ->
    remove_user(users.indexOf(socket.id))
    io.sockets.emit 'user disconnected',
      id: socket.id
      users: users



port = process.env.PORT || 3000
server.listen(port)

Array::remove = (from, to) ->
  rest = @slice((to or from) + 1 or @length)
  @length = (if from < 0 then (@length + from) else from)
  @push.apply this, rest
