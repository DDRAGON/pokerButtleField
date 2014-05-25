var structure = [100, 150, 200, 300, 400, 600, 800, 1000, 1200, 1600, 2000, 2400, 3000, 4000, 6000, 8000, 10000, 12000, 15000, 20000, 30000, 50000];
var stack = 300;
var thisHostAddress = '127.0.0.1';
var redisAddress    = '127.0.0.1';
var spectatorPort   = 3000;
var redisPort       = 6379;
var intervalTime = 5*60*1000;
var sendSpectatorDataTimeOut = 300

module.exports = {
	getStructure: function(){ return structure; },
	getStack: function(){ return stack; },
	getThisHostAddress: function(){ return thisHostAddress; },
	getRedisAddress: function(){ return redisAddress; },
	getSpectatorPort: function(){ return spectatorPort; },
	getRedisPort: function(){ return redisPort; },
	getIntervalTime: function(){ return intervalTime; },
	getSendSpectatorDataTimeOut: function(){ return sendSpectatorDataTimeOut; }
};