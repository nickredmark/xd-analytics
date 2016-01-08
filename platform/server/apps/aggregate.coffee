intervalIdString = (interval) ->
	$concat: [
			# year
			$substr: [
					$year: "$date"
				, 0, 4 ]
		,
			# month
			$cond: [
					$lte: [
							$month: "$date"
						, 9 ]
				,
					$concat: [
							"0"
						,
							$substr: [
									$month: "$date"
								, 0, 2 ]
						]
				,
					$substr: [
							$month: "$date"
						, 0, 2 ]
				]
		,
			# date
			$cond: [
					$lte: [
							$dayOfMonth: "$date"
						, 9 ]
				,
					$concat: [
							"0"
						,
							$substr: [
									$dayOfMonth: "$date"
								, 0, 2 ]
						]
				,
					$substr: [
							$dayOfMonth: "$date"
						, 0, 2 ]
				]
		,
			# hour
			$cond: [
					$lte: [
							$hour: "$date"
						, 9 ]
				,
					$concat: [
							"0"
						,
							$substr: [
									$hour: "$date"
								, 0, 2 ]
						]
				,
					$substr: [
							$hour: "$date"
						, 0, 2 ]
				]
		,
			# interval
			$cond: [
					$lte: [
							$subtract: [
									$minute: "$date"
								,
									$mod: [
											$minute: "$date"
										, interval ]
								]
						, 9 ]
				,
					$concat: [ "0",
							$substr: [
									$subtract: [
											$minute: "$date"
										,
											$mod: [
													$minute: "$date"
												, interval ]
										]
								, 0, 2]
						]
				,
					$substr: [
							$subtract: [
									$minute: "$date"
								,
									$mod: [
											$minute: "$date"
										, interval ]
								]
						, 0, 2]
				]
		]

@preprocessLogs = (appId, from, to) ->
	return
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

Meteor.computeIntervals = (min) ->

	InitialIntervals.remove({})

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
			deviceType = (diam) ->
				if diam > 1800
					type = 4 #xl
				else if diam > 1150
					type = 3 #lg
				else if diam > 500
					type = 2 #md
				else
					type = 1 #sm
				type

			d = @date

			diam = Math.sqrt @device.width*@device.width + @device.height*@device.height
			if @device.pixelRatio
				diam = diam / @device.pixelRatio

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
				minWidth: @device.width
				maxWidth: @device.width
				minHeight: @device.height
				maxHeight: @device.height
				pixelRatio: @device.pixelRatio
				minDiam: diam
				maxDiam: diam
				minDeviceType: deviceType diam
				maxDeviceType: deviceType diam
				count: 1
		, (key, values) ->
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
				minWidth = Math.min(minWidth, value.minWidth)
				maxWidth = Math.max(maxWidth, value.maxWidth)
				minHeight = Math.min(minHeight, value.minHeight)
				maxHeight = Math.max(maxHeight, value.maxHeight)
				minDiam  = Math.min(minDiam, value.minDiam)
				maxDiam = Math.max(maxDiam, value.maxDiam)
				minDeviceType = Math.min(minDeviceType, value.minDeviceType)
				maxDeviceType = Math.max(maxDeviceType, value.maxDeviceType)
				pixelRatio = if value.pixelRatio then value.pixelRatio

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
			maxDeviceType: @value.maxDeviceType
			events: [@]
			logs: @value.count
	, (key, values) ->
		maxDeviceType = 0
		events = []
		logs = 0
		for value in values
			maxDeviceType = Math.max(maxDeviceType, value.maxDeviceType)

			for event in value.events
				events.push event

			logs += value.logs

		maxDeviceType: maxDeviceType
		events: events
		logs: logs
	,
		out:
			merge: "deviceintervals"

Meteor.computeUserIntervals = (min) ->


	UserIntervals.remove()

	# Combinations for same user
	DeviceIntervals.mapReduce ->
		emit
			appId: @_id.appId
			interval: @_id.interval
			userIdentifier: @_id.userIdentifier
		,
			deviceTypes: [@value.maxDeviceType]
			events: @value.events
			logs: @value.count
	, (key, values) ->
		events = []
		deviceTypes = []
		logs = 0
		for value in values

			for event in value.events
				events.push event

			for deviceType in value.deviceTypes
				deviceTypes.push deviceType

			logs += value.logs

		deviceTypes: deviceTypes.sort()
		events: events
		logs: logs
	,
		out:
			merge: "userintervals"

