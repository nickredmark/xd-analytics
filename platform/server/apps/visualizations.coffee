@preprocessLogs = (appId) ->
	threshold = 1000 * 60 * 5 # 5 minutes
	i = 0
	Logs.find
		appId: appId
		date:
			$exists: false
	.forEach (l) ->
		if Math.abs(l.createdAt - l.loggedAt) > threshold
			date = l.createdAt
		else
			date = l.loggedAt
		Logs.update l._id,
			$set:
				date: date
		if i % 1000 is 0
			log i
		i++

reducible =
	"global-timeOnline": 1
	"global-timeOnlineByDeviceType": 1
	"global-logs": 1
	"global-views": 1
	"global-logins": 1

getAnalyticsValue = (appId, view, from, to, options) ->
	cache = Cache.findOne
		appId: appId
		view: view
		from: from
		to: to
		options: options

	if cache
		log "Found in cache"
		value = {}
		for cachedKey, v of cache.value
			key = cachedKey.replace /\[dot\]/g, "."
			value[key] = v

		value
	else

		[labels, buckets] = getBuckets from, to

		preprocessLogs appId

		logs = Logs.find
				appId: appId
				date:
					$gte: from
					$lt: to
			,
				sort:
					date: 1

		if reducible[view] && logs.count() > 100 && labels.length > 1
				value = {}
				for label, i in labels

					if buckets[i] > moment()
						break

					map = getAnalyticsValue appId, view, buckets[i].toDate(), moment(buckets[i+1]).subtract(1, "ms").toDate(), options
					for key, v of map
						if not value[key]
							value[key] = 0
						value[key] += parseFloat(v)

		else
			value = computeValue logs, view, options

		if to < moment()
			cachedValue = {}
			for key, v of value
				cachedKey = key.replace /\./g, "[dot]"
				cachedValue[cachedKey] = v

			Cache.insert
				appId: appId
				view: view
				from: from
				to: to
				value: cachedValue
				options: options

		value

computeValue = (logs, view, options) ->

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

		when "global-usersByLocation"
			assign = (map, element) ->
				if element.location
					for pattern in options.patterns
						match = element.location.match pattern
						if match
							if not map[pattern]
								map[pattern] = {}
							map[pattern][element.userIdentifier] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-usersByLocationSubstring"
			assign = (map, element) ->
				if element.location
					words = element.location.match(/\w+/g)
					if words
						for word in words
							if not map[word]
								map[word] = {}
							map[word][element.userIdentifier] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-usersByFullLocation"
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
						start: moment(element.date)
						end: moment(element.date)
					]
				else
					current = moment(element.date)
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
							start: moment(element.date)
							end: moment(element.date)
						]
				else
					current = moment(element.date)
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
						start: moment(element.date)
						end: moment(element.date)
					]
				else
					current = moment(element.date)
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
				if element.type in ["connected", "location"]
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

		when "global-deviceTypes"
			deviceTypes = {}
			logs.forEach (l) ->
				if not deviceTypes[l.device.id]
					deviceTypes[l.device.id] = {}
				deviceTypes[l.device.id][l.deviceType()] = 1
			deviceTypesList = for key, value of deviceTypes
				device: key
				types: value
			logs = deviceTypesList

			assign = (map, element) ->
				#key = Object.keys(element.types).sort().join()
				if Object.keys(element.types).length > 1
					key = "variable"
				else
					key = Object.keys(element.types)[0]
				if not map[key]
					map[key] = {}
				map[key][element.device] = 1
			reduce = (value) ->
				Object.keys(value).length

		when "global-deviceTypeCombinations"
			userDevices = {}
			logs.forEach (l) ->
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
				if Object.keys(element.devices).length > 1
					combination = for key, value of element.devices
						#Object.keys(value).sort().join()
						if Object.keys(value).length > 1
							"variable"
						else
							Object.keys(value)[0]
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

	if granularity is "global"
		labels = ["#{from.format(Constants.dateFormat)} - #{to.format(Constants.dateFormat)}"]
		buckets = [from, to]
	else
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

	if data.forEach
		data.forEach (d) ->
			assign map, d
	else
		for d in data
			assign map, d

	map = transform map

	for key, value of map
		map[key] = reduce value

	map

Meteor.methods

	getAnalyticsValues: (appId, view, from, to, options, granularity) ->
		[labels, buckets] = getBuckets from, to, granularity

		values = {}
		for label, i in labels
			if buckets[i] > moment()
				break

			map = getAnalyticsValue appId, view, buckets[i].toDate(), moment(buckets[i+1]).subtract(1, "ms").toDate(), options
			for key, value of map
				if not values[key]
					values[key] = []
				values[key][i] = value

		if not Object.keys(values).length
			values["No Data"] = []

		[labels, values]

	clearCache: (appId) ->
		cache = Cache.remove
			appId: appId
