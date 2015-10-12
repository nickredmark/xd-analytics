@Apps = new Mongo.Collection "apps"

Users.attachSchema Schemas.User

Schemas.App = new SimpleSchema
	name:
		type: String
		max: 200
	description:
		type: String
		max: 100
		optional: true
	userId:
		type: String
		min: 17
		max: 17
		autoValue: ->
			Meteor.userId()
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
	apiKey:
		type: String
		autoValue: ->
			if @isInsert
				Random.id()
			else if @isUpsert
				$setOnInsert: Random.id()

Apps.attachSchema Schemas.App
