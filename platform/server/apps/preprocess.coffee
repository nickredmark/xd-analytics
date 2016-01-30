Meteor.computeInitialItervals = (min) ->
	InitialIntervals.remove()

	start = moment()
	if !min
		min = Logs.findOne
				date:
					$exists: true
			,
				fields:
					date: 1
				sort:
					date: 1
			.date
	log min
	max = Logs.findOne
			date:
				$exists: true
		,
			fields:
				date: 1
			sort:
				date: -1
		.date
	log max
	max = moment(max)
	current = moment(min).startOf("day")

	count = 0

	while current < max

		log current.format("YYYY-MM-DD")

		red = Logs.mapReduce ->

			d = @date

			diam = Math.sqrt @device.width*@device.width + @device.height*@device.height
			if true
				# This is an approximation based on only the width
				width = @device.width
				if width > 2000
					type = 4
				else if width > 1200
					type = 3
				else if width > 600
					type = 2
				else
					type = 1
			else
				# This is an approximation based on the diameter
				if diam > 2300
					type = 4 #xl
				else if diam > 1500
					type = 3 #lg
				else if diam > 800
					type = 2 #md
				else
					type = 1 #sm

			emit
				appId: @appId
				interval: new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes()-d.getMinutes()%10)
				deviceId: @device.id
				sessionId: @device.sessionId
				type: @type
				location: @location?.split("?")[0]
				userIdentifier: @userIdentifier
				browser: @device.browser
				browserVersion: @device.browserVersion
				os: @device.os
			,
				minDate: @date
				maxDate: @date
				timeOnline: 10*1000
				minWidth: @device.width
				maxWidth: @device.width
				minHeight: @device.height
				maxHeight: @device.height
				pixelRatio: @device.pixelRatio
				minDiam: diam
				maxDiam: diam
				minDeviceType: type
				maxDeviceType: type
				count: 1
		, (key, values) ->
			minDate = new Date(100000000000000) # if you are running this code in the year 5138, sorry ;)
			maxDate = new Date(0)
			minWidth = Number.MAX_VALUE
			maxWidth = 0
			minHeight = Number.MAX_VALUE
			maxHeight = 0
			minDiam = Number.MAX_VALUE
			maxDiam = 0
			minDeviceType = Number.MAX_VALUE
			maxDeviceType = 0
			pixelRatio = 0
			for value in values
				minDate = Math.min(minDate, value.minDate)
				maxDate = Math.max(maxDate, value.maxDate)
				minWidth = Math.min(minWidth, value.minWidth)
				maxWidth = Math.max(maxWidth, value.maxWidth)
				minHeight = Math.min(minHeight, value.minHeight)
				maxHeight = Math.max(maxHeight, value.maxHeight)
				minDiam  = Math.min(minDiam, value.minDiam)
				maxDiam = Math.max(maxDiam, value.maxDiam)
				minDeviceType = Math.min(minDeviceType, value.minDeviceType)
				maxDeviceType = Math.max(maxDeviceType, value.maxDeviceType)
				pixelRatio = if value.pixelRatio then value.pixelRatio

			minDate = new Date(minDate)
			maxDate = new Date(maxDate)

			minDate: minDate
			maxDate: maxDate
			timeOnline: maxDate - minDate + 10*1000
			minWidth: minWidth
			maxWidth: maxWidth
			minHeight: minHeight
			maxHeight: maxHeight
			minDiam: minDiam
			maxDiam: maxDiam
			minDeviceType: minDeviceType
			maxDeviceType: maxDeviceType
			pixelRatio: pixelRatio
			count: values.length
		,
			query:
				date:
					$exists: true
					$gte: current.toDate()
					$lte: moment(current).endOf("day").toDate()
			sort:
				appId: 1
				date: 1
			out:
				merge: "intervals"

		current.add(1, "day")

Meteor.computeDeviceIntervals = (min) ->

	DeviceIntervals.remove()

	InitialIntervals.mapReduce ->
		emit
			appId: @_id.appId
			interval: @_id.interval
			userIdentifier: @_id.userIdentifier
			deviceId: @_id.deviceId
		,
			deviceMinDate: @value.minDate
			deviceMaxDate: @value.maxDate
			deviceTimeOnline: if @._id.type is "online" then 0 else @value.timeOnline
			maxDeviceType: @value.maxDeviceType
			eventTypes: [@._id.type]
			locations: [@_id.location]
			os: @_id.os
			browser: @_id.browser
			events: [@]
			logs: @value.count
	, (key, values) ->
		deviceMinDate = new Date(100000000000000)
		deviceMaxDate = new Date(0)
		maxDeviceType = 0
		events = []
		logs = 0
		eventTypes = {}
		locations = []
		os = values[0].os
		browser = values[0].browser

		for value in values
			deviceMinDate = Math.min(deviceMinDate, value.deviceMinDate)
			deviceMaxDate = Math.max(deviceMaxDate, value.deviceMaxDate)
			maxDeviceType = Math.max(maxDeviceType, value.maxDeviceType)

			for type in value.eventTypes
				if !eventTypes[type]
					eventTypes[type] = true

			for event in value.events
				events.push event

			for location in value.locations
				locations.push location

			logs += value.logs

		deviceMinDate = new Date(deviceMinDate)
		deviceMaxDate = new Date(deviceMaxDate)

		eventTypes = Object.keys(eventTypes).sort()
		locations.sort()

		if eventTypes.length is 1 and eventTypes[0] is "online"
			deviceTimeOnline = 0
		else
			deviceTimeOnline = deviceMaxDate - deviceMinDate + 10*1000

		deviceMinDate: deviceMinDate
		deviceMaxDate: deviceMaxDate
		deviceTimeOnline: deviceTimeOnline
		maxDeviceType: maxDeviceType
		locations: locations
		os: os
		browser: browser
		eventTypes: eventTypes
		events: events
		logs: logs
	,
		out:
			merge: "deviceintervals"

