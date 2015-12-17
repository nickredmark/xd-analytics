@Devices = new Mongo.Collection "devices"

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
