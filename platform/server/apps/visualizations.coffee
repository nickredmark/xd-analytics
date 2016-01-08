getAggregatedValues = (appId, view, from, to, options) ->

	log "get aggregated values #{appId} #{view} #{from} - #{to}"

	cache = Cache.findOne
			appId: appId
			view: view
			from: from
			to: to
			options: options
		,
			fields:
				valueObject: 1

	if cache
		log "Found in cache"
		aggregated = cache.valueObject
	else

		aggregate = []

		match =
			appId: appId
			interval:
				$gte: from
				$lt: to
		aggregate.push
			$match: match

		switch view
			when "browsers-devices"
				aggregate.push
					$group:
						_id:
							device: "$deviceId"
							browser: "$browser"
							version: "$browserVersion"


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

			when "browsers-views"

				match.type =
					$in: ["connected", "location"]

				aggregate.push
					$group:
						_id:
							browser: "$browser"
							version: "$browserVersion"
						count:
							$sum: "$count"

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

			when "browsers-versions"
				aggregate.push
					$group:
						_id:
							device: "$deviceId"
							browser: "$browser"
							version: "$browserVersion"

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

			when "oses"

				aggregate.push
					$group:
						_id:
							device: "$deviceId"
							os: "$os"

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

			when "device-types"
				match.deviceId =
					$exists: true
					$ne: null
				match.maxDeviceType =
					$exists: true
					$ne: null

				aggregate.push
					$group:
						_id:
							deviceId: "$deviceId"
							deviceType: "$maxDeviceType"

				aggregate.push
					$group:
						_id: "$_id.deviceType"
						count:
							$sum: 1

				aggregate.push
					$sort:
						count: -1

			when "device-type-combinations"
				match.userIdentifier =
					$exists: true
					$ne: null

				aggregate.push
					$group:
						_id:
							user: "$userIdentifier"
							deviceTypes: "$deviceTypes"

				aggregate.push
					$group:
						_id: "$_id.deviceTypes"
						count:
							$sum: 1

				aggregate.push
					$sort:
						count: -1


			when "device-combinations"
				match.userIdentifier =
					$exists: true
					$ne: null

				aggregate.push
					$group:
						_id:
							user: "$userIdentifier"
							devices:
								$size: "$deviceTypes"

				aggregate.push
					$group:
						_id: "$_id.devices"
						count:
							$sum: 1

				aggregate.push
					$sort:
						count: -1

			when "locations-views", "locations-combinedViews"
				match.location =
					$exists: true
					$ne: null
				match.type =
					$in: ["connected", "location"]
				if view is "locations-combinedViews"
					match.userIdentifier =
						$exists: true
						$ne: null
					match.deviceId =
						$exists: true
						$ne: null
					match["deviceTypes.1"] =
						$exists: true


				aggregate.push
					$group:
						_id: "$location"
						count:
							$sum: "$count"

				aggregate.push
					$sort:
						count: -1

				aggregate.push
					$limit: options?.limit or 20


			when "users-views", "users-devices", "users-combinedViews"
				match.userIdentifier =
					$exists: true
					$ne: null
				if view is "users-combinedViews"
					# make sure at least 2 devices have been used at the same time
					match.deviceId =
						$exists: true
						$ne: null
					match["deviceTypes.1"] =
						$exists: true
				match.type =
					$in: ["connected", "location"]

				aggregate.push
					$group:
						_id:
							user: "$userIdentifier"
							device: "$deviceId"
						count:
							$sum: "$count"

				aggregate.push
					$sort:
						count: -1

				aggregate.push
					$group:
						_id: "$_id.user"
						count:
							$sum: if view is "users-devices" then 1 else "$count"
						devices:
							$push:
								id: "$_id.device"
								count: "$count"

				aggregate.push
					$sort:
						count: -1

				aggregate.push
					$limit: options?.limit or 20

			else
				throw new Meteor.Error "Unknown view: #{view}"


		for a in aggregate
			log a

		aggregated = Intervals.aggregate aggregate

		if to < moment()
			Cache.insert
				appId: appId
				view: view
				from: from
				to: to
				options: options
				valueObject: aggregated

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

	if cache and false
		log "Found in cache"
		cache.value
	else

		value = computeAggregatedValue appId, view, from, to, options

		###
		if view in aggregate
		else
			preprocessLogs appId, from, to

			[labels, buckets] = getBuckets from, to


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
			logs = Logs.find
					appId: appId
					date:
						$gte: from
						$lt: to
				,
					sort:
						date: 1
			value = computeValue logs, view, options
			###

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
		interval:
			$gte: from
			$lt: to

	uniqueFields = []

	eliminationGroupId = {}

	aggregate.push
		$match: match

	# Filters on original data
	if options.logType
		switch options.logType
			when "view"
				match.type =
					$in: ["connected", "location"]
			else
				match.type = options.logType

	if options.deviceType
		match.maxDeviceType = options.deviceType
	if options.browser
		match.browser = options.browser
	if options.browserVersion
		match.browserVersion = options.browserVersion
	if options.os
		match.os = options.os
	if options.user
		match.userIdentifier = options.user
	if options.device
		match.deviceId = options.device
	if options.session
		match.sessionId = options.session

	if options.locationPattern
		match.location =
			$regex: options.locationPattern
	else if options.location
		match.location = options.location

	if options.deviceCount
		if !match.userIdentifier
			match.userIdentifier =
				$exists: true
				$ne: null
		if !match.deviceId
			match.deviceId =
				$exists: true
				$ne: null
		match.deviceTypes =
			$size: options.deviceCount
	else if options.deviceTypeCombination
		if !match.userIdentifier
			match.userIdentifier =
				$exists: true
				$ne: null
		if !match.deviceId
			match.deviceId =
				$exists: true
				$ne: null
		match.deviceTypes = options.deviceTypeCombination

	# Unique
	switch view
		when "logs"
			# Do nothing
			null
		when "users"
			uniqueFields.push "userIdentifier"
		when "devices"
			uniqueFields.push "deviceId"
		when "sessions"
			uniqueFields.push "sessionId"
		when "deviceTypes"
			uniqueFields.push "maxDeviceType"
		when "browsers"
			uniqueFields.push "browser"
		when "browserVersions"
			uniqueFields.push "browser"
			uniqueFields.push "browserVersion"
		when "oses"
			uniqueFields.push "os"
		when "locations"
			uniqueFields.push "location"

	if uniqueFields.length
		for uniqueField, i in uniqueFields
			match[uniqueField] =
				$exists: true
				$ne: null
			eliminationGroupId["uniqueField#{i}"] = "$#{uniqueField}"

		aggregate.push
			$group:
				_id: eliminationGroupId
				count:
					$first: 1
				countAll:
					$sum: 1

	# Sum it all together
	aggregate.push
		$group:
			_id: "count"
			count:
				$sum: "$count"

	for a in aggregate
		log a

	aggregated = Intervals.aggregate aggregate

	if aggregated.length
		value = aggregated[0].count
	else
		value = 0

	log value

###
computeValue = (logs, view, options) ->

	transform = (map) ->
		map

	reduce = (value) ->
		value

	switch view

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

		else
			throw new Meteor.Error "Unknown view: #{view}"

	value = process logs, assign, transform, reduce

	value
###

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

		log "get analytics values #{appId} #{view} #{from} - #{to} #{granularity}"
		log options

		granularity = getGranularity from, to, granularity

		[labels, buckets] = getBuckets from, to, granularity

		values = []
		for label, i in labels
			if buckets[i] > moment()
				break

			values[i] = getAnalyticsValue appId, view, buckets[i].toDate(), moment(buckets[i+1]).subtract(1, "ms").toDate(), options

		[labels, values]

	clearCache: (appId) ->
		cache = Cache.remove
			appId: appId
