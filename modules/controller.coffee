Config = require('../config')
WinPer = require('./WinPer')

tables = {}
playersCount = 0
structure = Config.getStructure()
intervalTime = Config.getIntervalTime()
state = 'waiting'
level = 0
playerRanking = []

join = (data, socketId, callback) ->
  name = data.name
  tableId = 0
  if !name
    callback({
      response: 'fail',
      errorMessage: 'no name here!'
    })
  else
    key = randobet(28+Math.floor(Math.random() * 6), '')
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
    callback({
      response: 'ok',
      key: key
    })

gameStart = () ->
  level = 0
  stack = Config.getStack()
  for tableId, table of tables
    table.players = [].concat(shufflePlayers(table.players))
    console.log 'shuffled players = '+table.players
    table.dealerButton = Math.floor(Math.random()*table.players.length)
    # ゲームの初期設定
    table.playedHandCount = 0
    table.lastBet = 0
    table.pot = 0
    table.bettingTotal = 0
    table.playersNum = table.players.length
    table.activePlayersNum = table.players.length
    table.hasActionPlayersNum = table.players.length
    table.board = []
    table.allInCalcFlags = []
    table.allInInfo = []
    table.state = 'preFlop'
    # 初期スタックの設定
    for i in [0...table.players.length]
      table.players[i].stack = stack
      tables[tableId].players[i].isActive = true
      tables[tableId].players[i].hasAction = true
      tables[tableId].players[i].isAllIn = false
      tables[tableId].players[i].lastBet = 0
      tables[tableId].players[i].lastAction = 0
    # 各ポジションの設定（SB BB 手番）
    setPositions(tableId)
    # SB BB のチップ提出
    setSbBbChips(tableId)
    # 手札を配る
    dealPlayersHands(tableId)

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
  if state == 'waiting'
    return {}
  tableInfo = {
    state: tables[tableId].state,
    level: level,
    pot: tables[tableId].pot,
    bettingTotal: tables[tableId].bettingTotal,
    lastBet: tables[tableId].lastBet,
    dealerButton: tables[tableId].dealerButton,
    playedHandCount: tables[tableId].playedHandCount,
    playersNum: tables[tableId].playersNum,
    activePlayersNum: tables[tableId].activePlayersNum,
    board: tables[tableId].board,
    players: []
  }
  for key, player of tables[tableId].players
    tableInfo.players[key] = {
      seat: player.seat,
      name: player.name,
      stack: player.stack,
      isActive: player.isActive,
      isAllIn: player.isAllIn,
      lastBet: player.lastBet
    }
  return tableInfo

getSpectatorTableInfo = (tableId) ->
  spectatorTableInfo = {}
  if !tables[tableId]
    spectatorTableInfo.state = state
    spectatorTableInfo.level = 0
    spectatorTableInfo.board = []
    return spectatorTableInfo

  if tables[tableId].state
    spectatorTableInfo.state = tables[tableId].state
  if typeof level != 'undefined'
    spectatorTableInfo.level = level
    spectatorTableInfo.bbAmount = structure[level]
  if typeof tables[tableId].pot != 'undefined'
    spectatorTableInfo.pot = tables[tableId].pot
  if typeof tables[tableId].bettingTotal != 'undefined'
     spectatorTableInfo.bettingTotal = tables[tableId].bettingTotal
  if tables[tableId].lastBet
    spectatorTableInfo.lastBet = tables[tableId].lastBet
  spectatorTableInfo.dealerButton = tables[tableId].dealerButton
  if tables[tableId].playedHandCount
    spectatorTableInfo.playedHandCount = tables[tableId].playedHandCount
  if tables[tableId].playersNum
    spectatorTableInfo.playersNum = tables[tableId].playersNum
  if tables[tableId].activePlayersNum
    spectatorTableInfo.activePlayersNum = tables[tableId].activePlayersNum
  spectatorTableInfo.actionPlayerSeat = tables[tableId].actionPlayerSeat
  if tables[tableId].board
    spectatorTableInfo.board = tables[tableId].board
  spectatorTableInfo.players = []
  # プレイヤーデータ
  for key, player of tables[tableId].players
    spectatorTableInfo.players[key] = {
      id: key,
      seat: player.seat,
      name: player.name,
      stack: player.stack,
      isActive: player.isActive,
      isAllIn: player.isAllIn,
      lastBet: player.lastBet,
      hand: player.hand,
      lastAction: player.lastAction
    }
  return spectatorTableInfo

