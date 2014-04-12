var controller = require('../modules/controller');

exports.list = function(req, res){
	res.set('Content-Type', 'application/json');
	res.json(controller.getInfo());
};