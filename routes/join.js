var controller = require('../modules/controller');

exports.list = function(req, res){
	res.set('Content-Type', 'application/json');
	var name = req.body.name;
	if (!name) {
		res.json(
			{
				status: 'fail',
				errorMessage: 'no name here!'
			}
		);
	} else {
		var key = randobet(28+Math.floor(Math.random() * 6), '');
		res.json(
			{
				status: 'ok',
				key: key,
				message: 'Your name is '+name
			}
		);
		controller.join(name, key);
	}
};

// ランダム文字列のキーを発行する。
var randobet = function(n, b) {
	b = b || '';
	var a = 'abcdefghijklmnopqrstuvwxyz' +
		'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
		'0123456789' +
		b;
	a = a.split('');
	var s = '';
	for (var i = 0; i < n; i++) {
		s += a[Math.floor(Math.random() * a.length)];
	}
	return s;
};