getTableInfoForWebSocketter = (tableId) ->
  return tables[tableId]

getActionPlayer = (tableId) ->
  console.log 'tables[tableId].actionPlayerSeat = '+tables[tableId].actionPlayerSeat
  console.log 'tables[tableId].players[tables[tableId].actionPlayerSeat] = '+tables[tableId].players[tables[tableId].actionPlayerSeat]
  return tables[tableId].players[tables[tableId].actionPlayerSeat]

action = (data) ->
  key    = data.key
  action = data.action
  amount = data.amount
  tableId = 0
  actionPlayerSeat = tables[tableId].actionPlayerSeat
  if key == tables[tableId].players[actionPlayerSeat].key
    switch action
      when 'fold'
        return actionFold(tableId, actionPlayerSeat)
      when 'check'
        return actionCheck(tableId, actionPlayerSeat)
      when 'call'
        return actionCall(tableId, actionPlayerSeat)
      when 'raise'
        return actionRaise(tableId, actionPlayerSeat, amount)
      when 'autoNextPhase'
        return actionAutoNextPhase(tableId)
  return 'ignroe'

goToNextTurn = (tableId) ->
  console.log 'goToNextTurn called.'
  tables[tableId].actionPlayerSeat = findNextActionPlayerSeat(tableId)

goToNextPhase = (tableId) ->
  nextPhaseResetOperation(tableId)
  switch tables[tableId].state
    when 'preFlop'
      dealPreFlop(tableId)
      tables[tableId].state = 'flop'
    when 'flop'
      dealTurn(tableId)
      tables[tableId].state = 'turn'
    when 'turn'
      dealRiver(tableId)
      tables[tableId].state = 'river'
  # アクション権限のリセットと手番のリセット
  addHasActionToActives(tableId)
  tables[tableId].actionPlayerSeat = tables[tableId].dealerButton
  tables[tableId].actionPlayerSeat = findNextActionPlayerSeat(tableId)


goToNextHand = (tableId) ->
  console.log 'goToNextHand called.'
  tables[tableId].dealerButton = (tables[tableId].dealerButton + 1)%tables[tableId].players.length
  # ゲームの初期設定
  tables[tableId].playedHandCount += 1
  tables[tableId].lastBet = 0
  tables[tableId].pot = 0
  tables[tableId].bettingTotal = 0
  tables[tableId].playersNum = tables[tableId].players.length
  tables[tableId].activePlayersNum = tables[tableId].players.length
  tables[tableId].hasActionPlayersNum = tables[tableId].players.length
  tables[tableId].board = []
  tables[tableId].allInCalcFlags = []
  tables[tableId].allInInfo = []
  tables[tableId].state = 'preFlop'
  # アクティブの初期化とアクション権限の付与
  for playerId, player of tables[tableId].players
    tables[tableId].players[playerId].isActive = true
    tables[tableId].players[playerId].hasAction = true
    tables[tableId].players[playerId].isAllIn = false
    tables[tableId].players[playerId].lastBet = 0
    tables[tableId].players[playerId].lastAction = null
  # 各ポジションの設定（SB BB 手番）
  setPositions(tableId)
  # SB BB のチップ提出
  setSbBbChips(tableId)
  # 手札を配る
  dealPlayersHands(tableId)

showDown = (tableId) ->
  nextPhaseResetOperation(tableId)
  messages = []
  # メインポット
  objForWinPer = {
    board: tables[tableId].board,
    players: []
  }
  for playerId, player of tables[tableId].players
    if player.isActive == true && player.isAllIn == false
      objForWinPer.players[objForWinPer.players.length] = player
  WinPer.getPlayersPointAndKicker(objForWinPer)
  winPlayers = WinPer.getWinPlayer(objForWinPer)
  winPlayersNum = winPlayers.length
  dividedPot = Math.floor(tables[tableId].pot/winPlayersNum)
  message = ''
  for key, value of winPlayers
    targetPlayerId = winPlayers[key].id
    tables[tableId].players[targetPlayerId].stack += dividedPot
    message += ' '+tables[tableId].players[targetPlayerId].name
  message += ' won the pot: '+dividedPot
  messages[messages.length] = message

  # サイドポット
  if !tables[tableId].allInInfo || tables[tableId].allInInfo.length <= 0
    return messages
  for i in [(tables[tableId].allInInfo.length-1)..0] # tables[tableId].allInInfo はポットが小さい順に入っている。allInCalc関数内
    allInInfo = tables[tableId].allInInfo[i]
    objForWinPer.players = winPlayers
    objForWinPer.players[objForWinPer.players.length] = tables[tableId].players[allInInfo.playerSeat]
    WinPer.getPlayersPointAndKicker(objForWinPer)
    winPlayers = WinPer.getWinPlayer(objForWinPer)
    winPlayersNum = winPlayers.length
    dividedPot = Math.floor(allInInfo.sidePot/winPlayersNum)
    message = ''
    for key, value of winPlayers
      targetPlayerId = winPlayers[key].id
      tables[tableId].players[targetPlayerId].stack += dividedPot
      message += ' '+tables[tableId].players[targetPlayerId].name
    message += ' won the pot: '+dividedPot
    messages[messages.length] = message

  return messages

