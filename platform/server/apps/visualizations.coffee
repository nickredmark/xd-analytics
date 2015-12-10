@preprocessLogs = (appId) ->
	threshold = 1000 * 60 * 5 # 5 minutes
	logs = Logs.find
		appId: appId
		date:
			$exists: false
	count = logs.count()
	if count
		log count
		i = 0
		logs.forEach (l) ->
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

###
reducible =
	"global-timeOnline": 1
	"global-timeOnlineByDeviceType": 1
	"global-logs": 1
	"global-views": 1
	"global-logins": 1
###

getAggregatedValues = (appId, view, from, to, options) ->

	log "get aggregated values #{appId} #{view} #{from} - #{to}"

	aggregate = []
	match =
		appId: appId
		date:
			$gte: from
			$lt: to
	aggregate.push
		$match: match

	switch view
		when "browsers-devices"
			aggregate.push
				$group:
					_id:
						device: "$device.id"
						browser: "$device.browser"
						version: "$device.browserVersion"

			aggregate.push
				$group:
					_id:
						browser: "$_id.browser"
						version: "$_id.version"
					count:
						$sum: 1

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$group:
					_id: "$_id.browser"
					count:
						$sum: "$count"
					versions:
						$push:
							version: "$_id.version"
							count: "$count"

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$limit: options?.limit or 20

			aggregated = Logs.aggregate aggregate

		when "browsers-views"
			match.type =
				$in: ["connected", "location"]

			aggregate.push
				$group:
					_id:
						browser: "$device.browser"
						version: "$device.browserVersion"
					count:
						$sum: 1

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$group:
					_id: "$_id.browser"
					count:
						$sum: "$count"
					versions:
						$push:
							version: "$_id.version"
							count: "$count"

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$limit: options?.limit or 20

			aggregated = Logs.aggregate aggregate
		when "browsers-versions"
			aggregate.push
				$group:
					_id:
						device: "$device.id"
						browser: "$device.browser"
						version: "$device.browserVersion"

			aggregate.push
				$group:
					_id:
						browser: "$_id.browser"
						version: "$_id.version"
					count:
						$sum: 1

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$group:
					_id: "$_id.browser"
					count:
						$sum: 1
					versions:
						$push:
							version: "$_id.version"
							count: "$count"

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$limit: options?.limit or 20

			aggregated = Logs.aggregate aggregate
		when "oses"

			aggregate.push
				$group:
					_id:
						device: "$device.id"
						os: "$device.os"

			aggregate.push
				$group:
					_id: "$_id.os"
					count:
						$sum: 1

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$limit: options?.limit or 20

			aggregated = Logs.aggregate aggregate
		when "locations"
			match.location =
				$exists: true
				$ne: null
			match.type =
				$in: ["connected", "location"]

			aggregate.push
				$group:
					_id: "$location"
					count:
						$sum: 1

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$limit: options?.limit or 20

			aggregated = Logs.aggregate aggregate

		when "users-views"
			match.userIdentifier =
				$exists: true
				$ne: null
			match.type =
				$in: ["connected", "location"]

			aggregate.push
				$group:
					_id:
						user: "$userIdentifier"
						device: "$device.id"
					count:
						$sum: 1

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$group:
					_id: "$_id.user"
					count:
						$sum: "$count"
					devices:
						$push:
							id: "$_id.device"
							count: "$count"

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$limit: options?.limit or 20

			aggregated = Logs.aggregate aggregate

		when "users-devices"
			match.userIdentifier =
				$exists: true
				$ne: null
			match.type =
				$in: ["connected", "location"]

			aggregate.push
				$group:
					_id:
						user: "$userIdentifier"
						device: "$device.id"
					count:
						$sum: 1

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$group:
					_id: "$_id.user"
					count:
						$sum: 1
					devices:
						$push:
							id: "$_id.device"
							count: "$count"

			aggregate.push
				$sort:
					count: -1

			aggregate.push
				$limit: options?.limit or 20

			aggregated = Logs.aggregate aggregate

		else
			throw new Meteor.Error "Unknown view: #{view}"

	log aggregated


getAnalyticsValue = (appId, view, from, to, options) ->
	cache = Cache.findOne
			appId: appId
			view: view
			from: from
			to: to
			options: options
		,
			fields:
				value: 1

	if cache
		log "Found in cache"
		cache.value
	else


		aggregate = [
			"users"
			"devices"
			"views"
			"viewsByFullLocation"
			"logs"
			"logins"
			"logouts"
			"location"
			"location-pattern"
			"browser"
			"browser-version"
			"os"
			"user"
			"device"
		]
		if view in aggregate
			value = computeAggregatedValue appId, view, from, to, options
		else

			###
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
			###
			logs = Logs.find
					appId: appId
					date:
						$gte: from
						$lt: to
				,
					sort:
						date: 1
			value = computeValue logs, view, options

		if to < moment()
			Cache.insert
				appId: appId
				view: view
				from: from
				to: to
				value: value
				options: options

		value

