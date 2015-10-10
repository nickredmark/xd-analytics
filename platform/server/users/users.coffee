Accounts.onCreateUser (options, user) ->
	if options.profile
		user.profile = options.profile
	else
		user.profile = {}
	if user.emails?
		Meteor.setTimeout ->
			Accounts.sendVerificationEmail user._id
		, 2*1000
	user

Meteor.startup ->

	facebook = Meteor.settings.private.facebook
	if (ServiceConfiguration.configurations.find({service: 'facebook'}).count() is 0) and facebook?.configured
	  ServiceConfiguration.configurations.insert
	    service: "facebook"
	    appId: facebook.appId
	    secret: facebook.appSecret

	google = Meteor.settings.private.google
	if (ServiceConfiguration.configurations.find({service: 'google'}).count() is 0) and google?.configured
		ServiceConfiguration.configurations.insert
			service: "google"
			clientId: google.clientId
			loginStyle: "popup"
			secret: google.secret

	if Meteor.users.find().count() is 0
		admin = Meteor.settings.private.admin
		id = Accounts.createUser
			username: admin.username
			email: admin.email
			password: admin.password
		Roles.addUserToRoles id, ['admin']

		test = Meteor.settings.private.test
		Accounts.createUser
			username: 'test'
			email: 'test@example.com'
			password: 'test'

Meteor.methods
	updateUsername: (username, name) ->
		Meteor.users.update @userId,
			$set:
				username: username
				'profile.name': name

Meteor.publish "user", ->
	[
		Users.find @userId
		Roles._collection.find
			userId: @userId
	]


Security.permit(['insert', 'update', 'remove']).collections([Users]).ifHasRole('admin').apply()
