Meteor.publish 'admin-users', ->
	if Roles.userHasRole(@userId, 'admin')
		Users.find {}
