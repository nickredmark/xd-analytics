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

Meteor.publish "oldapp", (appId) ->
	if Roles.userHasRole(@userId, 'admin')
		[
			Apps.find appId
			Logs.find
				appId: appId
			,
				sort:
					loggedAt: -1
				limit: 50
			Devices.find
				appId: appId
			,
				sort:
					lastUpdatedAt: -1
				limit: 50
		]
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
		if app.count() > 0
			logs = Logs.find
				appId: appId
			,
				sort:
					loggedAt: -1
				limit: 50
				fields:
					appId: 1
					createdAt: 1
					loggedAt: 1
					comment: 1
					device: 1
					connectedDevices: 1
					roles: 1
			devices = Devices.find
				appId: appId
			,
				sort:
					lastUpdatedAt: -1
				limit: 50
				fields:
					id: 1
					appId: 1
					width: 1
					height: 1
					minWidth: 1
					maxWidth: 1
					minHeight: 1
					maxHeight: 1
					roles: 1
					browser: 1
					browserVersion: 1
					connectedDevices: 1
			[app, logs, devices]
		else
			null
