Meteor.methods
	log: (appId, apiKey, logs) ->
		app = Apps.findOne
			_id: appId
			apiKey: apiKey

		if not app
			throw new Error "Invalid credentials."

		for l in logs
			l.appId = appId
			Logs.insert l
