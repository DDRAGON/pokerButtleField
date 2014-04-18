Config = require('../config')

tables = {}
playersCount = 0
structure = Config.getStructure()
intervalTime = Config.getIntervalTime()
state = 'waiting'
level = 0

join = (name, key, socketId) ->
  if !tables[0] || tables[0].players.length < 10
    if !tables[0]
      tables[0] = {}
    if !tables[0].players
      tables[0].players = []
    tables[0].players[tables[0].players.length] = {
      id: playersCount,
      name: name,
      key: key,
      socketId: socketId,
      isActive: false,
      hasAction: false,
      win: null,
      tie: null,
      hand: []
    }
  playersCount += 1

gameStart = () ->
  level = 0
  stack = Config.getStack()
  for tableId, table of tables
    table.players = [].concat(shufflePlayers(table.players))
    console.log 'shuffled players = '+table.players
    table.dealerButton = Math.floor(Math.random()*table.players.length)
    # ゲームの初期設定
    table.playedHandCount = 0
    table.actionCount = 0
    table.lastBet = 0
    table.pot = 0
    table.playersNum = table.players.length
    table.activePlayersNum = table.players.length
    table.hasActionPlayersNum = table.players.length
    table.board = []
    table.state = 'preFlop'
    # 初期スタックの設定
    for i in [0...table.players.length]
      table.players[i].stack = stack
      tables[tableId].players[i].isActive = true
      tables[tableId].players[i].hasAction = true
    # SB BB のチップ提出
    sbPosition = (table.dealerButton+1)%table.players.length
    bbPosition = (table.dealerButton+2)%table.players.length
    table.pot += Number(structure[level]/2)
    table.players[sbPosition].stack -= Number(structure[level]/2)
    table.pot += structure[level]
    table.players[bbPosition].stack -= structure[level]
    # 手札を配る
    dealPlayersHands(tableId)
    # 手番プレイヤーの設定
    table.actionPlayerSeat = (table.dealerButton+3)%table.players.length

  setTimeout ->
    blindUp()
  , intervalTime
  state = 'gaming'

getInfo = () ->
  info = {
    state: state,
    level: level,
    tables: {}
  }
  for tableId, table of tables
    info.tables[tableId] = {
      pot: table.pot,
      lastBet: table.lastBet,
      dealerButton: table.dealerButton,
      playedHandCount: table.playedHandCount,
      playersNum: table.playersNum,
      activePlayersNum: table.activePlayersNum,
      players: table.players
    }
  return info

getState = () ->
  return state

getTableInfo = (tableId) ->
  tableInfo = {
    state: state,
    level: level,
    pot: tables[tableId].pot,
    lastBet: tables[tableId].lastBet,
    dealerButton: tables[tableId].dealerButton,
    playedHandCount: tables[tableId].playedHandCount,
    playersNum: tables[tableId].playersNum,
    activePlayersNum: tables[tableId].activePlayersNum,
    players: []
  }
  for key, player of tables[tableId].players
    tableInfo.players[key] = {
      name: player.name,
      stack: player.stack,
      isActive: player.isActive
    }
  return tableInfo

getActionPlayer = (tableId) ->
  return tables[tableId].players[tables[tableId].actionPlayerSeat]

action = (data, callback) ->
  key = data.key
  action = data.action
  amount = data.amount
  tableId = 0
  if key == tables[tableId].players[tables[tableId].actionPlayerSeat].key
    actionPlayerSeat = tables[tableId].actionPlayerSeat
    switch action
      when 'fold'
        tables[tableId].players[actionPlayerSeat].isActive = false
        tables[tableId].players[actionPlayerSeat].hasAction = false
        tables[tableId].activePlayersNum -= 1
        tables[tableId].hasActionPlayersNum -= 1
        nextCommand = getNextCommand(tableId) # 次どうするかの指令
        if nextCommand == 'nextHand'
          winPlayerSeat = 0
          for playerSeat, player of tables[tableId].players
            if player.isActive == true
              winPlayerSeat = playerSeat
          tables[tableId].players[winPlayerSeat].stack += tables[tableId].pot
          callback({
            status: 'ok',
            message: 'got fold.',
            nextCommand: nextCommand,
            sendAllTables:{
              takenAction: 'fold',
              tableInfo: getTableInfo(tableId),
              message: tables[tableId].players[winPlayerSeat].name+' takes pot '+tables[tableId].pot
            }
          })
          console.log 'go to next hand'
        else # まだ勝負は続くとき
          callback({
            status: 'ok',
            message: 'got fold.',
            nextCommand: nextCommand,
            sendAllTables:{
              takenAction: 'fold',
              tableInfo: getTableInfo(tableId),
              message: 'go to next turn'
            }
          })

      when 'check'
        tables[tableId].players[actionPlayerSeat].hasAction = false
        tables[tableId].hasActionPlayersNum -= 1
        nextCommand = getNextCommand(tableId) # 次どうするかの指令
        callback({
          status: 'ok',
          message: 'got check.',
          nextCommand: nextCommand,
          sendAllTables:{
            takenAction: 'check',
            tableInfo: getTableInfo(tableId),
            message: 'go to next turn'
          }
        })

      when 'call'
        tables[tableId].pot += tables[tableId].lastBet
        tables[tableId].players[actionPlayerSeat].stack -= tables[tableId].lastBet
        tables[tableId].players[actionPlayerSeat].hasAction = false
        tables[tableId].hasActionPlayersNum -= 1
        nextCommand = getNextCommand(tableId) # 次どうするかの指令
        callback({
          status: 'ok',
          message: 'got call.',
          nextCommand: nextCommand,
          sendAllTables:{
            takenAction: 'call',
            tableInfo: getTableInfo(tableId),
            message: 'go to next turn'
          }
        })

      when 'raise'
        if amount < tables[tableId].lastBet*2
          amount = tables[tableId].lastBet*2
        tables[tableId].pot += amount
        tables[tableId].players[actionPlayerSeat].stack -= amount
        addHasActionToActives(tableId)
        tables[tableId].players[actionPlayerSeat].hasAction = false
        tables[tableId].hasActionPlayersNum -= 1
        callback({
          status: 'ok',
          message: 'got raise '+amount,
          nextCommand: 'nextTurn',
          sendAllTables:{
            takenAction: 'raise',
            tableInfo: getTableInfo(tableId),
            message: 'go to next turn'
          }
        })
  else
    callback('ignroe')