playerSitOut = (tableId) ->
  for playerId, player of tables[tableId].players
    if player.stack == 0 # スタックがゼロになったプレーヤーをテーブルから除外
      playerRanking.push(tables[tableId].players[playerId])
      tables[tableId].players.splice(playerId, 1);

endCheck = () ->
  playerCount = 0
  for tableId, table of tables
    playerCount += table.players.length
    message = '' + table.players[0].name
  if playerCount <= 1
    tables[tableId].state = 'end'
    return (message + ' won the game')
  return false


module.exports = {
  join: join,
  getInfo: getInfo,
  gameStart: gameStart,
  getState: getState,
  getTableInfo: getTableInfo,
  getSpectatorTableInfo: getSpectatorTableInfo,
  getTableInfoForWebSocketter: getTableInfoForWebSocketter,
  getActionPlayer: getActionPlayer,
  action: action,
  goToNextTurn: goToNextTurn,
  goToNextPhase: goToNextPhase,
  goToNextHand: goToNextHand,
  showDown: showDown,
  playerSitOut: playerSitOut,
  endCheck: endCheck
}

# ここから下はエクスポートしないプライベートメソッド
blindUp = () ->
  level += 1
  setTimeout ->
    blindUp()
  , intervalTime

dealPlayersHands = (tableId) ->
  tables[tableId].deck = [].concat(createDeck())
  playersNum = tables[tableId].playersNum
  sbPosition = tables[tableId].sbPosition
  for handNum in [0...2]
    for i in [0...playersNum]
      cardPosition = Math.floor(Math.random() * tables[tableId].deck.length)
      tables[tableId].players[( (i+sbPosition)%playersNum )].hand[handNum] = tables[tableId].deck[cardPosition]
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
    if tables[tableId].players[checkSeat].isActive == true && tables[tableId].players[checkSeat].isAllIn == false
      return checkSeat
  # 見つからなかったらときは変更なし。
  return nowActionPlayerSeat

getNextCommand = (tableId) ->
  console.log 'getNextCommand called'
  if tables[tableId].activePlayersNum == 1 # プレイヤーが一人だけになったとき（勝負あり）
    return 'nextHand'
  countIsActiveNotAllInPlayers = 0
  activeLastBet = 0
  for playerId, player of tables[tableId].players
    if player.isActive == true && player.isAllIn == false
      countIsActiveNotAllInPlayers += 1
  console.log 'countIsActiveNotAllInPlayers = '+countIsActiveNotAllInPlayers+', tables[tableId].hasActionPlayersNum = '+tables[tableId].hasActionPlayersNum
  if tables[tableId].hasActionPlayersNum == 0 && tables[tableId].state == 'river'
    return 'showDown'
  if tables[tableId].hasActionPlayersNum == 0 && countIsActiveNotAllInPlayers <= 1
    return 'autoNextPhase'
  if tables[tableId].hasActionPlayersNum == 0
    return 'nextPhase'

  return'nextTurn'

addHasActionToActives = (tableId) ->
  console.log 'addHasActionToActives called'
  hasActionCounter = 0
  for playerId, player of tables[tableId].players
    if player.isActive == true && player.isAllIn == false
      tables[tableId].players[playerId].hasAction = true
      hasActionCounter += 1
  tables[tableId].hasActionPlayersNum = hasActionCounter
  console.log 'hasActionCounter = '+hasActionCounter

setPositions = (tableId) ->
  dealerButton = tables[tableId].dealerButton
  if tables[tableId].playersNum == 2
    tables[tableId].sbPosition = dealerButton
    tables[tableId].bbPosition = (dealerButton+1)%tables[tableId].playersNum
  else
    tables[tableId].sbPosition = (dealerButton+1)%tables[tableId].playersNum
    tables[tableId].bbPosition = (dealerButton+2)%tables[tableId].playersNum
  # 手番プレイヤーの設定
  tables[tableId].actionPlayerSeat = (tables[tableId].bbPosition+1)%tables[tableId].playersNum

