@Devices = new Mongo.Collection "devices"

Schemas.DeviceState = new SimpleSchema
	id:
		type: String
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
	type:
		type: String
	comment:
		type: String
		max: 300
		optional: true
	device:
		type: Schemas.DeviceState
	connectedDevices:
		type: [Schemas.DeviceState]

Logs.attachSchema Schemas.Log

Schemas.Device = new SimpleSchema
	id:
		type: String
	appId:
		type: String
		min: 17
		max: 17
	width:
		type: Number
		decimal: true
		optional: true
	height:
		type: Number
		decimal: true
		optional: true
	minWidth:
		type: Number
		decimal: true
		optional: true
	maxWidth:
		type: Number
		decimal: true
		optional: true
	minHeight:
		type: Number
		decimal: true
		optional: true
	maxHeight:
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
	connectedDevices:
		type: [String]
		optional: true
	lastUpdatedAt:
		type: Date
		autoValue: ->
			new Date()

Devices.attachSchema Schemas.Device
