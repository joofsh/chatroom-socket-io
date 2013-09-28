console.log "Starting app in: #{process.env.NODE_ENV} mode"


coffee_middleware = require('coffee-middleware')
express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

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
messages = []

fetch_user = (id) ->
  for u in users
    return u if u.id is id

remove_user = (id) ->
  users.remove(users.indexOf(fetch_user(id)))

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
      messages: messages
      message: {user: data, message: "#{data.user_name} has joined the chatroom", with_name: false}

  socket.on 'chat message', (data) ->
    console.info 'Message sent:', data.message
    messages.push(data)
    io.sockets.emit 'chat message', data

  socket.on 'user name update', (data) ->
    console.info "Switching user_name from #{data.old_user_name} to #{data.new_user_name}"
    update_user(data.user)
    io.sockets.emit 'user updated',
      user: data.user
      users: users
      message: {user: data.user, message: "#{data.old_user_name} has changed their username to #{data.new_user_name}", with_name: false}

  socket.on 'disconnect', (data) ->
    user = fetch_user(socket.id)
    remove_user(socket.id)
    io.sockets.emit 'user disconnected',
      id: socket.id
      users: users
      message: {user: user, message: "#{user.user_name} has left the channel", with_name: false}



port = if process.env.NODE_ENV is 'production' then 80 else 3000
server.listen(port)

Array::remove = (index) ->
  rest = @slice(index + 1)
  @length = (if index < 0 then (@length + index) else index)
  @push.apply this, rest