setSbBbChips = (tableId) ->
  bbAmount = structure[level]
  sbAmount = Number(bbAmount/2)
  sbPosition = tables[tableId].sbPosition
  bbPosition = tables[tableId].bbPosition
  # SBのオールインチェック
  if sbAmount >= tables[tableId].players[sbPosition].stack
    # 以下オールイン処理をしてくださいフラグの作成
    betAmount = tables[tableId].players[sbPosition].stack
    tables[tableId].players[sbPosition].isAllIn = true
    takenAction = 'CallAllIn'
    tables[tableId].allInCalcFlags[tables[tableId].allInCalcFlags.length] = {
      playerSeat: sbPosition,
      lastBet: betAmount
    }
    tables[tableId].players[sbPosition].lastAction = takenAction
    tables[tableId].bettingTotal += betAmount
    tables[tableId].players[sbPosition].stack = 0
    tables[tableId].players[sbPosition].lastBet = betAmount
    tables[tableId].players[sbPosition].hasAction = false
    tables[tableId].hasActionPlayersNum -= 1
  else
    tables[tableId].bettingTotal += sbAmount
    tables[tableId].players[sbPosition].stack -= sbAmount
    tables[tableId].players[sbPosition].lastBet = sbAmount
  # BBのオールインチェック
  if bbAmount >= tables[tableId].players[bbPosition].stack
    # 以下オールイン処理をしてくださいフラグの作成
    betAmount = tables[tableId].players[bbPosition].stack
    tables[tableId].players[bbPosition].isAllIn = true
    takenAction = 'CallAllIn'
    tables[tableId].allInCalcFlags[tables[tableId].allInCalcFlags.length] = {
      playerSeat: bbPosition,
      lastBet: betAmount
    }
    tables[tableId].players[bbPosition].lastAction = takenAction
    tables[tableId].bettingTotal += betAmount
    tables[tableId].players[bbPosition].stack = 0
    tables[tableId].players[bbPosition].lastBet = betAmount
    tables[tableId].players[bbPosition].hasAction = false
    tables[tableId].hasActionPlayersNum -= 1
    tables[tableId].lastBet = betAmount
  else
    tables[tableId].bettingTotal += bbAmount
    tables[tableId].players[bbPosition].stack -= bbAmount
    tables[tableId].players[bbPosition].lastBet = bbAmount
    tables[tableId].lastBet = bbAmount
  tables[tableId].differenceAmount = bbAmount

actionFold = (tableId, actionPlayerSeat) ->
  tables[tableId].players[actionPlayerSeat].lastAction = 'fold'
  tables[tableId].players[actionPlayerSeat].isActive = false
  tables[tableId].players[actionPlayerSeat].hasAction = false
  tables[tableId].activePlayersNum -= 1
  tables[tableId].hasActionPlayersNum -= 1
  console.log 'hasActionPlayersNum decrement called = '+tables[tableId].hasActionPlayersNum
  nextCommand = getNextCommand(tableId) # 次どうするかの指令
  if nextCommand == 'nextHand'
    winPlayerSeat = 0
    for playerSeat, player of tables[tableId].players
      tables[tableId].pot += player.lastBet
      if player.isActive == true
        winPlayerSeat = playerSeat
    tables[tableId].players[winPlayerSeat].stack += tables[tableId].pot
    return {
      status: 'ok',
      message: 'got your action fold.',
      nextCommand: nextCommand,
      sendAllTables:{
        takenAction: 'fold',
        tableInfo: getTableInfo(tableId),
        message: 'got fold. '+tables[tableId].players[winPlayerSeat].name+' takes pot '+tables[tableId].pot,
        nextCommand: nextCommand
      }
    }
  else # まだ勝負は続くとき
    return {
      status: 'ok',
      message: 'got your action fold.',
      nextCommand: nextCommand,
      sendAllTables:{
        takenAction: 'fold',
        tableInfo: getTableInfo(tableId),
        message: 'got fold. pot: '+tables[tableId].pot + ', bettingTotal: '+tables[tableId].bettingTotal,
        nextCommand: nextCommand
      }
    }

