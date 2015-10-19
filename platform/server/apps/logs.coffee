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

###
Logs.after.insert (userId, log) ->
	updateDevice = (device, connectedDevices) ->
		if not device.id
			return

		d = Devices.findOne
			id: device.id
			appId: log.appId

		if d
			set = {
				roles: d.roles
				connectedDevices: d.connectedDevices
			}

			if device.browser?
				set.browser = device.browser
				set.browserVersion = device.browserVersion

			if device.width?
				set.width = device.width
				if d.minWidth?
					set.minWidth = Math.min(d.minWidth, device.width)
				else
					set.minWidth = device.width
				if d.maxWidth?
					set.maxWidth = Math.max(d.maxWidth, device.width)
				else
					set.maxWidth = device.width
			if device.height?
				set.height = device.height
				if d.minHeight?
					set.minHeight = Math.min(d.minHeight, device.height)
				else
					set.minHeight = device.height
				if d.maxHeight?
					set.maxHeight = Math.max(d.maxHeight, device.height)
				else
					set.maxHeight = device.height

			if device.roles
				for role in device.roles
					if role not in d.roles
						d.roles.push(role)

			if connectedDevices?.length
				if not set.connectedDevices?
					set.connectedDevices = []
				for cd in connectedDevices
					if cd.id not in set.connectedDevices
						set.connectedDevices.push(cd.id)

			Devices.update
				id: device.id
				appId: log.appId
			,
				$set: set
		else
			set = {
				id: device.id
				appId: log.appId
				roles: device.roles
				browser: device.browser
			}

			if device.width?
				set.width = device.width
				set.minWidth = device.width
				set.maxWidth = device.width

			if device.height?
				set.height = device.height
				set.minHeight = device.height
				set.maxHeight = device.height

			if connectedDevices
				set.connectedDevices =
					cd.id for cd in connectedDevices

			Devices.insert set

	updateDevice(log.device, log.connectedDevices)
	for device in log.connectedDevices
		updateDevice(device)
###
