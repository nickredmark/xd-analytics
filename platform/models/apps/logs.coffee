@Logs = new Mongo.Collection "logs"

Schemas.DeviceState = new SimpleSchema
	id:
		type: String
		optional: true
	sessionId:
		type: String
		optional: true
	noStorage:
		type: Boolean
		optional: true
	width:
		type: Number
		decimal: true
		optional: true
	height:
		type: Number
		decimal: true
		optional: true
	roles:
		type: [String]
		optional: true
	browser:
		type: String
		optional: true
	browserVersion:
		type: String
		optional: true
	os:
		type: String
		optional: true
	pixelRatio:
		type: Number
		decimal: true
		optional: true
	diam:
		type: Number
		decimal: true
	type:
		type: String

Schemas.Log = new SimpleSchema
	userIdentifier:
		type: String
		optional: true
	appId:
		type: String
		min: 17
		max: 17
	createdAt:
		type: Date
		denyUpdate: true
		autoValue: ->
			if @isInsert
				new Date
			else if @isUpsert
				$setOnInsert: new Date
			else
				@unset()
	loggedAt:
		type: Date
		denyUpdate: true
	date:
		type: Date
		autoValue: ->
			if @isInsert
				now = new Date
				threshold = 1000 * 60 * 5 # 5 minutes
				loggedAt = @field("loggedAt").value
				if Math.abs(now - loggedAt) > threshold
					now
				else
					loggedAt
	location:
		type: String
		optional: true
	type:
		type: String
	comment:
		type: String
		max: 300
		optional: true
	device:
		type: Schemas.DeviceState
	connectedDevices:
		type: [String]

Logs.attachSchema Schemas.Log

Logs.helpers
	deviceDiam: ->
		Math.sqrt @device.width*@device.width + @device.height*@device.height
	deviceType: ->
		if @device.pixelRatio
			realDiam = @deviceDiam() / @device.pixelRatio
		else
			realDiam = @deviceDiam()
		if realDiam > 1800
			"xl"
		else if realDiam > 1150
			"lg"
		else if realDiam > 500
			"md"
		else
			"sm"
