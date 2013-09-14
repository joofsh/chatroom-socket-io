@app = angular.module('chat_room', [])
@socket = io.connect(document.URL, {'sync disconnect on unload' : true})

@ChatController = ($scope, User, Message) ->
  window.scope = $scope
  $scope.Message = Message
  $scope.User = User
  $scope.messages = Message.all
  $scope.users = User.all
  $scope.user_name = (if localStorage['user_name'] then localStorage['user_name'] else 'Anonymous')

  $scope.update_user_name = ->
    user = User.fetch($scope.session_id)
    old_user_name = user.user_name
    user.user_name = $scope.user_name
    localStorage.setItem('user_name', $scope.user_name)
    socket.emit 'user name update',
      user: user
      old_user_name: old_user_name
      new_user_name: $scope.user_name

  $scope.send_message = (message) ->
    socket.emit 'chat message',
      id: $scope.session_id
      message: message

  $scope.current_user = (user) ->
    return false unless user
    user.id is $scope.session_id

  socket.on 'connect', ->
    console.log 'Connected', socket
    $scope.session_id = socket.socket.sessionid
    socket.emit 'join',
      id: $scope.session_id
      user_name: $scope.user_name

  socket.on 'chat message', (data) ->
    console.log 'Message received:', data.message
    $scope.$apply(Message.add(data.message, User.fetch(data.id), true))


  socket.on 'user joined', (data) ->
    User.set(data.users)
    console.log 'User joined!', data.users
    $scope.$apply(Message.add("#{data.user.user_name} has joined the chatroom", null, false))

  socket.on 'user disconnected', (data) ->
    user = User.fetch(data.id)
    User.set(data.users)
    $scope.$apply(Message.add("#{user.user_name} has left the channel", null, false))
    console.log 'User disconnected', data.id
    console.log 'Users remaining:', User.all().length

  socket.on 'user updated', (data) ->
    User.set(data.users)
    $scope.$apply(Message.add(data.message, null, false))

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
        users[i] = user
        return user
    undefined

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

@app.directive 'sendMessage', ->
  (scope, element, attrs) ->

    send_message = ->
      message = element.val()
      scope.send_message(message) if message.replace(new RegExp(' ', 'g'),'').length > 0
      element.val('')

    element.on 'keypress', (e) ->
      if e.which is 13
        e.preventDefault()
        send_message()

    $('#send-message').on 'click', ->
      send_message()

@app.directive 'updateUserName', ->
  (scope, element, attrs) ->

    element.on 'keypress', (e) ->
      if e.which is 13
        e.preventDefault()
        scope.update_user_name()

    $('#update-user-name').on 'click', ->
      scope.update_user_name()

