getAnalyticsValue = (appId, view, from, to) ->
		caching = true
		if caching
			cache = Cache.findOne
				appId: appId
				view: view
				from: from
				to: to

		if cache
			cache.value
		else

			logs = Logs.find
					appId: appId
					loggedAt:
						$gte: from
						$lt: to
				,
					sort:
						loggedAt: 1
				.fetch()


			value = computeValue logs, view

			if caching
				if to < moment()
					Cache.insert
						appId: appId
						view: view
						from: from
						to: to
						value: value

			value

computeValue = (logs, view) ->

	transform = (map) ->
		map

	reduce = (value) ->
		value

	switch view
		when "global-users"
			assign = (map, element) ->
				if element.userIdentifier
					if not map["Users"]
						map["Users"] = {}
					map["Users"][element.userIdentifier] = 1
				if not map["Devices"]
					map["Devices"] = {}
				map["Devices"][element.device.id] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-usersByDeviceType"
			assign = (map, element) ->
				if element.userIdentifier
					if not map[element.userIdentifier]
						map[element.userIdentifier] = {}
					map[element.userIdentifier][element.deviceType()] = 1
			transform = (map) ->
				byDeviceType = {}
				for user, types of map
					for deviceType, one of types
						if not byDeviceType[deviceType]
							byDeviceType[deviceType] = 0
						byDeviceType[deviceType]++
				byDeviceType

		when "global-usersByLocation"
			assign = (map, element) ->
				if element.location
					if not map[element.location]
						map[element.location] = {}
					map[element.location][element.userIdentifier] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-timeOnline"
			assign = (map, element) ->
				if not map["Time online"]
					map["Time online"] = {}
				if not map["Time online"][element.device.id]
					map["Time online"][element.device.id] = [
						start: moment(element.loggedAt)
						end: moment(element.loggedAt)
					]
				else
					current = moment(element.loggedAt)
					history = map["Time online"][element.device.id]
					timeout = moment(history[history.length-1].end).add(5, 'minutes')
					if current < timeout
						history[history.length-1].end = current
			transform = (map) ->
				time = 0
				for device, history of map["Time online"]
					for interval in history
						time += interval.end.add(10, 'seconds').diff(interval.start, 'minutes', true)
				"Time online": time.toFixed(2)

		when "global-timeOnlineByDeviceType"
			assign = (map, element) ->
				if not map[element.device.id]
					map[element.device.id] =
						type: {}
						history: [
							start: moment(element.loggedAt)
							end: moment(element.loggedAt)
						]
				else
					current = moment(element.loggedAt)
					history = map[element.device.id].history
					timeout = moment(history[history.length-1].end).add(5, 'minutes')
					if current < timeout
						history[history.length-1].end = current
				map[element.device.id].type[element.deviceType()] = 1
			transform = (map) ->
				byDeviceType = {}

				for device, data of map
					time = 0
					for interval in data.history
						time += interval.end.add(10, 'seconds').diff(interval.start, 'minutes', true)
					byDeviceType[Object.keys(data.type).sort().join()] = time

				byDeviceType

		when "global-averageTimeOnline"
			assign = (map, element) ->
				if not map["Time online"]
					map["Time online"] = {}
				if not map["Time online"][element.device.id]
					map["Time online"][element.device.id] = [
						start: moment(element.loggedAt)
						end: moment(element.loggedAt)
					]
				else
					current = moment(element.loggedAt)
					history = map["Time online"][element.device.id]
					timeout = moment(history[history.length-1].end).add(5, 'minutes')
					if current < timeout
						history[history.length-1].end = current
			transform = (map) ->
				if map["Time online"]
					time = 0
					for device, history of map["Time online"]
						for interval in history
							time += interval.end.add(10, 'seconds').diff(interval.start, 'minutes', true)
					nmap =
						"Time online": (time / Object.keys(map["Time online"]).length).toFixed(2)
				else
					nmap =
						"Time online": 0
				nmap

		when "global-devicesPerUser"
			assign = (map, element) ->
				if element.userIdentifier
					if not map[element.userIdentifier]
						map[element.userIdentifier] = {}
					map[element.userIdentifier][element.device.id] = 1
			transform = (map) ->
				byNumber = {}
				for user, devices of map
					number = Object.keys(devices).length
					if number is 1
						key = "1 device"
					else
						key = "#{number} devices"
					if not byNumber[key]
						byNumber[key] = 1
					else
						byNumber[key]++
				byNumber

		when "global-logs"
			assign = (map, element) ->
				if not map["Logs"]
					map["Logs"] = 1
				else
					map["Logs"]++

		when "global-views"
			assign = (map, element) ->
				if not map["Views"]
					map["Views"] = 1
				else
					map["Views"]++

		when "global-uniquePages"
			assign = (map, element) ->
				if element.type in ["connected", "location"]
					if not map["Pages"]
						map["Pages"] = {}
					map["Pages"][element.location] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-logins"
			assign = (map, element) ->
				if element.type in ["login"]
					if not map["Logins"]
						map["Logins"] = 0
					map["Logins"]++
				else if element.type in ["logout"]
					if not map["Logouts"]
						map["Logouts"] = 0
					map["Logouts"]++

		when "global-browsers"
			assign = (map, element) ->
				key = element.device.browser
				if not map[key]
					map[key] = {}
				map[key][element.device.id] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-browserVersions"
			assign = (map, element) ->
				key = "#{element.device.browser} #{element.device.browserVersion}"
				if not map[key]
					map[key] = {}
				map[key][element.device.id] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-oses"
			assign = (map, element) ->
				key = element.device.os
				if not map[key]
					map[key] = {}
				map[key][element.device.id] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-pages"
			assign = (map, element) ->
				key = element.location
				if not map[key]
					map[key] = {}
				map[key][element.device.id] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-deviceTypes"
			deviceTypes = {}
			for l in logs
				if not deviceTypes[l.device.id]
					deviceTypes[l.device.id] = {}
				deviceTypes[l.device.id][l.deviceType()] = 1
			deviceTypesList = for key, value of deviceTypes
				device: key
				types: value
			logs = deviceTypesList

			assign = (map, element) ->
				log element
				key = Object.keys(element.types).sort().join()
				if not map[key]
					map[key] = {}
				map[key][element.device] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-deviceTypeCombinations"
			userDevices = {}
			for l in logs
				if l.userIdentifier
					if not userDevices[l.userIdentifier]
						userDevices[l.userIdentifier] = {}
					if not userDevices[l.userIdentifier][l.device.id]
						userDevices[l.userIdentifier][l.device.id] = {}
					userDevices[l.userIdentifier][l.device.id][l.deviceType()] = 1

			userDevicesList = for key, value of userDevices
				user: key
				devices: value

			logs = userDevicesList

			assign = (map, element) ->
				combination = for key, value of element.devices
					Object.keys(value).sort().join()
				key = combination.sort().join(";")
				if not map[key]
					map[key] = 1
				else
					map[key]++

		when "user-logs"
			assign = (map, element) ->
				if not map[element.device.id]
					map[element.device.id] = 1
				else
					map[element.device.id]++

		else
			throw new Error "Unknown view: #{view}"

	value = process logs, assign, transform, reduce

	value

