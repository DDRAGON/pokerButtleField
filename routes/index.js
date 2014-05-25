var Config = require('../config');

exports.index = function(req, res){
	var port = Config.getSpectatorPort();
	var host = Config.getThisHostAddress();
	res.render('index', { title: 'Express', port: port, host: host});
};