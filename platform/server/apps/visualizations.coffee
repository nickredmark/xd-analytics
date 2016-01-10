getAggregatedValues = (appId, view, from, to, options) ->

	log "get aggregated values #{appId} #{view} #{from} - #{to}"
	log options

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

		if options.deviceCount
			match.userIdentifier =
				$exists: true
				$ne: null
			match.deviceId =
				$exists: true
				$ne: null
			match.deviceCount = options.deviceCount

		if options.user
			match.userIdentifier = options.user

		if options.device
			match.deviceId = options.device

		if options.location
			match.location = options.location
		else if options.locationPattern
			match.location =
				$regex: options.locationPattern

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

			when "deviceTypes"
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

			when "deviceTypeCombinations"
				if !match.userIdentifier
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

			when "osCombinations"
				if !match.userIdentifier
					match.userIdentifier =
						$exists: true
						$ne: null

				aggregate.push
					$group:
						_id:
							user: "$userIdentifier"
							oses: "$oses"

				aggregate.push
					$group:
						_id: "$_id.oses"
						count:
							$sum: 1

			when "browserCombinations"
				if !match.userIdentifier
					match.userIdentifier =
						$exists: true
						$ne: null

				aggregate.push
					$group:
						_id:
							user: "$userIdentifier"
							browsers: "$browsers"

				aggregate.push
					$group:
						_id: "$_id.browsers"
						count:
							$sum: 1

			when "locationCombinations"
				if !match.userIdentifier
					match.userIdentifier =
						$exists: true
						$ne: null

				aggregate.push
					$unwind: "$userLocations"

				aggregate.push
					$match:
						"userLocations.1":
							$exists: true

				aggregate.push
					$group:
						_id:
							user: "$userIdentifier"
							userLocations: "$userLocations"

				aggregate.push
					$group:
						_id: "$_id.userLocations"
						count:
							$sum: 1

			when "deviceCombinations-users", "deviceCombinations-views"
				match.deviceCount =
					$exists: true
					$ne: null

				if !match.userIdentifier
					match.userIdentifier =
						$exists: true
						$ne: null

				if view is "deviceCombinations-views"
					match.type =
						$in: ["connected", "location"]

					aggregate.push
						$group:
							_id: "$deviceCount"
							count:
								$sum: "$count"
				else

					aggregate.push
						$group:
							_id:
								user: "$userIdentifier"
								deviceCount: "$deviceCount"

					aggregate.push
						$group:
							_id: "$_id.deviceCount"
							count:
								$sum: 1

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
							$sum: "$count"


			when "users-timeOnline", "users-combinedTimeOnline", "users-views", "users-devices", "users-combinedDevices"
				match.userIdentifier =
					$exists: true
					$ne: null

				switch view
					when "users-combinedDevices", "users-combinedTimeOnline"
						if !match.deviceId
							match.deviceId =
								$exists: true
								$ne: null
						match.deviceCount =
							$gte: 2
					when "users-views", "users-devices"
						match.type =
							$in: ["connected", "location"]

				id = "$userIdentifier"
				switch view
					when "users-timeOnline","users-combinedTimeOnline"
						aggregate.push
							$group:
								_id:
									userIdentifier: "$userIdentifier"
									interval: "$interval"
								userTimeOnline:
									$first: "$userTimeOnline"
						id = "$_id.userIdentifier"
						count =
							$sum: "$userTimeOnline"

					when "users-devices"
						aggregate.push
							$group:
								_id:
									userIdentifier: "$userIdentifier"
									deviceId: "$deviceId"
						id = "$_id.userIdentifier"
						count =
							$sum: 1
					when "users-combinedDevices"
						count =
							$max: "$deviceCount"
					else
						count =
							$sum: "$count"

				aggregate.push
					$group:
						_id: id
						count: count

			when "devices"

				match.deviceId =
					$exists: true
					$ne: null
				match.type =
					$in: ["connected", "location"]

				aggregate.push
					$group:
						_id: "$deviceId"
						count:
							$sum: "$count"

			else
				throw new Meteor.Error "Unknown view: #{view}"

		aggregate.push
			$sort:
				count: -1

		aggregate.push
			$limit: options?.limit or 20

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
		match.deviceCount = options.deviceCount
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


	if view isnt "logs"
		uniqueFields = []
		group =
			_id: {}

		# Unique
		switch view
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
			when "timeOnline", "averageTimeOnline"
				if options.device or options.deviceType
					uniqueFields.push "deviceId"
					uniqueFields.push "interval"
					group.timeOnline =
						$first: "$deviceTimeOnline"
				else
					uniqueFields.push "userIdentifier"
					uniqueFields.push "interval"
					group.timeOnline =
						$first: "$userTimeOnline"

		for uniqueField, i in uniqueFields
			if !match[uniqueField]
				match[uniqueField] =
					$exists: true
					$ne: null
			group._id[uniqueField] = "$#{uniqueField}"

		aggregate.push
			$group: group

		switch view
			when "averageTimeOnline"
				group =
					_id: {}
					timeOnline:
						$sum: "$timeOnline"
				if options.device or options.deviceType
					group._id.deviceId = "$_id.deviceId"
				else
					group._id.userIdentifier = "$_id.userIdentifier"
				aggregate.push
					$group: group

	group =
		_id: "count"
	switch view
		when "logs"
			group.count =
				$sum: "$count"
		when "timeOnline"
			group.count =
				$sum: "$timeOnline"
		when "averageTimeOnline"
			group.count =
				$avg: "$timeOnline"
		else
			group.count =
				$sum: 1

	# Sum it all together
	aggregate.push
		$group: group

	for a in aggregate
		log a

	aggregated = Intervals.aggregate aggregate

	if aggregated.length
		value = aggregated[0].count
	else
		value = 0

	switch view
		when "timeOnline", "averageTimeOnline"
			value /= 1000*60

	log value

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
