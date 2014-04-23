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
    Controller.join data ,socket.id, (responseData) ->
    if responseData.response == 'fail'
      socket.emit('joinResponse', {
        status: 'fail',
        errorMessage: responseData.errorMessage
      })
    else
      socket.emit('joinResponse', {
        status: 'ok',
        key: responseData.key,
        message: 'Your name is '+name
      })

  socket.on 'action', (data) ->
    tableId = 0
    Controller.action data, (callbackData) ->
      if callbackData.status == 'ok'
        socket.emit('actionResponse',  callbackData.message) # 本人に受け取ったレスポンスを返す。
        webSockets.emit('takenActionAndResult', callbackData.sendAllTables) # 全員にアクションと
        if callbackData.nextCommand == 'nextHand'
          Controller.goToNextHand(tableId)
          tableInfoForWebSocketter = Controller.getTableInfoForWebSocketter(tableId)
          webSockets.emit('tableInfo', Controller.getTableInfo(tableId)) # テーブル情報更新
          for key, player of tableInfoForWebSocketter.players
            socketId = player.socketId
            webSockets.socket(socketId).emit('yourHand', { hand: player.hand })
          # 手番プレイヤーにアクションを通知します。
          actionPlayer = Controller.getActionPlayer(0)
          webSockets.socket(actionPlayer.socketId).emit('action', {});
        else if callbackData.nextCommand == 'showDown'
          Controller.showDown tableId, (data) ->
            console.log data
        else if callbackData.nextCommand == 'nextPhase'
          Controller.goToNextPhase(tableId)
          webSockets.emit('tableInfo', Controller.getTableInfo(0)) # テーブル情報更新
          # 手番プレイヤーにアクションを通知します。
          actionPlayer = Controller.getActionPlayer(0)
          webSockets.socket(actionPlayer.socketId).emit('action', {});
        else if callbackData.nextCommand == 'nextTurn'
          Controller.goToNextTurn(tableId)
          webSockets.emit('tableInfo', Controller.getTableInfo(0)) # テーブル情報更新
          # 手番プレイヤーにアクションを通知します。
          actionPlayer = Controller.getActionPlayer(0)
          webSockets.socket(actionPlayer.socketId).emit('action', {});

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
      webSockets.socket(socketId).emit('yourSeat', { seat: key })
      webSockets.socket(socketId).emit('yourHand', { hand: info.tables[0].players[key].hand })
    # 手番プレイヤーにアクションを通知します。
    actionPlayer = Controller.getActionPlayer(0)
    webSockets.socket(actionPlayer.socketId).emit('action', {})
waiting()
