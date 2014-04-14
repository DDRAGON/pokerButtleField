Config = require('../config')
Controller = require('./controller')

webSockets = {}

createWebSocketter = (io) ->
  webSockets = io.of('/AI').on 'connection', (socket) ->
    makeSocket(socket)

module.exports = createWebSocketter

makeSocket = (socket) ->

  socket.on 'join', (data) ->
    name = data.name
    if !name
      failMessage =
        status: 'fail',
        errorMessage: 'no name here!'
      socket.emit('joinResponse', failMessage)
    else
      key = randobet(28+Math.floor(Math.random() * 6), '')
      successMessage =
        status: 'ok',
        key: key,
        message: 'Your name is '+name
      socket.emit('joinResponse', successMessage)
      Controller.join(name, key, socket.id)

waiting = () ->
  if Controller.getState() == 'waiting'
    setTimeout ->
      waiting()
    , 1000
  else if Controller.getState() == 'gaming'
    webSockets.emit('start', {message: 'Game start!'})
    info = Controller.getInfo()
    # テーブル情報を全員に知らせます。
    webSockets.emit('tableInfo', Controller.getTableInfo(0))
    # 参加AIにハンド情報を送ります。
    for key, value of info.tables[0].players
      socketId = info.tables[0].players[key].socketId
      webSockets.socket(socketId).emit('yourHand', { hand: info.tables[0].players[key].hand });
    # 手番プレイヤーにアクションを通知します。
    actionPlayer = Controller.getActionPlayer(0)
    webSockets.socket(actionPlayer. socketId).emit('action', {});
waiting()


# ランダム文字列のキーを発行する。
randobet = (n, b) ->
  b = b || ''
  a = 'abcdefghijklmnopqrstuvwxyz' + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' + '0123456789' + b
  a = a.split('')
  s = ''
  for i in [0...n]
    s += a[Math.floor(Math.random() * a.length)]
  return s;