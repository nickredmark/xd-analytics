###
@Sessions = new Mongo.Collection "sessions"

Schemas.Session = new SimpleSchema
	appId:
		type: String
		min: 17
		max: 17
	sessionId:
		type: String
	deviceId:
		type: String
	start:
		type: Date
	end:
		type: Date
	userIdentifiers:
		type: [String]
		optional: true
	locations:
		type: [String]
		optional: true
	types:
		type: [String]
	device:
		type: Schemas.Device

Sessions.attachSchemas Session.Log
###
