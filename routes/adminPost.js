var controller = require('../modules/controller');

exports.list = function(req, res){
	res.set('Content-Type', 'application/json');
	var status = 'ok';
	switch (req.body.command) {
		case 'gameStart': controller.gameStart(); break;
		default : status = 'fail'; break;
	}

	res.json(
		{
			status: status,
			message: 'got command ' + req.body.command
		}
	);
};