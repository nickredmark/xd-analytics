Meteor.publish "apps", ->
	if Roles.userHasRole(@userId, 'admin')
		Apps.find()
	else
		Apps.find
			userId: @userId
		,
			sort:
				createdAt: -1
			fields:
				name: 1
				description: 1
				apiKey: 1

Meteor.publish "app", (appId) ->
	if Roles.userHasRole(@userId, 'admin')
		Apps.find appId
	else
		app = Apps.find
			_id: appId
			userId: @userId
		,
			fields:
				name: 1
				description: 1
				apiKey: 1
				device: 1
				connectedDevices: 1
				roles: 1
