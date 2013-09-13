@app = angular.module('chat_room', [])
@socket = io.connect(document.URL)

@ChatController = ($scope, User, Message) ->
  window.scope = $scope
  $scope.messages = Message.all
  $scope.users = User.all

  $scope.user_name = (if localStorage['user_name'] then localStorage['user_name'] else 'Anonymous')

  $scope.fetch_user = (id) ->
    for user in $scope.users
      return user if user.id is id

  socket.on 'connect', ->
    console.log 'Connected', socket
    $scope.session_id = socket.socket.sessionid
    socket.emit 'join',
      id: $scope.session_id
      user_name: $scope.user_name

  socket.on 'chat message', (data) ->
    console.log 'Message received:', data.message
    Message.add(data.message, User.fetch(data.id), true)


  socket.on 'user joined', (data) ->
    $scope.$apply(User.set(data.users))
    console.log 'User joined!', data.users
    # TODO: Add notification that user joined
    # TODO: Update participants list

  socket.on 'user disconnected', (data) ->
    $scope.$apply(User.remove(data.id))
    console.log 'User disconnected', data
    # TODO: Remove user from participants list







ChatController.$inject = ['$scope', 'User', 'Message']

@app.factory 'User', ->
  users = []

  set: (new_users_arr) ->
    users = new_users_arr

  all: -> users

  add: (user) -> users.push(user)

  fetch: (id) ->
    for user in users
      return user if user.id is id

  update: (user) ->
    for u, i in users
      if user.id is u.id
        u[i] = user
        true
      else
        false

  remove: (id) ->
    users = _.without(users, this.fetch(id))



@app.factory 'Message', ->
  messages = []

  all: -> messages

  add: (message, user, with_name) ->
    message_obj =
      message: message
      user: user
      with_name: with_name
    messages.push message_obj


