// Generated by CoffeeScript 1.6.2
(function() {
  var Config, WinPer, action, actionAutoNextPhase, actionCall, actionCheck, actionFold, actionRaise, addHasActionToActives, allInCalc, blindUp, createDeck, dealPlayersHands, dealPreFlop, dealRiver, dealTurn, endCheck, findNextActionPlayerSeat, gameStart, getActionPlayer, getInfo, getNextCommand, getSpectatorTableInfo, getState, getTableInfo, getTableInfoForWebSocketter, goToNextHand, goToNextPhase, goToNextTurn, intervalTime, join, level, nextPhaseResetOperation, playerRanking, playerSitOut, playersCount, potCalc, randobet, setPositions, setSbBbChips, showDown, shuffleArray, shufflePlayers, sortAllInCalcFlags, state, structure, tables;

  Config = require('../config');

  WinPer = require('./WinPer');

  tables = {};

  playersCount = 0;

  structure = Config.getStructure();

  intervalTime = Config.getIntervalTime();

  state = 'waiting';

  level = 0;

  playerRanking = [];

  join = function(data, socketId, callback) {
    var key, name, tableId;

    name = data.name;
    tableId = 0;
    if (!name) {
      return callback({
        response: 'fail',
        errorMessage: 'no name here!'
      });
    } else {
      key = randobet(28 + Math.floor(Math.random() * 6), '');
      if (!tables[0] || tables[0].players.length < 10) {
        if (!tables[0]) {
          tables[0] = {};
        }
        if (!tables[0].players) {
          tables[0].players = [];
        }
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
        };
      }
      playersCount += 1;
      return callback({
        response: 'ok',
        key: key
      });
    }
  };

  gameStart = function() {
    var i, stack, table, tableId, _i, _ref;

    level = 0;
    stack = Config.getStack();
    for (tableId in tables) {
      table = tables[tableId];
      table.players = [].concat(shufflePlayers(table.players));
      console.log('shuffled players = ' + table.players);
      table.dealerButton = Math.floor(Math.random() * table.players.length);
      table.playedHandCount = 0;
      table.lastBet = 0;
      table.pot = 0;
      table.bettingTotal = 0;
      table.playersNum = table.players.length;
      table.activePlayersNum = table.players.length;
      table.hasActionPlayersNum = table.players.length;
      table.board = [];
      table.allInCalcFlags = [];
      table.allInInfo = [];
      table.state = 'preFlop';
      for (i = _i = 0, _ref = table.players.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        table.players[i].stack = stack;
        tables[tableId].players[i].isActive = true;
        tables[tableId].players[i].hasAction = true;
        tables[tableId].players[i].isAllIn = false;
        tables[tableId].players[i].lastBet = 0;
        tables[tableId].players[i].lastAction = 0;
      }
      setPositions(tableId);
      setSbBbChips(tableId);
      dealPlayersHands(tableId);
    }
    setTimeout(function() {
      return blindUp();
    }, intervalTime);
    return state = 'gaming';
  };

  getInfo = function() {
    var info, table, tableId;

    info = {
      state: state,
      level: level,
      tables: {}
    };
    for (tableId in tables) {
      table = tables[tableId];
      info.tables[tableId] = {
        pot: table.pot,
        lastBet: table.lastBet,
        dealerButton: table.dealerButton,
        playedHandCount: table.playedHandCount,
        playersNum: table.playersNum,
        activePlayersNum: table.activePlayersNum,
        players: table.players
      };
    }
    return info;
  };

  getState = function() {
    return state;
  };

  getTableInfo = function(tableId) {
    var key, player, tableInfo, _ref;

    if (state === 'waiting') {
      return {};
    }
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
    };
    _ref = tables[tableId].players;
    for (key in _ref) {
      player = _ref[key];
      tableInfo.players[key] = {
        seat: player.seat,
        name: player.name,
        stack: player.stack,
        isActive: player.isActive,
        isAllIn: player.isAllIn,
        lastBet: player.lastBet
      };
    }
    return tableInfo;
  };

  getSpectatorTableInfo = function(tableId) {
    var key, player, spectatorTableInfo, _ref;

    spectatorTableInfo = {};
    if (!tables[tableId]) {
      spectatorTableInfo.state = state;
      spectatorTableInfo.level = 0;
      spectatorTableInfo.board = [];
      return spectatorTableInfo;
    }
    if (tables[tableId].state) {
      spectatorTableInfo.state = tables[tableId].state;
    }
    if (typeof level !== 'undefined') {
      spectatorTableInfo.level = level;
      spectatorTableInfo.bbAmount = structure[level];
    }
    if (typeof tables[tableId].pot !== 'undefined') {
      spectatorTableInfo.pot = tables[tableId].pot;
    }
    if (typeof tables[tableId].bettingTotal !== 'undefined') {
      spectatorTableInfo.bettingTotal = tables[tableId].bettingTotal;
    }
    if (tables[tableId].lastBet) {
      spectatorTableInfo.lastBet = tables[tableId].lastBet;
    }
    spectatorTableInfo.dealerButton = tables[tableId].dealerButton;
    if (tables[tableId].playedHandCount) {
      spectatorTableInfo.playedHandCount = tables[tableId].playedHandCount;
    }
    if (tables[tableId].playersNum) {
      spectatorTableInfo.playersNum = tables[tableId].playersNum;
    }
    if (tables[tableId].activePlayersNum) {
      spectatorTableInfo.activePlayersNum = tables[tableId].activePlayersNum;
    }
    spectatorTableInfo.actionPlayerSeat = tables[tableId].actionPlayerSeat;
    if (tables[tableId].board) {
      spectatorTableInfo.board = tables[tableId].board;
    }
    spectatorTableInfo.players = [];
    _ref = tables[tableId].players;
    for (key in _ref) {
      player = _ref[key];
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
      };
    }
    return spectatorTableInfo;
  };

  getTableInfoForWebSocketter = function(tableId) {
    return tables[tableId];
  };

  getActionPlayer = function(tableId) {
    console.log('tables[tableId].actionPlayerSeat = ' + tables[tableId].actionPlayerSeat);
    console.log('tables[tableId].players[tables[tableId].actionPlayerSeat] = ' + tables[tableId].players[tables[tableId].actionPlayerSeat]);
    return tables[tableId].players[tables[tableId].actionPlayerSeat];
  };

  action = function(data) {
    var actionPlayerSeat, amount, key, tableId;

    key = data.key;
    action = data.action;
    amount = data.amount;
    tableId = 0;
    actionPlayerSeat = tables[tableId].actionPlayerSeat;
    if (key === tables[tableId].players[actionPlayerSeat].key) {
      switch (action) {
        case 'fold':
          return actionFold(tableId, actionPlayerSeat);
        case 'check':
          return actionCheck(tableId, actionPlayerSeat);
        case 'call':
          return actionCall(tableId, actionPlayerSeat);
        case 'raise':
          return actionRaise(tableId, actionPlayerSeat, amount);
        case 'autoNextPhase':
          return actionAutoNextPhase(tableId);
      }
    }
    return 'ignroe';
  };

  goToNextTurn = function(tableId) {
    console.log('goToNextTurn called.');
    return tables[tableId].actionPlayerSeat = findNextActionPlayerSeat(tableId);
  };

  goToNextPhase = function(tableId) {
    nextPhaseResetOperation(tableId);
    switch (tables[tableId].state) {
      case 'preFlop':
        dealPreFlop(tableId);
        tables[tableId].state = 'flop';
        break;
      case 'flop':
        dealTurn(tableId);
        tables[tableId].state = 'turn';
        break;
      case 'turn':
        dealRiver(tableId);
        tables[tableId].state = 'river';
    }
    addHasActionToActives(tableId);
    tables[tableId].actionPlayerSeat = tables[tableId].dealerButton;
    return tables[tableId].actionPlayerSeat = findNextActionPlayerSeat(tableId);
  };

  goToNextHand = function(tableId) {
    var player, playerId, _ref;

    console.log('goToNextHand called.');
    tables[tableId].dealerButton = (tables[tableId].dealerButton + 1) % tables[tableId].players.length;
    tables[tableId].playedHandCount += 1;
    tables[tableId].lastBet = 0;
    tables[tableId].pot = 0;
    tables[tableId].bettingTotal = 0;
    tables[tableId].playersNum = tables[tableId].players.length;
    tables[tableId].activePlayersNum = tables[tableId].players.length;
    tables[tableId].hasActionPlayersNum = tables[tableId].players.length;
    tables[tableId].board = [];
    tables[tableId].allInCalcFlags = [];
    tables[tableId].allInInfo = [];
    tables[tableId].state = 'preFlop';
    _ref = tables[tableId].players;
    for (playerId in _ref) {
      player = _ref[playerId];
      tables[tableId].players[playerId].isActive = true;
      tables[tableId].players[playerId].hasAction = true;
      tables[tableId].players[playerId].isAllIn = false;
      tables[tableId].players[playerId].lastBet = 0;
      tables[tableId].players[playerId].lastAction = null;
    }
    setPositions(tableId);
    setSbBbChips(tableId);
    return dealPlayersHands(tableId);
  };

  showDown = function(tableId) {
    var allInInfo, dividedPot, i, key, message, messages, objForWinPer, player, playerId, targetPlayerId, value, winPlayers, winPlayersNum, _i, _ref, _ref1;

    nextPhaseResetOperation(tableId);
    messages = [];
    objForWinPer = {
      board: tables[tableId].board,
      players: []
    };
    _ref = tables[tableId].players;
    for (playerId in _ref) {
      player = _ref[playerId];
      if (player.isActive === true && player.isAllIn === false) {
        objForWinPer.players[objForWinPer.players.length] = player;
      }
    }
    WinPer.getPlayersPointAndKicker(objForWinPer);
    winPlayers = WinPer.getWinPlayer(objForWinPer);
    winPlayersNum = winPlayers.length;
    dividedPot = Math.floor(tables[tableId].pot / winPlayersNum);
    message = '';
    for (key in winPlayers) {
      value = winPlayers[key];
      targetPlayerId = winPlayers[key].id;
      tables[tableId].players[targetPlayerId].stack += dividedPot;
      message += ' ' + tables[tableId].players[targetPlayerId].name;
    }
    message += ' won the pot: ' + dividedPot;
    messages[messages.length] = message;
    if (!tables[tableId].allInInfo || tables[tableId].allInInfo.length <= 0) {
      return messages;
    }
    for (i = _i = _ref1 = tables[tableId].allInInfo.length - 1; _ref1 <= 0 ? _i <= 0 : _i >= 0; i = _ref1 <= 0 ? ++_i : --_i) {
      allInInfo = tables[tableId].allInInfo[i];
      objForWinPer.players = winPlayers;
      objForWinPer.players[objForWinPer.players.length] = tables[tableId].players[allInInfo.playerSeat];
      WinPer.getPlayersPointAndKicker(objForWinPer);
      winPlayers = WinPer.getWinPlayer(objForWinPer);
      winPlayersNum = winPlayers.length;
      dividedPot = Math.floor(allInInfo.sidePot / winPlayersNum);
      message = '';
      for (key in winPlayers) {
        value = winPlayers[key];
        targetPlayerId = winPlayers[key].id;
        tables[tableId].players[targetPlayerId].stack += dividedPot;
        message += ' ' + tables[tableId].players[targetPlayerId].name;
      }
      message += ' won the pot: ' + dividedPot;
      messages[messages.length] = message;
    }
    return messages;
  };

  playerSitOut = function(tableId) {
    var player, playerId, _ref, _results;

    _ref = tables[tableId].players;
    _results = [];
    for (playerId in _ref) {
      player = _ref[playerId];
      if (player.stack === 0) {
        playerRanking.push(tables[tableId].players[playerId]);
        _results.push(tables[tableId].players.splice(playerId, 1));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  endCheck = function() {
    var message, playerCount, table, tableId;

    playerCount = 0;
    for (tableId in tables) {
      table = tables[tableId];
      playerCount += table.players.length;
      message = '' + table.players[0].name;
    }
    if (playerCount <= 1) {
      tables[tableId].state = 'end';
      return message + ' won the game';
    }
    return false;
  };

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
  };

  blindUp = function() {
    level += 1;
    return setTimeout(function() {
      return blindUp();
    }, intervalTime);
  };

  dealPlayersHands = function(tableId) {
    var cardPosition, handNum, i, playersNum, sbPosition, _i, _results;

    tables[tableId].deck = [].concat(createDeck());
    playersNum = tables[tableId].playersNum;
    sbPosition = tables[tableId].sbPosition;
    _results = [];
    for (handNum = _i = 0; _i < 2; handNum = ++_i) {
      _results.push((function() {
        var _j, _results1;

        _results1 = [];
        for (i = _j = 0; 0 <= playersNum ? _j < playersNum : _j > playersNum; i = 0 <= playersNum ? ++_j : --_j) {
          cardPosition = Math.floor(Math.random() * tables[tableId].deck.length);
          tables[tableId].players[(i + sbPosition) % playersNum].hand[handNum] = tables[tableId].deck[cardPosition];
          _results1.push(tables[tableId].deck.splice(cardPosition, 1));
        }
        return _results1;
      })());
    }
    return _results;
  };

  dealPreFlop = function(tableId) {
    var cardPosition, i, _i, _results;

    _results = [];
    for (i = _i = 0; _i < 3; i = ++_i) {
      cardPosition = Math.floor(Math.random() * tables[tableId].deck.length);
      tables[tableId].board[i] = tables[tableId].deck[cardPosition];
      _results.push(tables[tableId].deck.splice(cardPosition, 1));
    }
    return _results;
  };

  dealTurn = function(tableId) {
    var cardPosition;

    cardPosition = Math.floor(Math.random() * tables[tableId].deck.length);
    tables[tableId].board[3] = tables[tableId].deck[cardPosition];
    return tables[tableId].deck.splice(cardPosition, 1);
  };

  dealRiver = function(tableId) {
    var cardPosition;

    cardPosition = Math.floor(Math.random() * tables[tableId].deck.length);
    tables[tableId].board[4] = tables[tableId].deck[cardPosition];
    return tables[tableId].deck.splice(cardPosition, 1);
  };

  findNextActionPlayerSeat = function(tableId) {
    var checkSeat, i, nowActionPlayerSeat, _i, _ref;

    nowActionPlayerSeat = tables[tableId].actionPlayerSeat;
    for (i = _i = 1, _ref = tables[tableId].players.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
      checkSeat = (nowActionPlayerSeat + i) % tables[tableId].players.length;
      if (tables[tableId].players[checkSeat].isActive === true && tables[tableId].players[checkSeat].isAllIn === false) {
        return checkSeat;
      }
    }
    return nowActionPlayerSeat;
  };

  getNextCommand = function(tableId) {
    var activeLastBet, countIsActiveNotAllInPlayers, player, playerId, _ref;

    console.log('getNextCommand called');
    if (tables[tableId].activePlayersNum === 1) {
      return 'nextHand';
    }
    countIsActiveNotAllInPlayers = 0;
    activeLastBet = 0;
    _ref = tables[tableId].players;
    for (playerId in _ref) {
      player = _ref[playerId];
      if (player.isActive === true && player.isAllIn === false) {
        countIsActiveNotAllInPlayers += 1;
      }
    }
    console.log('countIsActiveNotAllInPlayers = ' + countIsActiveNotAllInPlayers + ', tables[tableId].hasActionPlayersNum = ' + tables[tableId].hasActionPlayersNum);
    if (tables[tableId].hasActionPlayersNum === 0 && tables[tableId].state === 'river') {
      return 'showDown';
    }
    if (tables[tableId].hasActionPlayersNum === 0 && countIsActiveNotAllInPlayers <= 1) {
      return 'autoNextPhase';
    }
    if (tables[tableId].hasActionPlayersNum === 0) {
      return 'nextPhase';
    }
    return 'nextTurn';
  };

  addHasActionToActives = function(tableId) {
    var hasActionCounter, player, playerId, _ref;

    console.log('addHasActionToActives called');
    hasActionCounter = 0;
    _ref = tables[tableId].players;
    for (playerId in _ref) {
      player = _ref[playerId];
      if (player.isActive === true && player.isAllIn === false) {
        tables[tableId].players[playerId].hasAction = true;
        hasActionCounter += 1;
      }
    }
    tables[tableId].hasActionPlayersNum = hasActionCounter;
    return console.log('hasActionCounter = ' + hasActionCounter);
  };

  setPositions = function(tableId) {
    var dealerButton;

    dealerButton = tables[tableId].dealerButton;
    if (tables[tableId].playersNum === 2) {
      tables[tableId].sbPosition = dealerButton;
      tables[tableId].bbPosition = (dealerButton + 1) % tables[tableId].playersNum;
    } else {
      tables[tableId].sbPosition = (dealerButton + 1) % tables[tableId].playersNum;
      tables[tableId].bbPosition = (dealerButton + 2) % tables[tableId].playersNum;
    }
    return tables[tableId].actionPlayerSeat = (tables[tableId].bbPosition + 1) % tables[tableId].playersNum;
  };

  setSbBbChips = function(tableId) {
    var bbAmount, bbPosition, betAmount, sbAmount, sbPosition, takenAction;

    bbAmount = structure[level];
    sbAmount = Number(bbAmount / 2);
    sbPosition = tables[tableId].sbPosition;
    bbPosition = tables[tableId].bbPosition;
    if (sbAmount >= tables[tableId].players[sbPosition].stack) {
      betAmount = tables[tableId].players[sbPosition].stack;
      tables[tableId].players[sbPosition].isAllIn = true;
      takenAction = 'CallAllIn';
      tables[tableId].allInCalcFlags[tables[tableId].allInCalcFlags.length] = {
        playerSeat: sbPosition,
        lastBet: betAmount
      };
      tables[tableId].players[sbPosition].lastAction = takenAction;
      tables[tableId].bettingTotal += betAmount;
      tables[tableId].players[sbPosition].stack = 0;
      tables[tableId].players[sbPosition].lastBet = betAmount;
      tables[tableId].players[sbPosition].hasAction = false;
      tables[tableId].hasActionPlayersNum -= 1;
    } else {
      tables[tableId].bettingTotal += sbAmount;
      tables[tableId].players[sbPosition].stack -= sbAmount;
      tables[tableId].players[sbPosition].lastBet = sbAmount;
    }
    if (bbAmount >= tables[tableId].players[bbPosition].stack) {
      betAmount = tables[tableId].players[bbPosition].stack;
      tables[tableId].players[bbPosition].isAllIn = true;
      takenAction = 'CallAllIn';
      tables[tableId].allInCalcFlags[tables[tableId].allInCalcFlags.length] = {
        playerSeat: bbPosition,
        lastBet: betAmount
      };
      tables[tableId].players[bbPosition].lastAction = takenAction;
      tables[tableId].bettingTotal += betAmount;
      tables[tableId].players[bbPosition].stack = 0;
      tables[tableId].players[bbPosition].lastBet = betAmount;
      tables[tableId].players[bbPosition].hasAction = false;
      tables[tableId].hasActionPlayersNum -= 1;
      tables[tableId].lastBet = betAmount;
    } else {
      tables[tableId].bettingTotal += bbAmount;
      tables[tableId].players[bbPosition].stack -= bbAmount;
      tables[tableId].players[bbPosition].lastBet = bbAmount;
      tables[tableId].lastBet = bbAmount;
    }
    return tables[tableId].differenceAmount = bbAmount;
  };

  actionFold = function(tableId, actionPlayerSeat) {
    var nextCommand, player, playerSeat, winPlayerSeat, _ref;

    tables[tableId].players[actionPlayerSeat].lastAction = 'fold';
    tables[tableId].players[actionPlayerSeat].isActive = false;
    tables[tableId].players[actionPlayerSeat].hasAction = false;
    tables[tableId].activePlayersNum -= 1;
    tables[tableId].hasActionPlayersNum -= 1;
    console.log('hasActionPlayersNum decrement called = ' + tables[tableId].hasActionPlayersNum);
    nextCommand = getNextCommand(tableId);
    if (nextCommand === 'nextHand') {
      winPlayerSeat = 0;
      _ref = tables[tableId].players;
      for (playerSeat in _ref) {
        player = _ref[playerSeat];
        tables[tableId].pot += player.lastBet;
        if (player.isActive === true) {
          winPlayerSeat = playerSeat;
        }
      }
      tables[tableId].players[winPlayerSeat].stack += tables[tableId].pot;
      return {
        status: 'ok',
        message: 'got your action fold.',
        nextCommand: nextCommand,
        sendAllTables: {
          takenAction: 'fold',
          tableInfo: getTableInfo(tableId),
          message: 'got fold. ' + tables[tableId].players[winPlayerSeat].name + ' takes pot ' + tables[tableId].pot,
          nextCommand: nextCommand
        }
      };
    } else {
      return {
        status: 'ok',
        message: 'got your action fold.',
        nextCommand: nextCommand,
        sendAllTables: {
          takenAction: 'fold',
          tableInfo: getTableInfo(tableId),
          message: 'got fold. pot: ' + tables[tableId].pot + ', bettingTotal: ' + tables[tableId].bettingTotal,
          nextCommand: nextCommand
        }
      };
    }
  };

  actionCheck = function(tableId, actionPlayerSeat) {
    var nextCommand;

    if (tables[tableId].lastBet > tables[tableId].players[actionPlayerSeat].lastBet) {
      return {
        status: 'no',
        message: 'No you cant check.'
      };
    }
    tables[tableId].players[actionPlayerSeat].lastAction = 'check';
    tables[tableId].players[actionPlayerSeat].hasAction = false;
    tables[tableId].hasActionPlayersNum -= 1;
    console.log('hasActionPlayersNum decrement called in Check= ' + tables[tableId].hasActionPlayersNum);
    nextCommand = getNextCommand(tableId);
    return {
      status: 'ok',
      message: 'got your action check',
      nextCommand: nextCommand,
      sendAllTables: {
        takenAction: 'check',
        tableInfo: getTableInfo(tableId),
        message: 'got check. pot: ' + tables[tableId].pot + ', bettingTotal: ' + tables[tableId].bettingTotal,
        nextCommand: nextCommand
      }
    };
  };

  actionCall = function(tableId, actionPlayerSeat) {
    var betAmount, nextCommand, playerLastBet, takenAction;

    betAmount = tables[tableId].lastBet - tables[tableId].players[actionPlayerSeat].lastBet;
    playerLastBet = tables[tableId].players[actionPlayerSeat].lastBet;
    takenAction = 'call';
    if (betAmount >= tables[tableId].players[actionPlayerSeat].stack) {
      betAmount = tables[tableId].players[actionPlayerSeat].stack;
      tables[tableId].players[actionPlayerSeat].isAllIn = true;
      takenAction = 'CallAllIn';
      tables[tableId].allInCalcFlags[tables[tableId].allInCalcFlags.length] = {
        playerSeat: actionPlayerSeat,
        lastBet: playerLastBet + betAmount
      };
    }
    tables[tableId].players[actionPlayerSeat].lastAction = takenAction;
    tables[tableId].bettingTotal += betAmount;
    tables[tableId].players[actionPlayerSeat].stack -= betAmount;
    tables[tableId].players[actionPlayerSeat].lastBet = playerLastBet + betAmount;
    tables[tableId].players[actionPlayerSeat].hasAction = false;
    tables[tableId].hasActionPlayersNum -= 1;
    console.log('hasActionPlayersNum decrement called in Call= ' + tables[tableId].hasActionPlayersNum);
    nextCommand = getNextCommand(tableId);
    return {
      status: 'ok',
      message: 'got your action ' + takenAction,
      nextCommand: nextCommand,
      sendAllTables: {
        takenAction: takenAction,
        tableInfo: getTableInfo(tableId),
        message: 'got ' + takenAction + ', pot: ' + tables[tableId].pot + ', bettingTotal: ' + tables[tableId].bettingTotal,
        nextCommand: nextCommand
      }
    };
  };

  actionRaise = function(tableId, actionPlayerSeat, amount) {
    var betAmount, callAmount, nextCommand, takenAction;

    if (!amount || amount < tables[tableId].lastBet + tables[tableId].differenceAmount) {
      amount = tables[tableId].lastBet + tables[tableId].differenceAmount;
    }
    callAmount = tables[tableId].lastBet - tables[tableId].players[actionPlayerSeat].lastBet;
    if (tables[tableId].players[actionPlayerSeat].stack <= callAmount) {
      return actionCall(tableId, actionPlayerSeat);
    }
    takenAction = 'raise';
    addHasActionToActives(tableId);
    tables[tableId].players[actionPlayerSeat].hasAction = false;
    tables[tableId].hasActionPlayersNum -= 1;
    console.log('hasActionPlayersNum decrement called in Raise= ' + tables[tableId].hasActionPlayersNum);
    if (tables[tableId].players[actionPlayerSeat].stack <= amount) {
      amount = tables[tableId].players[actionPlayerSeat].stack + tables[tableId].players[actionPlayerSeat].lastBet;
      tables[tableId].players[actionPlayerSeat].isAllIn = true;
      takenAction = 'RaiseAllIn';
      tables[tableId].allInCalcFlags[tables[tableId].allInCalcFlags.length] = {
        playerSeat: actionPlayerSeat,
        lastBet: amount
      };
    }
    tables[tableId].players[actionPlayerSeat].lastAction = takenAction;
    betAmount = amount - tables[tableId].players[actionPlayerSeat].lastBet;
    tables[tableId].bettingTotal += betAmount;
    tables[tableId].players[actionPlayerSeat].stack -= betAmount;
    tables[tableId].differenceAmount = amount - tables[tableId].lastBet;
    tables[tableId].lastBet = amount;
    tables[tableId].players[actionPlayerSeat].lastBet = amount;
    nextCommand = getNextCommand(tableId);
    return {
      status: 'ok',
      message: 'got your action ' + takenAction,
      nextCommand: nextCommand,
      sendAllTables: {
        takenAction: takenAction,
        tableInfo: getTableInfo(tableId),
        message: 'got ' + takenAction + ' ' + amount + ', pot: ' + tables[tableId].pot + ', bettingTotal: ' + tables[tableId].bettingTotal,
        nextCommand: nextCommand
      }
    };
  };

  actionAutoNextPhase = function(tableId) {
    var nextCommand;

    nextCommand = getNextCommand(tableId);
    return {
      status: 'ok',
      message: 'AutoNextPhase',
      nextCommand: nextCommand,
      sendAllTables: {
        takenAction: 'AutoNextPhase',
        tableInfo: getTableInfo(tableId),
        message: 'AutoNextPhase, pot: ' + tables[tableId].pot,
        nextCommand: nextCommand
      }
    };
  };

  allInCalc = function(tableId) {
    var allInCalcFlag, allInCalcFlags, collectAmount, key, player, playerId, sidePot, _ref;

    allInCalcFlags = sortAllInCalcFlags(tables[tableId].allInCalcFlags);
    collectAmount = 0;
    for (key in allInCalcFlags) {
      allInCalcFlag = allInCalcFlags[key];
      collectAmount = allInCalcFlag.lastBet - collectAmount;
      sidePot = 0;
      _ref = tables[tableId].players;
      for (playerId in _ref) {
        player = _ref[playerId];
        if (collectAmount <= player.lastBet) {
          sidePot += collectAmount;
          player.lastBet -= collectAmount;
        } else {
          sidePot += player.lastBet;
          player.lastBet = 0;
        }
      }
      tables[tableId].allInInfo[tables[tableId].allInInfo.length] = {
        playerSeat: allInCalcFlag.playerSeat,
        sidePot: sidePot
      };
    }
    return tables[tableId].allInCalcFlags = [];
  };

  nextPhaseResetOperation = function(tableId) {
    var i, targetSeat, _i, _ref, _results;

    allInCalc(tableId);
    potCalc(tableId);
    tables[tableId].bettingTotal = 0;
    tables[tableId].lastBet = 0;
    _results = [];
    for (i = _i = 1, _ref = tables[tableId].players.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
      targetSeat = (tables[tableId].dealerButton + 1) % tables[tableId].players.length;
      if (tables[tableId].players[targetSeat].isAllIn === false) {
        tables[tableId].actionPlayerSeat = targetSeat;
        break;
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  potCalc = function(tableId) {
    var player, playerId, _ref, _results;

    _ref = tables[tableId].players;
    _results = [];
    for (playerId in _ref) {
      player = _ref[playerId];
      tables[tableId].pot += tables[tableId].players[playerId].lastBet;
      tables[tableId].players[playerId].lastBet = 0;
      _results.push(tables[tableId].players[playerId].lastAction = null);
    }
    return _results;
  };

  createDeck = function() {
    var trumps;

    trumps = ['As', '2s', '3s', '4s', '5s', '6s', '7s', '8s', '9s', 'Ts', 'Js', 'Qs', 'Ks', 'Ah', '2h', '3h', '4h', '5h', '6h', '7h', '8h', '9h', 'Th', 'Jh', 'Qh', 'Kh', 'Ad', '2d', '3d', '4d', '5d', '6d', '7d', '8d', '9d', 'Td', 'Jd', 'Qd', 'Kd', 'Ac', '2c', '3c', '4c', '5c', '6c', '7c', '8c', '9c', 'Tc', 'Jc', 'Qc', 'Kc'];
    return shuffleArray(trumps);
  };

  sortAllInCalcFlags = function(allInCalcFlags) {
    var allInCalcFlag, i, j, key, newAllInCalcFlag, newAllInCalcFlags, _i, _ref;

    newAllInCalcFlags = [];
    for (key in allInCalcFlags) {
      allInCalcFlag = allInCalcFlags[key];
      if (newAllInCalcFlags.length === 0) {
        newAllInCalcFlags[0] = allInCalcFlag;
      } else {
        for (i in newAllInCalcFlags) {
          newAllInCalcFlag = newAllInCalcFlags[i];
          if (allInCalcFlag.lastBet < newAllInCalcFlag.lastBet) {
            for (j = _i = _ref = newAllInCalcFlag.length; _ref <= i ? _i <= i : _i >= i; j = _ref <= i ? ++_i : --_i) {
              if (j === i) {
                newAllInCalcFlags[j] = new allInCalcFlag.constructor();
              } else {
                newAllInCalcFlags[j] = new newAllInCalcFlags[j - 1].constructor();
              }
            }
            break;
          } else if (i === newAllInCalcFlags.length - 1) {
            newAllInCalcFlags[newAllInCalcFlags.length] = new allInCalcFlag.constructor();
          }
        }
      }
    }
    return newAllInCalcFlags;
  };

  shuffleArray = function(targetArray) {
    var i, j, length, t, _i, _j, _len, _ref, _results;

    length = targetArray.length;
    _ref = (function() {
      _results = [];
      for (var _j = 0; 0 <= length ? _j < length : _j > length; 0 <= length ? _j++ : _j--){ _results.push(_j); }
      return _results;
    }).apply(this) in targetArray;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      i = _ref[_i];
      j = Math.floor(Math.random() * length);
      t = targetArray[i];
      targetArray[i] = targetArray[j];
      targetArray[j] = t;
    }
    return targetArray;
  };

  shufflePlayers = function(players) {
    var i, j, length, t, _i, _j, _len, _ref, _results;

    length = players.length;
    _ref = (function() {
      _results = [];
      for (var _j = 0; 0 <= length ? _j < length : _j > length; 0 <= length ? _j++ : _j--){ _results.push(_j); }
      return _results;
    }).apply(this) in players;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      i = _ref[_i];
      j = Math.floor(Math.random() * length);
      t = new players[i].constructor();
      players[i] = new players[j].constructor();
      players[j] = new t.constructor();
      players[i].id = i;
    }
    return players;
  };

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
