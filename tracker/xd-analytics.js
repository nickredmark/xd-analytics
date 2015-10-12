function XDAnalytics(config) {
	this.config = config;
	var options = {
		endpoint: "ws://"+config.analyticsServer+":"+config.analyticsServerPort+"/websocket",
		SocketConstructor: WebSocket
	};

	this.ddp = new DDP(options);

	self = this;


	this.ddp.on("connected", function () {
		self.log({
			"comment": "Started XD-Analytics Tracker."
		});

		// XDmvc events

		XDmvc.on("XDdisconnection", function(e) {
			console.log("XDdisconnection");
			console.log(e);
			self.log({
				"comment": "Other device disconnected."
			});
		});
		XDmvc.on("XDconnection", function(e) {
			console.log("XDconnection");
			console.log(e);
			self.log({
				"comment": "This or other device connected."
			});
		});
		XDmvc.on("XDdevice", function(e) {
			console.log("XDdevice");
			console.log(e);
		});
		XDmvc.on("XDroles", function(e) {
			console.log("XDroles");
			console.log(e);
			self.log({
				"comment": "Device roles updated."
			});
		});
		XDmvc.on("XDsync", function(e) {
			console.log("XDsync");
			console.log(e);
		});
		XDmvc.on("XDsendToAll", function(e) {
			console.log("XDsendToAll");
			console.log(e);
			self.log({
				"comment": "Sending device data to all."
			});
		});
		XDmvc.on("XDsyncData", function(e) {
			console.log("XDsyncData");
			console.log(e);
		});
		XDmvc.on("XDupdate", function(e) {
			console.log("XDupdate");
			console.log(e);
		});
		XDmvc.on("XDothersRolesChanged", function(e) {
			console.log("XDothersRolesChanged");
			console.log(e);
		});

		// XDmvc.XDd2d events

		XDmvc.XDd2d.on("XDserverReady", function(e) {
			console.log("XDserverReady");
			console.log(e);
		});
		XDmvc.XDd2d.on("XDserverReady", function(e) {
			console.log("XDerror");
			console.log(e);
		});
		XDmvc.XDd2d.on("wrapMsg", function(e) {
			console.log("wrapMsg");
			console.log(e);
		});
		XDmvc.XDd2d.on("connectTo", function(e) {
			console.log("connectTo");
			console.log(e);
		});
		XDmvc.XDd2d.on("XDconnectionError", function(e) {
			console.log("XDconnectionError");
			console.log(e);
		});
		XDmvc.XDd2d.on("XDopen", function(e) {
			console.log("XDopen");
			console.log(e);
		});

		// Other events
		window.addEventListener("resize", function(e) {
		});

	});




}

XDAnalytics.prototype.log = function(log) {
	log.loggedAt = new Date();
	device = XDmvc.device;
	log.device = {
		id: device.id,
		width: device.width,
		height: device.height,
		roles: XDmvc.roles,
		browser: navigator.browserInfo.browser,
		browserVersion: navigator.browserInfo.version
	}
	log.connectedDevices = [];
	connectedDevices = XDmvc.getConnectedDevices();
	for (var i=0; i<connectedDevices.length; i++) {
		device = connectedDevices[i];
		log.connectedDevices.push({
			id: device.id,
			width: device.device.width,
			height: device.device.height,
			roles: device.roles
		});
	}
	console.log("Logging: ");
	console.log(log);
	this.ddp.method("log", [this.config.appId, this.config.apiKey, log],
		function(e, res) {
			if (e) {
				console.log("Error sending log:");
				console.log(e);
			}
			if (res) {
				console.log("Log sent:");
				console.log(res);
			}
		}
	);
};


navigator.browserInfo= (function(){
    var ua= navigator.userAgent, tem,
    M= ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
    if(/trident/i.test(M[1])){
        tem=  /\brv[ :]+(\d+)/g.exec(ua) || [];
        return 'IE '+(tem[1] || '');
    }
    if(M[1]=== 'Chrome'){
        tem= ua.match(/\b(OPR|Edge)\/(\d+)/);
        if(tem!= null) return tem.slice(1).join(' ').replace('OPR', 'Opera');
    }
    M= M[2]? [M[1], M[2]]: [navigator.appName, navigator.appVersion, '-?'];
    if((tem= ua.match(/version\/(\d+)/i))!= null) M.splice(1, 1, tem[1]);
    return {'browser': M[0], 'version': M[1]};
})();