computeAggregatedValue = (appId, view, from, to, options) ->
	aggregate = []

	match =
		appId: appId
		date:
			$gte: from
			$lt: to
	aggregate.push
		$match: match

	switch view
		when "users"
			match.userIdentifier =
				$exists: true
				$ne: null

			aggregate.push
				$group:
					_id: "$userIdentifier"

			aggregate.push
				$group:
					_id: "count"
					count:
						$sum: 1

			aggregated = Logs.aggregate aggregate
			if aggregated.length
				value = aggregated[0].count
			else
				value = 0

		when "devices"
			match['device.id'] =
				$exists: true
				$ne: null


			aggregate.push
				$group:
					_id: "$device.id"

			aggregate.push
				$group:
					_id: "count"
					count:
						$sum: 1

			aggregated = Logs.aggregate aggregate
			if aggregated.length
				value = aggregated[0].count
			else
				value = 0

		when "browser"
			match["device.browser"] = options.browser
			match.type =
				$in: ["connected", "location"]
			value = Logs.find(match).count()

		when "browser-version"
			match["device.browser"] = options.browser
			match["device.browserVersion"] = options.version
			match.type =
				$in: ["connected", "location"]
			value = Logs.find(match).count()

		when "os"
			match["device.os"] = options.os
			match.type =
				$in: ["connected", "location"]
			value = Logs.find(match).count()

		when "user"
			match.userIdentifier = options.user
			match.type =
				$in: ["connected", "location"]
			value = Logs.find(match).count()

		when "device"
			match["device.id"] = options.device
			match.type =
				$in: ["connected", "location"]
			value = Logs.find(match).count()

		when "browser"
			match["device.browser"] = options.browser
			match.type =
				$in: ["connected", "location"]
			value = Logs.find(match).count()

		when "location"

			match.location = options.location
			match.type =
				$in: ["connected", "location"]
			value = Logs.find(match).count()

		when "location-pattern"

			match.location =
				$regex: options.pattern
			match.type =
				$in: ["connected", "location"]

			value = Logs.find(match).count()

		when "global-viewsByLocation"
			match.location =
				$exists: true
				$ne: null
			match.type =
				$in: ["connected", "location"]

			aggregate.push
				_id: "$location"
				count:
					$sum: 1

			aggregate.push
				$sort:
					count: -1

			locations = Logs.aggregate aggregate

			value =
				locations: locations

		when "views"
			match.type =
				$in: ["connected", "location"]

			value = Logs.find(match).count()

		when "logs"

			value = Logs.find(match).count()


		when "logins"
			match.type = "login"

			value = Logs.find(match).count()

		when "logouts"
			match.type = "logout"

			value = Logs.find(match).count()

	value

computeValue = (logs, view, options) ->

	transform = (map) ->
		map

	reduce = (value) ->
		value

	switch view

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

		when "global-uniquePages"
			assign = (map, element) ->
				if element.type in ["connected", "location"]
					if not map["Pages"]
						map["Pages"] = {}
					map["Pages"][element.location] = 1
			reduce = (value) ->
				Object.keys(value).length

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
			throw new Meteor.Error "Unknown view: #{view}"

	value = process logs, assign, transform, reduce

	value

getGranularity = (from, to, granularity) ->
	from = moment from
	to = moment to

	if not granularity or granularity is "auto"
		if to.diff(from, 'weeks') > 50
			'month'
		else if to.diff(from, 'days') > 50
			'week'
		else if to.diff(from, 'hours') > 50
			'day'
		else
			'hour'
	else
		granularity

getBuckets = (from, to, granularity) ->

	buckets = []

	from = moment from
	to = moment to

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

	getAggregatedValues: getAggregatedValues

	getAnalyticsValues: (appId, view, from, to, options, granularity) ->

		log "get analytics values #{appId} #{view} #{from} - #{to} #{options} #{granularity}"

		granularity = getGranularity from, to, granularity

		[labels, buckets] = getBuckets from, to, granularity

		values = []
		for label, i in labels
			if buckets[i] > moment()
				break

			values[i] = getAnalyticsValue appId, view, buckets[i].toDate(), moment(buckets[i+1]).subtract(1, "ms").toDate(), options

		log [labels, values]

	clearCache: (appId) ->
		cache = Cache.remove
			appId: appId