actionCheck = (tableId, actionPlayerSeat) ->
  if tables[tableId].lastBet > tables[tableId].players[actionPlayerSeat].lastBet
    return {
      status: 'no',
      message: 'No you cant check.'
    }
  tables[tableId].players[actionPlayerSeat].lastAction = 'check'
  tables[tableId].players[actionPlayerSeat].hasAction = false
  tables[tableId].hasActionPlayersNum -= 1
  console.log 'hasActionPlayersNum decrement called in Check= '+tables[tableId].hasActionPlayersNum
  nextCommand = getNextCommand(tableId) # 次どうするかの指令
  return {
    status: 'ok',
    message: 'got your action check',
    nextCommand: nextCommand,
    sendAllTables:{
      takenAction: 'check',
      tableInfo: getTableInfo(tableId),
      message: 'got check. pot: '+tables[tableId].pot + ', bettingTotal: '+tables[tableId].bettingTotal,
      nextCommand: nextCommand
    }
  }

actionCall = (tableId, actionPlayerSeat) ->
  betAmount = tables[tableId].lastBet - tables[tableId].players[actionPlayerSeat].lastBet
  playerLastBet = tables[tableId].players[actionPlayerSeat].lastBet
  takenAction = 'call'
  if betAmount >= tables[tableId].players[actionPlayerSeat].stack # オールインチェック
    # 以下オールイン処理をしてくださいフラグの作成
    betAmount = tables[tableId].players[actionPlayerSeat].stack
    tables[tableId].players[actionPlayerSeat].isAllIn = true
    takenAction = 'CallAllIn'
    tables[tableId].allInCalcFlags[tables[tableId].allInCalcFlags.length] = {
      playerSeat: actionPlayerSeat,
      lastBet: playerLastBet+betAmount
    }
  tables[tableId].players[actionPlayerSeat].lastAction = takenAction
  tables[tableId].bettingTotal += betAmount
  tables[tableId].players[actionPlayerSeat].stack -= betAmount
  tables[tableId].players[actionPlayerSeat].lastBet = playerLastBet+betAmount
  tables[tableId].players[actionPlayerSeat].hasAction = false
  tables[tableId].hasActionPlayersNum -= 1
  console.log 'hasActionPlayersNum decrement called in Call= '+tables[tableId].hasActionPlayersNum
  nextCommand = getNextCommand(tableId) # 次どうするかの指令
  return {
    status: 'ok',
    message: 'got your action '+takenAction,
    nextCommand: nextCommand,
    sendAllTables:{
      takenAction: takenAction,
      tableInfo: getTableInfo(tableId),
      message: 'got '+takenAction+', pot: '+tables[tableId].pot + ', bettingTotal: '+tables[tableId].bettingTotal,
      nextCommand: nextCommand
    }
  }

actionRaise = (tableId, actionPlayerSeat, amount) ->
  if !amount || amount < tables[tableId].lastBet + tables[tableId].differenceAmount
    amount = tables[tableId].lastBet + tables[tableId].differenceAmount
  #オールインチェック
  callAmount = tables[tableId].lastBet - tables[tableId].players[actionPlayerSeat].lastBet
  if tables[tableId].players[actionPlayerSeat].stack <= callAmount # これはレイズではなくコールですね。
    return actionCall(tableId, actionPlayerSeat)

  takenAction = 'raise'
  addHasActionToActives(tableId)
  tables[tableId].players[actionPlayerSeat].hasAction = false
  tables[tableId].hasActionPlayersNum -= 1
  console.log 'hasActionPlayersNum decrement called in Raise= '+tables[tableId].hasActionPlayersNum
  if tables[tableId].players[actionPlayerSeat].stack <= amount # レイズオールインですね。
    # 以下オールイン処理をしてくださいフラグの作成
    amount = tables[tableId].players[actionPlayerSeat].stack + tables[tableId].players[actionPlayerSeat].lastBet
    tables[tableId].players[actionPlayerSeat].isAllIn = true
    takenAction = 'RaiseAllIn'
    tables[tableId].allInCalcFlags[tables[tableId].allInCalcFlags.length] = {
      playerSeat: actionPlayerSeat,
      lastBet: amount
    }
  tables[tableId].players[actionPlayerSeat].lastAction = takenAction
  betAmount = amount - tables[tableId].players[actionPlayerSeat].lastBet
  tables[tableId].bettingTotal += betAmount
  tables[tableId].players[actionPlayerSeat].stack -= betAmount
  tables[tableId].differenceAmount = amount - tables[tableId].lastBet
  tables[tableId].lastBet = amount
  tables[tableId].players[actionPlayerSeat].lastBet = amount
  nextCommand = getNextCommand(tableId) # 次どうするかの指令
  return {
    status: 'ok',
    message: 'got your action '+takenAction,
    nextCommand: nextCommand,
    sendAllTables:{
      takenAction: takenAction,
      tableInfo: getTableInfo(tableId),
      message: 'got '+takenAction+' '+amount+', pot: '+tables[tableId].pot + ', bettingTotal: '+tables[tableId].bettingTotal,
      nextCommand: nextCommand
    }
  }

