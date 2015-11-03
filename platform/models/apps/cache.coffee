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
	value:
		type: Object
		blackbox: true

Cache.attachSchema Schemas.Cache