Meteor.computeFinalIntervals = ->
	UserIntervals.aggregate [
		$unwind: "$value.events"
	,
		$project:
			_id: false
			appId: "$_id.appId"
			userIdentifier: "$_id.userIdentifier"
			interval: "$value.events._id.interval"
			deviceId: "$value.events._id.deviceId"
			sessionId: "$value.events._id.sessionId"
			type: "$value.events._id.type"
			location: "$value.events._id.location"
			browser: "$value.events._id.browser"
			browserVersion: "$value.events._id.browserVersion"
			os: "$value.events._id.os"
			logs: "$value.logs"
			deviceTypes: "$value.deviceTypes"
			minDate: "$value.events.value.minDate"
			maxDate: "$value.events.value.maxDate"
			minWidth: "$value.events.value.minWidth"
			maxWidth: "$value.events.value.maxWidth"
			minHeight: "$value.events.value.minHeight"
			maxHeight: "$value.events.value.maxHeight"
			pixelRatio: "$value.events.value.pixelRatio"
			minDiam: "$value.events.value.minDiam"
			maxDiam: "$value.events.value.maxDiam"
			minDeviceType: "$value.events.value.minDeviceType"
			maxDeviceType: "$value.events.value.maxDeviceType"
			count: "$value.events.value.count"
	,
		$out: "finalintervals"
	]

Meteor.computeSlottedSessions = (min) ->

	#preprocessLogs()

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
	current = moment(min).startOf("week")


	#Sessions.remove {}

	while current < max

		log current.format("YYYY-MM-DD")

		aggregated = Logs.aggregate [
			$match:
				date:
					$exists: true
					$gte: current.toDate()
					$lte: moment(current).endOf("week").toDate()
		,
			$group:
				_id:
					appId: "$appId"
					deviceId: "$device.id"
					sessionId: "$device.sessionId"
					year:
						$year: "$date"
					month:
						$month: "$date"
					day:
						$dayOfMonth: "$date"
					hour:
						$hour: "$date"
					interval:
						$subtract: [
							$minute: "$date"
						,
							$mod: [
								$minute: "$date"
							,
								10
							]
						]
					type: "$type"
					location: "$location"
					userIdentifier: "$userIdentifier"
				appId:
					$first: "$appId"
				minDate:
					$min: "$date"
				maxDate:
					$max: "$date"
				minWidth:
					$min: "$device.width"
				maxWidth:
					$max: "$device.width"
				minHeight:
					$min: "$device.height"
				maxHeight:
					$max: "$device.height"
				browser:
					$first: "$device.browser"
				browserVersion:
					$first: "$device.browserVersion"
				os:
					$first: "$device.os"
				pixelRatio:
					$first: "$device.pixelRatio"
				count:
					$sum: 1
		,
			$group:
				_id:
					appId: "$_id.appId"
					deviceId: "$_id.deviceId"
					sessionId: "$_id.sessionId"
					year: "$_id.year"
					month: "$_id.month"
					day: "$_id.day"
					hour: "$_id.hour"
					interval: "$_id.interval"
					userIdentifier: "$_id.userIdentifier"
					location: "$_id.location"
				types:
					$push:
						type: "$_id.type"
						count: "$count"
				minDate:
					$min: "$minDate"
				maxDate:
					$max: "$maxDate"
				minWidth:
					$min: "$minWidth"
				maxWidth:
					$max: "$maxWidth"
				minHeight:
					$min: "$minHeight"
				maxHeight:
					$max: "$maxHeight"
				browser:
					$first: "$browser"
				browserVersion:
					$first: "$browserVersion"
				os:
					$first: "$os"
				pixelRatio:
					$first: "$pixelRatio"
				count:
					$sum: "$count"
		,
			$group:
				_id:
					appId: "$_id.appId"
					deviceId: "$_id.deviceId"
					sessionId: "$_id.sessionId"
					year: "$_id.year"
					month: "$_id.month"
					day: "$_id.day"
					hour: "$_id.hour"
					interval: "$_id.interval"
					userIdentifier: "$_id.userIdentifier"
				locations:
					$push:
						location: "$_id.location"
						types: "$types"
						count: "$count"
				userIdentifiers: "$userIdentifiers"
				minDate:
					$min: "$minDate"
				maxDate:
					$max: "$maxDate"
				minWidth:
					$min: "$minWidth"
				maxWidth:
					$max: "$maxWidth"
				minHeight:
					$min: "$minHeight"
				maxHeight:
					$max: "$maxHeight"
				browser:
					$first: "$browser"
				browserVersion:
					$first: "$browserVersion"
				os:
					$first: "$os"
				pixelRatio:
					$first: "$pixelRatio"
				count:
					$sum: "$count"
		,
			$project:
				_id: false
				appId: "$_id.appId"
				deviceId: "$_id.deviceId"
				sessionId: "$_id.sessionId"
				year: "$_id.year"
				month: "$_id.month"
				day: "$_id.day"
				hour: "$_id.hour"
				interval: "$_id.interval"
				userIdentifiers: "$_id.userIdentifier"
				locations: 1
				minDate: 1
				maxDate: 1
				minWidth: 1
				maxWidth: 1
				minHeight: 1
				maxHeight: 1
				browser: 1
				browserVersion: 1
				os: 1
				pixelRatio: 1
				count: "$count"
		,
			$out: "sessions-temp"
		]

		SessionsTemp.mapReduce ->
			doc = @
			doc.date = new Date doc.year, doc.month-1, doc.day, doc.hour, doc.interval, 0, 0
			emit @_id, doc
		, (key, values) ->
			values[0]
		,
			out:
				merge: "sessions"

		current.add(1, "week")

	return
	Sessions.aggregate [
		$project:
			appId: "$value.appId"
			deviceId: "$value.deviceId"
			sessionId: "$value.sessionId"
			date: "$value.date"
			year: "$value.year"
			month: "$value.month"
			day: "$value.day"
			interval: "$value.interval"
			locations: "$value.locations"
			userIdentifiers: "$value.userIdentifiers"
			userIdentifier: "$value.userIdentifier"
			minDate: "$value.minDate"
			maxDate: "$value.maxDate"
			minWidth: "$value.minWidth"
			maxWidth: "$value.maxWidth"
			minHeight: "$value.minHeight"
			maxHeight: "$value.maxHeight"
			browser: "$value.browser"
			browserVersion: "$value.browserVersion"
			os: "$value.os"
			pixelRatio: "$value.pixelRatio"
			count: "$value.count"
	,
		$out: "sessions"
	]

