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
    action(socket, data)

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

goToNextHand = (tableId, webSockets) ->
  Controller.goToNextHand(tableId)
  tableInfoForWebSocketter = Controller.getTableInfoForWebSocketter(tableId)
  webSockets.emit('tableInfo', Controller.getTableInfo(tableId)) # テーブル情報更新
  for key, player of tableInfoForWebSocketter.players
    socketId = player.socketId
    webSockets.socket(socketId).emit('yourHand', { hand: player.hand })
  # 手番プレイヤーにアクションを通知します。
  actionPlayer = Controller.getActionPlayer(0)
  webSockets.socket(actionPlayer.socketId).emit('action', {});

action = (socket, data) ->
  tableId = 0
  actionedData = Controller.action(data)
  if actionedData.status && actionedData.status == 'ok'
    if actionedData.nextCommand != 'autoNextPhase'
      socket.emit('actionResponse',  actionedData.message) # 本人に受け取ったレスポンスを返す。
      webSockets.emit('takenActionAndResult', actionedData.sendAllTables) # 全員にアクションと

    if actionedData.nextCommand == 'nextHand'
      goToNextHand(tableId, webSockets)
    if actionedData.nextCommand == 'showDown'
      messages = Controller.showDown(tableId)
      for key, message of messages
        webSockets.emit('showDownResult', message) # 全員にショーダウン結果を報告
      Controller.playerSitOut(tableId) # スタックのなくなったプレイヤーをここで排除
      endCheckResult = Controller.endCheck()
      if endCheckResult != false
        webSockets.emit('endResult', endCheckResult)
      else
        goToNextHand(tableId, webSockets)
    if actionedData.nextCommand == 'nextPhase'
      Controller.goToNextPhase(tableId)
      webSockets.emit('tableInfo', Controller.getTableInfo(0)) # テーブル情報更新
      # 手番プレイヤーにアクションを通知します。
      actionPlayer = Controller.getActionPlayer(0)
      webSockets.socket(actionPlayer.socketId).emit('action', {});
    if actionedData.nextCommand == 'autoNextPhase'
      Controller.goToNextPhase(tableId)
      webSockets.emit('tableInfo', Controller.getTableInfo(0)) # テーブル情報更新
      data.action = 'check'
      action(socket, data)
    if actionedData.nextCommand == 'nextTurn'
      Controller.goToNextTurn(tableId)
      webSockets.emit('tableInfo', Controller.getTableInfo(0)) # テーブル情報更新
      # 手番プレイヤーにアクションを通知します。
      actionPlayer = Controller.getActionPlayer(0)
      webSockets.socket(actionPlayer.socketId).emit('action', {});
