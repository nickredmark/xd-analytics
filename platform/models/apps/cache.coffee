@Cache = new Mongo.Collection "cache"

Schemas.Cache = new SimpleSchema
	appId:
		type: String
		min: 17
		max: 17
	view:
		type: String
		max: 200
	from:
		type: Date
	to:
		type: Date
	options:
		type: Object
		blackbox: true
	value:
		type: Number
		decimal: true
		optional: true
	valueObject:
		type: [Object]
		blackbox: true
		optional: true

Cache.attachSchema Schemas.Cache
