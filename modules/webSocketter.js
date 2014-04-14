// Generated by CoffeeScript 1.6.2
(function() {
  var Config, Controller, createWebSocketter, makeSocket, randobet, waiting, webSockets;

  Config = require('../config');

  Controller = require('./controller');

  webSockets = {};

  createWebSocketter = function(io) {
    return webSockets = io.of('/AI').on('connection', function(socket) {
      return makeSocket(socket);
    });
  };

  module.exports = createWebSocketter;

  makeSocket = function(socket) {
    return socket.on('join', function(data) {
      var failMessage, key, name, successMessage;
      name = data.name;
      if (!name) {
        failMessage = {
          status: 'fail',
          errorMessage: 'no name here!'
        };
        return socket.emit('joinResponse', failMessage);
      } else {
        key = randobet(28 + Math.floor(Math.random() * 6), '');
        successMessage = {
          status: 'ok',
          key: key,
          message: 'Your name is ' + name
        };
        socket.emit('joinResponse', successMessage);
        return Controller.join(name, key, socket.id);
      }
    });
  };

  waiting = function() {
    var actionPlayer, info, key, socketId, value, _ref;
    if (Controller.getState() === 'waiting') {
      return setTimeout(function() {
        return waiting();
      }, 1000);
    } else if (Controller.getState() === 'gaming') {
      webSockets.emit('start', {
        message: 'Game start!'
      });
      info = Controller.getInfo();
      webSockets.emit('tableInfo', Controller.getTableInfo(0));
      _ref = info.tables[0].players;
      for (key in _ref) {
        value = _ref[key];
        socketId = info.tables[0].players[key].socketId;
        webSockets.socket(socketId).emit('yourHand', {
          hand: info.tables[0].players[key].hand
        });
      }
      actionPlayer = Controller.getActionPlayer(0);
      return webSockets.socket(actionPlayer.socketId).emit('action', {});
    }
  };

  waiting();

  randobet = function(n, b) {
    var a, i, s, _i;
    b = b || '';
    a = 'abcdefghijklmnopqrstuvwxyz' + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' + '0123456789' + b;
    a = a.split('');
    s = '';
    for (i = _i = 0; 0 <= n ? _i < n : _i > n; i = 0 <= n ? ++_i : --_i) {
      s += a[Math.floor(Math.random() * a.length)];
    }
    return s;
  };

}).call(this);