actionAutoNextPhase = (tableId) ->
  nextCommand = getNextCommand(tableId) # 次どうするかの指令
  return {
    status: 'ok',
    message: 'AutoNextPhase',
    nextCommand: nextCommand,
    sendAllTables:{
      takenAction: 'AutoNextPhase',
      tableInfo: getTableInfo(tableId),
      message: 'AutoNextPhase, pot: '+tables[tableId].pot,
      nextCommand: nextCommand
    }
  }

allInCalc = (tableId) ->
  allInCalcFlags = sortAllInCalcFlags(tables[tableId].allInCalcFlags)
  collectAmount = 0
  for key, allInCalcFlag of allInCalcFlags
    collectAmount = allInCalcFlag.lastBet - collectAmount
    sidePot = 0
    for playerId, player of tables[tableId].players
      if collectAmount <= player.lastBet
        sidePot += collectAmount
        player.lastBet -= collectAmount
      else # オールイン額よりも少ない額で降りている人もいるため、そのための処理
        sidePot += player.lastBet # 0だったらまぁ0が足される訳で良い
        player.lastBet = 0
    tables[tableId].allInInfo[tables[tableId].allInInfo.length] = {
      playerSeat: allInCalcFlag.playerSeat,
      sidePot: sidePot
    }
  tables[tableId].allInCalcFlags = []

nextPhaseResetOperation = (tableId) ->
  allInCalc(tableId) # オールイン計算
  potCalc(tableId) # ポット計算
  tables[tableId].bettingTotal = 0
  tables[tableId].lastBet = 0
  for i in [1...tables[tableId].players.length]
    targetSeat = (tables[tableId].dealerButton + 1)%tables[tableId].players.length
    if tables[tableId].players[targetSeat].isAllIn == false
      tables[tableId].actionPlayerSeat = targetSeat
      break

potCalc = (tableId) ->
  for playerId, player of tables[tableId].players
    tables[tableId].pot += tables[tableId].players[playerId].lastBet
    tables[tableId].players[playerId].lastBet = 0
    tables[tableId].players[playerId].lastAction = null

createDeck = () ->
  trumps = [
    'As','2s','3s','4s','5s','6s','7s','8s','9s','Ts','Js','Qs','Ks',
    'Ah','2h','3h','4h','5h','6h','7h','8h','9h','Th','Jh','Qh','Kh',
    'Ad','2d','3d','4d','5d','6d','7d','8d','9d','Td','Jd','Qd','Kd',
    'Ac','2c','3c','4c','5c','6c','7c','8c','9c','Tc','Jc','Qc','Kc'
  ]
  return shuffleArray(trumps)

sortAllInCalcFlags = (allInCalcFlags) ->
  newAllInCalcFlags = []
  for key, allInCalcFlag of allInCalcFlags
    if newAllInCalcFlags.length == 0
      newAllInCalcFlags[0] = allInCalcFlag
    else
      for i, newAllInCalcFlag of newAllInCalcFlags
        if allInCalcFlag.lastBet < newAllInCalcFlag.lastBet
          for j in [newAllInCalcFlag.length..i]
            if j == i
              newAllInCalcFlags[j] = new (allInCalcFlag.constructor)()
            else
              newAllInCalcFlags[j] = new (newAllInCalcFlags[j-1].constructor)()
          break
        else if i == newAllInCalcFlags.length-1
          newAllInCalcFlags[newAllInCalcFlags.length] = new (allInCalcFlag.constructor)()
  return newAllInCalcFlags

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
    players[i].id = i
  return players

# ランダム文字列のキーを発行する。
randobet = (n, b) ->
  b = b || ''
  a = 'abcdefghijklmnopqrstuvwxyz' + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' + '0123456789' + b
  a = a.split('')
  s = ''
  for i in [0...n]
    s += a[Math.floor(Math.random() * a.length)]
  return s;