express= require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)


app.configure ->
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use require('stylus').middleware({src: "#{__dirname}/public"})
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

io.sockets.on 'connection', (socket) ->
  socket.on 'join', (data) ->
    console.info 'Join Event:', data.user_name
    users.push(data)
    io.sockets.emit 'user joined',
      user: data

  socket.on 'chat message', (data) ->
    console.info 'Message sent:', data.message
    io.sockets.emit 'chat message',
      user_id: socket.id
      message: data.message

  socket.on 'user name update', (data) ->
    console.info "Switching user_name from #{data.old_user_name} to #{data.new_user_name}"
    io.sockets.emit 'user updated',
      user: data.user
      message: "#{data.old_user_name} has changed their username to #{data.new_user_name}"

  socket.on 'disconnect', ->
    users.remove(users.indexOf(socket.id))
    io.sockets.emit 'user disconnected', {id: socket.id}



server.listen 3000

Array::remove = (from, to) ->
  rest = @slice((to or from) + 1 or @length)
  @length = (if from < 0 then (@length + from) else from)
  @push.apply this, rest