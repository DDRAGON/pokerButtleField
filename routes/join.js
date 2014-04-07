var controller = require('../modules/controller');

exports.list = function(req, res){
	res.json(
		{
			status: 200,
			message: 'Is Your name '+req.body.name+'?',
			code: 200
		}
	);
	controller.join();
	res.send('Is Your name '+req.body.name+'?');
};