Meteor.computeUserIntervals = (min) ->


	UserIntervals.remove()

	# Combinations for same user
	DeviceIntervals.mapReduce ->
		locations = []
		for location in @value.locations
			locations.push [location]
		emit
			appId: @_id.appId
			interval: @_id.interval
			userIdentifier: @_id.userIdentifier
		,
			userMinDate: @value.deviceMinDate
			userMaxDate: @value.deviceMaxDate
			userTimeOnline: @value.deviceTimeOnline
			deviceTypes: [@value.maxDeviceType]
			locations: locations
			oses: [@value.os]
			browsers: [@value.browser]
			deviceCount: 1
			eventTypes: [@value.eventTypes]
			events: [@]
			logs: @value.count
	, (key, values) ->
		userMinDate = new Date(100000000000000)
		userMaxDate = new Date(0)
		events = []
		deviceTypes = []
		locations = null
		oses = []
		browsers = []
		logs = 0
		eventTypes = {}
		for value in values
			userMinDate = Math.min(userMinDate, value.userMinDate)
			userMaxDate = Math.max(userMaxDate, value.userMaxDate)

			for type in value.eventTypes
				if !eventTypes[type]
					eventTypes[type] = true

			for event in value.events
				events.push event

			for deviceType in value.deviceTypes
				deviceTypes.push deviceType

			if locations
				nlocations = []
				for lcomb in locations
					for rcomb in value.locations
						ncomb = []
						for llocation in lcomb
							ncomb.push llocation
						for rlocation in rcomb
							ncomb.push rlocation
					ncomb.sort()
					nlocations.push ncomb
				locations = nlocations
			else
				locations = value.locations

			for os in value.oses
				oses.push os

			for browser in value.browsers
				browsers.push browser

			logs += value.logs

		userMinDate = new Date(userMinDate)
		userMaxDate = new Date(userMaxDate)

		eventTypes = Object.keys(eventTypes).sort()

		if eventTypes.length is 1 and eventTypes[0] is "online"
			userTimeOnline = 0
		else
			userTimeOnline = userMaxDate - userMinDate + 10*1000

		deviceTypes.sort()
		oses.sort()
		browsers.sort()

		userMinDate: userMinDate
		userMaxDate: userMaxDate
		userTimeOnline: userTimeOnline
		deviceTypes: deviceTypes
		deviceCount: deviceTypes.length
		locations: locations
		oses: oses
		browsers: browsers
		eventTypes: eventTypes
		events: events
		logs: logs
	,
		out:
			merge: "userintervals"

Meteor.computeFinalIntervals = ->
	UserIntervals.aggregate [
		$unwind: "$value.events"
	,
		$unwind: "$value.events.value.events"
	,
		$project:
			_id: false
			appId: "$_id.appId"
			userIdentifier: "$_id.userIdentifier"
			interval: "$_id.interval"

			deviceId: "$value.events._id.deviceId"

			sessionId: "$value.events.value.events._id.sessionId"
			type: "$value.events.value.events._id.type"
			location: "$value.events.value.events._id.location"
			browser: "$value.events.value.events._id.browser"
			browserVersion: "$value.events.value.events._id.browserVersion"
			os: "$value.events.value.events._id.os"

			logs: "$value.logs"
			userMinDate: "$value.userMinDate"
			userMaxDate: "$value.userMaxDate"
			userTimeOnline: "$value.userTimeOnline"
			deviceTypes: "$value.deviceTypes"
			deviceCount: "$value.deviceCount"
			userEventTypes: "$value.eventTypes"
			userLocations: "$value.locations"
			oses: "$value.oses"
			browsers: "$value.browsers"

			deviceMinDate: "$value.events.value.deviceMinDate"
			deviceMaxDate: "$value.events.value.deviceMaxDate"
			deviceTimeOnline: "$value.events.value.deviceTimeOnline"
			deviceEventTypes: "$value.events.value.eventTypes"
			deviceLocations: "$value.events.value.locations"

			minDate: "$value.events.value.events.value.minDate"
			maxDate: "$value.events.value.events.value.maxDate"
			timeOnline: "$value.events.value.events.value.timeOnline"
			minWidth: "$value.events.value.events.value.minWidth"
			maxWidth: "$value.events.value.events.value.maxWidth"
			minHeight: "$value.events.value.events.value.minHeight"
			maxHeight: "$value.events.value.events.value.maxHeight"
			pixelRatio: "$value.events.value.events.value.pixelRatio"
			minDiam: "$value.events.value.events.value.minDiam"
			maxDiam: "$value.events.value.events.value.maxDiam"
			minDeviceType: "$value.events.value.events.value.minDeviceType"
			maxDeviceType: "$value.events.value.events.value.maxDeviceType"
			count: "$value.events.value.events.value.count"
	,
		$out: "finalintervals"
	]