Meteor.computeAllSessions = (min) ->
	timeout = 5 * 60 * 1000 # 5 minutes
	start = moment()
	if !min
		min = Logs.findOne
				date:
					$exists: true
			,
				sort:
					date: 1
			.date
	max = Logs.findOne
			date:
				$exists: true
		,
			sort:
				date: -1
		.date
	max = moment(max)
	current = moment(min).startOf("day")
	i = 0
	updated = 0
	inserted = 0

	storeSession = (session) ->
		s = Sessions.findOne
			sessionId: session.sessionId
			start:
				$lte: session.start
			end:
				$gte: moment(session.start).subtract(5, "minutes").toDate()
		if s
			if s.end < session.end
				updated++
				Sessions.update s._id,
					$set:
						end: session.end
		else
			inserted++
			Sessions.insert session




	while current < max
		count = Logs.find
				date:
					$gte: current.toDate()
					$lte: moment(current).endOf("hour").toDate()
			.count()
		log count
		sessions = {}
		Logs.find
			date:
				$gte: current.toDate()
				$lte: moment(current).endOf("hour").toDate()
		,
			sort:
				date: 1
		.forEach (l) ->
			sessionId = l.device.sessionId or l.device.id

			session = sessions[sessionId]
			if session
				if session.end < moment(l.date).subtract(5, "minutes").toDate()
					storeSession sessions[sessionId]
					delete(sessions[sessionId])
				else
					session.end = l.date
			else
				sessions[sessionId] =
					sessionId: sessionId
					start: l.date
					end: l.date

			i++

		for sessionId, session of sessions
			storeSession session

		log "day: #{current.format("YYYY-MM-DD HH")}, logs: #{i}\tupdated: #{updated}\tinserted: #{inserted}, time: #{moment()-start}"
		current.add(1, "hour")

Meteor.methods
	sessionStats: ->
		aggregated = Logs.aggregate [
			$match:
				"device.sessionId":
					$exists: true
		,
			$group:
				_id: "$device.sessionId"
				count:
					$sum: 1
				minDate:
					$min: "$date"
				maxDate:
					$max: "$date"
		,
			$project:
				count: "$count"
				diff:
					$subtract: ["$maxDate", "$minDate"]
		,
			$group:
				_id: "aggregated"
				averageCount:
					$avg: "$count"
				maxCount:
					$max: "$count"
				maxDiff:
					$max: "$diff"
				averageDiff:
					$avg: "$diff"
		]
		log aggregated

	aggregateLogs: (limit) ->

		aggregated = Logs.aggregate [
			$match:
				date:
					$exists: true
		,
			$limit: limit
		,
			$group:
				_id:
					appId: "$appId"
					userIdentifier: "$userIdentifier"
					date: intervalId(15)
					type: "$type"
					device:
						id: "$device.id"
						type: "$device.type"
						sessionId: "$device.sessionId"
						diam: "$device.diam"
						browser: "$device.browser"
						browserVersion: "$device.browserVersion"
						location: "$device.location"
				count:
					$sum: 1
			,
				$group:
					_id: "count"
					count:
						$sum: 1
			]

		log aggregated