getBuckets = (from, to, granularity) ->

	buckets = []

	from = moment from
	to = moment to

	if not granularity or granularity is "auto"
		if to.diff(from, 'weeks') > 50
			granularity = 'month'
		else if to.diff(from, 'days') > 50
			granularity = 'week'
		else if to.diff(from, 'hours') > 50
			granularity = 'day'
		else
			granularity = 'hour'

	# Create buckets

	current = from.startOf(granularity)
	to = to.endOf(granularity)
	while current < to
		buckets.push moment(current)
		current.add(1, granularity)

	formats =
		month: "MMMM"
		week: "w"
		day: "dd D"
		hour: "H:00"
	labels = (point.format(formats[granularity]) for point in buckets)
	buckets.push moment(current)

	[labels, buckets]

process = (data, assign, transform, reduce) ->
	map = {}
	for d in data
		assign map, d

	map = transform map

	for key, value of map
		map[key] = reduce value

	map

Meteor.methods

	getAnalyticsValues: (appId, view, from, to, granularity) ->
		[labels, buckets] = getBuckets from, to, granularity

		values = {}
		for label, i in labels
			map = getAnalyticsValue appId, view, buckets[i].toDate(), buckets[i+1].toDate()
			for key, value of map
				if not values[key]
					values[key] = []
				values[key][i] = value

		if not Object.keys(values).length
			values["No Data"] = []

		[labels, values]

	getAnalyticsValue: getAnalyticsValue
