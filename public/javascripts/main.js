function build_message(user, message, with_name) {
  var chatroom = $('#chatroom');
  var user_str = '';
  var class_str = '';
  if(with_name && user.user_name) user_str += ('<b>' + user.user_name + ': </b>');
  if(user.id == session_id) class_str += 'current-user'
  var full_str = ("<p class='" + class_str + "'>" + user_str +  message + '</p>');
  chatroom.append(full_str);
}

function fetch_user(id) {
  for(var i = 0; i < users.length; i++) {
    if(users[i].id == id) return users[i];
  }
}

function update_user(user) {
  for(var i = 0; i < users.length; i++) {
    if(users[i].id == user.id) {
      users[i] = user;
      return true;
    }
    return false;
  }
}

function update_participants() {
  for(var i = 0; i < users.length; i++) {
    user = users[i];
    user_li = $('#' + user.id);
    if( user_li.length == 0) {
      $('#participants').append("<li id='" + user.id + "' class='list-group-item'>" + user.user_name + "</li>");
    } else if ( user.length > 0 && user_li.first().html() != user.user_name) {
      user.first().html(user.user_name);
    }
  }
}

function init() {
  var socket = io.connect(document.URL);
  if(localStorage['chat-user-name']) {
    window.user_name = localStorage['chat-user-name'];
    $('#user-name').val(user_name);
  } else { window.user_name = 'Anonymous' }

  window.session_id = '';
  window.users = [];

  function emit_message() {
    var message = $('#new-message').val();
    socket.emit('chat message', {user_id: session_id, message: message});
    $('#new-message').val('');
  };

  function emit_update_user() {
    user = fetch_user(session_id);
    old_user_name = user.user_name
    new_user_name = $('#user-name').val();
    localStorage.setItem('chat-user-name', new_user_name);
    user.user_name = new_user_name;

    socket.emit('user name update',
      {user: user,
        old_user_name: old_user_name,
      new_user_name: new_user_name});
  };

  socket.on('connect', function() {
    session_id = socket.socket.sessionid;
    console.log('Connected:', session_id);
    socket.emit('join', {id: session_id, user_name: user_name});
  });

    socket.on('chat message', function(data) {
      console.log('Message received:', data.message);
      build_message(fetch_user(data.user_id), data.message, true);
    });

    socket.on('user joined', function(data) {
      window.users = data.users
      console.log('User joined!', users);
      $('#chatroom').append('<p>A new user has joined the chatroom </p>')
    });

    socket.on('user updated', function(data) {
      $('#chatroom').append('<p>' + data.message + '</p>');
      update_user(data.user);
      update_participants();
    });

    socket.on('user disconnected', function(data) {
      users.remove(data.id);
      $('#' + data.id).remove()
      console.log('User disconnected:', data);
    });

  // Setup DOM bindings
  $('.btn-success').bind('click', function() {
    emit_message();
  });

  $('#user-name').keypress(function(e) {
    if (e.which == 13) {
      e.preventDefault();
      emit_update_user();
    }
  });

  $('#new-message').keypress(function(e) {
    if (e.which == 13) {
      e.preventDefault();
      emit_message();
    }
  });

  $('#update-user-name').bind('click', function() {
    emit_update_user();
  });
}

$(document).on('ready', init)

Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length);
  this.length = from < 0 ? this.length + from : from;
  return this.push.apply(this, rest);
};
