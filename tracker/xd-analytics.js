"use strict";
/* jshint browser: true */
/*global console: false */
/*global DDP: false */
/*global CryptoJS: false */

/**
 * Creates an XDAnalytics objects and starts tracking.
 * @param {[type]} config contains server, port, appId, apiKey, debug
 */
window.XDAnalytics = function(config, userId) {

	if (config.debug) {
		console.log(config);
	}

	var self = this;

	// Methods

	this.createLog = function() {
		var log = {
			type: "log",
			loggedAt: new Date(),
			location: window.location.hash,
			device: {
				id: self.deviceId,
				sessionId: self.sessionId,
				noStorage: self.noStorage,
				width: screen.width,
				height: screen.height,
				pixelRatio: window.devicePixelRatio || window.screen.deviceXDPI / window.screen.logicalXDPI,
				browser: self.browserInfo.browser,
				browserVersion: self.browserInfo.version,
				os: self.os
			},
			userIdentifier: self.userIdentifier,
			connectedDevices: []
		};
		return log;
	};

	this.log = function(type, comment) {
		var log = self.createLog();
		log.type = type;
		log.comment = comment;
		self.logs.push(log);
	};

	this.sendLogs = function() {
		if (self.dirty) {
			this.log("update");
			this.dirty = false;
		}

		if (self.logs.length) {
			var logs = self.logs;
			self.logs = [];
			self.debug("Sending logs");
			self.debug(logs);
			self.ddp.method("log", [self.config.appId, self.config.apiKey, logs],
				function(e/*, res*/) {
					if (e) {
						return;
					}
				}
			);
			self.lastLogSent = logs[logs.length -1];
		}
	};

	this.close = function() {
		if(typeof(Storage) !== "undefined") {
			localStorage.setItem("logs", JSON.stringify(self.logs));
		}
	};

	this.debug = function(msg) {
		if (self.config.debug) {
			console.log(msg);
		}
	};

	this.connect = function() {
		var protocol = "ws";
		if (self.config.secure) {
			protocol = "wss";
		}
		var endpoint = protocol+"://"+self.config.server+":"+self.config.port+"/websocket";

		self.debug("connecting to "+endpoint);
		var options = {
			endpoint: endpoint,
			SocketConstructor: WebSocket,
			"do_not_autoconnect": true
		};
		self.ddp = new DDP(options);
		self.ddp.on("error", function(e) {
			self.debug(e);
		});
		self.ddp.on("connected", function() {

			self.connected = true;
			self.log("connected");

			setInterval(function() {
				self.log("online");
			}, 30000);

			self.sendLogs();
			setInterval(function() {
				self.sendLogs();
			}, self.config.debug ? 1000 : 10000);
		});

		try {
			self.ddp.connect();
		} catch (e) {
			console.log("caught!");
		}

		window.addEventListener('popstate', function() {
			self.log("location");
		});

		window.addEventListener("beforeunload", function() {
			self.close();
		});

		window.addEventListener("resize", function() {
			self.dirty = true;
		});

		window.addEventListener("login", function(e, id) { // jshint ignore:line
			self.login(id);
		});

		window.addEventListener("logout", function() {
			self.logout();
		});

	};

	this.uniqId = function() {
  	return Math.round(new Date().getTime()*100 + (Math.random() * 100));
	};

	this.login = function(userId) {
		self.setUser(userId);
		self.log("login");
	};

	this.logout = function() {
		self.log("logout");
		self.userIdentifier = null;
	};

	this.setUser = function(userId) {
		self.userIdentifier = CryptoJS.MD5(userId.toString()).toString(CryptoJS.enc.Base64);
	};

	// Init

	this.config = config;

	this.logs = [];

	this.userIdentifier = null;

	this.lastLogSent = null;

	this.dirty = false;

	if (userId) {
		this.setUser(userId);
	}

	if(typeof(Storage) !== "undefined") {
		// Device id
		this.deviceId = localStorage.getItem("deviceId");

		if (!this.deviceId) {
			this.deviceId = this.uniqId();

			localStorage.setItem("deviceId", this.deviceId);
		}

		// Session id
		this.sessionId = sessionStorage.getItem("sessionId");

		if (!this.sessionId) {
			this.sessionId = this.uniqId();

			sessionStorage.setItem("sessionId", this.sessionId);
		}

		// Logs
		try {
			var logs = JSON.parse(localStorage.getItem("logs"));
			if (logs) {
				this.logs = logs;
			}
		} catch (e) {}
	} else {
		this.noStorage = true;
		this.deviceId = this.uniqId();
		this.sessionId = this.sessionId();
	}

	this.browserInfo= (function(){
	    var ua= navigator.userAgent, tem,
	    M= ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
	    if(/trident/i.test(M[1])){
	        tem=  /\brv[ :]+(\d+)/g.exec(ua) || [];
	        return 'IE '+(tem[1] || '');
	    }
	    if(M[1]=== 'Chrome'){
	        tem= ua.match(/\b(OPR|Edge)\/(\d+)/);
	        if(tem !== null) {
						return tem.slice(1).join(' ').replace('OPR', 'Opera');
					}
	    }
	    M= M[2]? [M[1], M[2]]: [navigator.appName, navigator.appVersion, '-?'];
	    if((tem= ua.match(/version\/(\d+)/i))!== null) {
				M.splice(1, 1, tem[1]);
			}
	    return {'browser': M[0], 'version': M[1]};
	})();

	this.os=(function() {
		var os="Unknown OS";
		if (navigator.appVersion.indexOf("Win")!==-1) {
			os="Windows";
		}
		if (navigator.appVersion.indexOf("Mac")!==-1) {
			os="MacOS";
		}
		if (navigator.appVersion.indexOf("X11")!==-1) {
			os="UNIX";
		}
		if (navigator.appVersion.indexOf("Linux")!==-1) {
			os="Linux";
		}
		return os;
	})();


};
