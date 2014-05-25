// Generated by CoffeeScript 1.6.2
(function() {
  var config, createCanvas, drawSpectatorData, imageName, images, loadingMovie, movieCounter, prepareForGames, setColorAndFont;

  config = {
    canvasWidth: 1000,
    canvasHeight: 600,
    cardWidth: 48,
    cardHeight: 64,
    state: 'loading',
    mouseListener: false,
    clockTime: false
  };

  imageName = ['Tranp.png'];

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
      config.state = "ready";
      return console.log('ready!');
    };
  };

  drawSpectatorData = function(data) {
    return console.log('通信できたー！！');
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

  setColorAndFont = function(color, size) {
    config.ctx.fillStyle = color;
    return config.ctx.font = size + "px \'Times New Roman\'";
  };

}).call(this);