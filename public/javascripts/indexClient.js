// Generated by CoffeeScript 1.6.2
(function() {
  var cardToCardNum, config, createCanvas, drawSpectatorData, drawcard, dummyTableInfo, imageName, images, loadingMovie, movieCounter, prepareForGames, setColorAndFont;

  config = {
    canvasWidth: 1000,
    canvasHeight: 600,
    cardWidth: 48,
    cardHeight: 64,
    state: 'loading',
    mouseListener: false,
    clockTime: false
  };

  imageName = ['Tranp.png', 'bg1.png'];

  images = {};

  prepareForGames = function() {
    var checkLoad, i, image, loaded, loadedCount, socket, _i, _ref;

    socket = io.connect('http://' + host + ':' + port + '/spectator');
    socket.on('spectatorData', function(data) {
      config.state = 'drawing';
      return drawSpectatorData(data);
    });
    checkLoad = function() {
      loadedCount += 1;
      if (loadedCount === imageName.length) {
        return loaded();
      }
    };
    loadedCount = 0;
    for (i = _i = 0, _ref = imageName.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      image = document.createElement("img");
      image.src = "/images/" + imageName[i];
      image.onload = function() {
        return checkLoad();
      };
      images[imageName[i]] = image;
    }
    return loaded = function() {
      return config.state = "ready";
    };
  };

  drawSpectatorData = function(data) {
    var drawX, drawY, player, playerId, _ref, _results;

    data = dummyTableInfo(10, ['As', 'Jd', '2h', '5h', '3c']);
    config.ctx.clearRect(0, 0, config.canvasWidth, config.canvasHeight);
    config.ctx.drawImage(images['bg1.png'], 0, 0);
    _ref = data.players;
    _results = [];
    for (playerId in _ref) {
      player = _ref[playerId];
      drawX = playerId * config.cardWidth * 2;
      drawY = 200;
      console.log(player.hand[0]);
      drawcard(cardToCardNum(player.hand[0]), drawX, drawY);
      drawX += config.cardWidth;
      _results.push(drawcard(cardToCardNum(player.hand[1]), drawX, drawY));
    }
    return _results;
  };

  movieCounter = 0;

  loadingMovie = function() {
    var i, loadingText, _i;

    if (config.state === 'loading') {
      setTimeout((function() {
        return loadingMovie();
      }), 50);
      config.ctx.clearRect(0, 0, config.canvasWidth, config.canvasHeight);
      config.ctx.fillStyle = "silver";
      config.ctx.font = "26px \'Times New Roman\'";
      loadingText = 'Loading';
      for (i = _i = 0; 0 <= movieCounter ? _i <= movieCounter : _i >= movieCounter; i = 0 <= movieCounter ? ++_i : --_i) {
        loadingText += '.';
      }
      config.ctx.fillText(loadingText, 100, 300);
      movieCounter++;
      if (movieCounter > 5) {
        return movieCounter = 0;
      }
    }
  };

  createCanvas = function() {
    var canvas, page;

    page = "<canvas id='canvas' width='" + config.canvasWidth + "' height='" + config.canvasHeight + "'> </canvas>";
    $('#tableDiv').html(page);
    canvas = $('#canvas').get(0);
    canvas.width = config.canvasWidth;
    canvas.height = config.canvasHeight;
    config.ctx = canvas.getContext("2d");
    return loadingMovie();
  };

  $(document).ready(function() {
    createCanvas();
    return prepareForGames();
  });

  drawcard = function(cardnum, x, y) {
    var cardmany, cutx, cuty;

    cardmany = 10;
    cutx = (cardnum % cardmany) * config.cardWidth;
    cuty = ((cardnum / cardmany) | 0) * config.cardHeight;
    return config.ctx.drawImage(images["Tranp.png"], cutx, cuty, config.cardWidth, config.cardHeight, x, y, config.cardWidth, config.cardHeight);
  };

  dummyTableInfo = function(playersNum, board) {
    var playerId, tableInfo, _i;

    tableInfo = {
      board: board,
      players: []
    };
    for (playerId = _i = 0; 0 <= playersNum ? _i < playersNum : _i > playersNum; playerId = 0 <= playersNum ? ++_i : --_i) {
      tableInfo.players[playerId] = {
        playerId: playerId,
        name: 'dummy' + playerId,
        hand: ['Ks', 'Ah'],
        stack: 15000,
        lastBet: 3500
      };
    }
    return tableInfo;
  };

  cardToCardNum = function(card) {
    var cardNum;

    switch (card.charAt(1)) {
      case 's':
        cardNum = 0;
        break;
      case 'c':
        cardNum = 13;
        break;
      case 'd':
        cardNum = 26;
        break;
      case 'h':
        cardNum = 39;
        break;
      default:
        return 53;
    }
    switch (card.charAt(0)) {
      case 'A':
        cardNum += 0;
        break;
      case 'K':
        cardNum += 12;
        break;
      case 'Q':
        cardNum += 11;
        break;
      case 'J':
        cardNum += 10;
        break;
      case 'T':
        cardNum += 9;
        break;
      default:
        cardNum += Number(card.charAt(0)) - 1;
    }
    return cardNum;
  };

  setColorAndFont = function(color, size) {
    config.ctx.fillStyle = color;
    return config.ctx.font = size + "px \'Times New Roman\'";
  };

}).call(this);
