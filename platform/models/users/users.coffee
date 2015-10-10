@Users = Meteor.users
Schemas = {}

Schemas.UserProfile = new SimpleSchema
	name:
		type: String
		max: 200
		optional: true

Schemas.UserEmail = new SimpleSchema
	address:
		type: String
		regEx: SimpleSchema.RegEx.Email
	verified:
		type: Boolean

Schemas.User = new SimpleSchema
	username:
		type: String
		min: 3
		regEx: /^[a-z0-9A-Z_]*$/
		optional: true
		custom: ->
			if @operator == '$unset'
				'required'
			else if @field("emails").isSet and not @isSet
				'required'
			else
				null
	emails:
		type: [Schemas.UserEmail]
		min: 1
		optional: true
		custom: ->
			if @field("username").isSet and not @isSet
				'required'
			else
				null
	createdAt:
		type: Date
	profile:
		type: Schemas.UserProfile
		optional: true
	services:
		type: Object
		optional: true
		blackbox: true
	roles:
		type: [String]
		optional: true

Users.attachSchema Schemas.User

Users.helpers
	displayName: ->
		if @profile.name
			@profile.name
		else
			@username
	isAdmin: ->
		@hasRole 'admin'
	email: ->
		@emails?[0]?.address