goToNextTurn = (tableId, callback) ->
  console.log 'goToNextTurn called.'
  tables[tableId].actionPlayerSeat = findNextActionPlayerSeat(tableId)
  callback(getTableInfo(tableId))

goToNextPhase = (tableId) ->
  console.log 'goToNextPhase called.'
  switch tables[tableId].state
    when 'preFlop'
      console.log 'preFlop'
      dealPreFlop(tableId)
      tables[tableId].state = 'flop'
    when 'flop'
      console.log 'flop'
      dealTurn(tableId)
      tables[tableId].state = 'turn'
    when 'turn'
      console.log 'turn'
      dealRiver(tableId)
      tables[tableId].state = 'river'
    when 'river'
      console.log 'river'
      tables[tableId].state = 'showDown'
  resetPlayersHasActive(tableId)

goToNextHand = (tableId) ->
  console.log 'goToNextHand called.'

module.exports = {
  join: join,
  getInfo: getInfo,
  gameStart: gameStart,
  getState: getState,
  getTableInfo: getTableInfo,
  getActionPlayer: getActionPlayer,
  action: action,
  goToNextTurn: goToNextTurn
}

# ここから下はエクスポートしないプライベートメソッド
blindUp = () ->
  level += 1
  setTimeout ->
    blindUp()
  , intervalTime

dealPlayersHands = (tableId) ->
  tables[tableId].deck = [].concat(createDeck())
  for i in [0...2]
    for key, value of tables[tableId].players
      cardPosition = Math.floor(Math.random() * tables[tableId].deck.length)
      tables[tableId].players[key].hand[i] = tables[tableId].deck[cardPosition]
      tables[tableId].deck.splice(cardPosition, 1)

dealPreFlop = (tableId) ->
  for i in [0...3]
    cardPosition = Math.floor(Math.random() * tables[tableId].deck.length)
    tables[tableId].board[i] = tables[tableId].deck[cardPosition]
    tables[tableId].deck.splice(cardPosition, 1)

dealTurn = (tableId) ->
  cardPosition = Math.floor(Math.random() * tables[tableId].deck.length)
  tables[tableId].board[3] = tables[tableId].deck[cardPosition]
  tables[tableId].deck.splice(cardPosition, 1)

dealRiver = (tableId) ->
  cardPosition = Math.floor(Math.random() * tables[tableId].deck.length)
  tables[tableId].board[4] = tables[tableId].deck[cardPosition]
  tables[tableId].deck.splice(cardPosition, 1)

findNextActionPlayerSeat = (tableId) ->
  nowActionPlayerSeat = tables[tableId].actionPlayerSeat
  for i in [1...tables[tableId].players.length]
    checkSeat = (nowActionPlayerSeat + i)%tables[tableId].players.length
    if (tables[tableId].players[checkSeat].isActive == true)
      return checkSeat

getNextCommand = (tableId) ->
  console.log 'getNextCommand called'
  if tables[tableId].activePlayersNum == 1 # プレイヤーが一人だけになったとき（勝負あり）
    return 'nextHand'
  else if tables[tableId].hasActionPlayersNum == 0 # アクション権をもっているプレーヤーがいない（次のフェイズに進む）
    return 'nextPhase'
  else 'nextTurn'

addHasActionToActives = (tableId) ->
  console.log 'addHasActionToActives called'
  hasActionCounter = 0
  for i in [0...tables[tableId].players.length]
    if tables[tableId].players.isActive == true
      tables[tableId].players.hasAction = true
      hasActionCounter += 1
  tables[tableId].hasActionPlayersNum = hasActionCounter

createDeck = () ->
  trumps = [
    'As','2s','3s','4s','5s','6s','7s','8s','9s','Ts','Js','Qs','Ks',
    'Ah','2h','3h','4h','5h','6h','7h','8h','9h','Th','Jh','Qh','Kh',
    'Ad','2d','3d','4d','5d','6d','7d','8d','9d','Td','Jd','Qd','Kd',
    'Ac','2c','3c','4c','5c','6c','7c','8c','9c','Tc','Jc','Qc','Kc'
  ]
  return shuffleArray(trumps)

shuffleArray = (targetArray) ->
  length = targetArray.length
  for i in [0...length] of targetArray
    j = Math.floor(Math.random()*length)
    t = targetArray[i]
    targetArray[i] = targetArray[j]
    targetArray[j] = t
  return targetArray

shufflePlayers = (players) ->
  length = players.length
  for i in [0...length] of players
    j = Math.floor(Math.random()*length)
    t = new (players[i].constructor)();
    players[i] = new (players[j].constructor)();
    players[j] = new (t.constructor)();
  return players
