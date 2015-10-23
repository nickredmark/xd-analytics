Templates.App = React.createClass
	mixins: [ReactMeteorData]
	views:
		overview: "Overview"
		timeline: "Timeline"
		devices: "Devices"
		logs: "Logs"
	getMeteorData: ->
		handle = Meteor.subscribe 'app', @props.appId

		app = Apps.findOne @props.appId

		logs = Logs.find
				appId: @props.appId
			,
				sort:
					loggedAt: -1
			.fetch()

		devices = Devices.find
				appId: @props.appId
			,
				sort:
					lastUpdatedAt: -1
			.fetch()

		ready: handle.ready()
		app: app
		logs: logs
		devices: devices
	view: ->
		if @props.view then @props.view else "overview"
	viewUrl: (view) ->
		if view is "overview"
			"/apps/#{@props.appId}"
		else
			"/apps/#{@props.appId}/#{view}"
	render: ->
		<article className="container">
			{
				if @data.ready
					if @data.app
						<div className="row">
							<div className="col-xs-12">
								<h1>{@data.app.name}</h1>
								<p>{@data.app.description}</p>
							</div>
						</div>
					else
						<div className="row">
							<div className="col-xs-12">
								<h1>Not found</h1>
								<p>This app doesn't exist. <a href="/apps">Back to your apps</a>.</p>
							</div>
						</div>
				else
					<div className="row">
						<div className="col-xs-12">
							<h1>Loading App<Templates.Ellipsis/></h1>
						</div>
					</div>
			}
			{
				if not @data.ready or @data.app
					<div className="row">
						<div className="col-xs-12">
							<ul className="nav nav-tabs">
								{
									for view, label of @views
										<li key={view} role="presentation" className={if view is @view() then "active" else ""}><a href={@viewUrl(view)}>{label}</a></li>
								}
							</ul>
						</div>
					</div>
			}
			<div className="row">
				{
					if @data.ready
						if @data.app
							switch @view()
								when "overview"
									<Views.Overview app={@data.app} devices={@data.devices} logs={@data.logs}/>
								when "timeline"
									<Views.Timeline appId={@props.appId}/>
								when "devices"
									<Views.Devices appId={@props.appId} devices={@data.devices}/>
								when "logs"
									<Views.Logs logs={@data.logs}/>
					else
						<Templates.Loading />
				}
			</div>
		</article>

Views = {}

Views.Overview = React.createClass
	mixins: [ReactUtils]
	render: ->
		<div>
			<div className="col-xs-12 col-sm-6">
				<h2>App data</h2>
				<div>
					<label>App ID:&nbsp;</label>
					{@props.app._id}
				</div>
				<div>
					<label>API Key:&nbsp;</label>
					{@props.app.apiKey}
				</div>
			</div>
			<div className="col-xs-12 col-sm-6">
				<h2>Statistics</h2>
				<div>
					<label>Number of devices:&nbsp;</label>
					{@props.devices.length}
				</div>
				<div>
					<label>Number of log entries:&nbsp;</label>
					{@props.logs.length}
				</div>
			</div>
		</div>


Views.Timeline = React.createClass
	mixins: [ReactMeteorData, ReactUtils]
	displays:
		users: "Users and devices"
		timeOnline: "Time online"
		averageTimeOnline: "Average time online"
		devicesPerUser: "Devices per user"
		logs: "Number of logs"
		views: "Page views"
		uniquePages: "Unique page views"
		logins: "Logins"
		browsers: "Browsers"
		browserVersions: "Browser versions"
		oses: "Operating systems"
		pages: "Pages"
		deviceTypes: "Device types"
		deviceTypeCombinations: "Device type combinations"
	granularities:
		auto: "Auto"
		hour: "Hour"
		day: "Day"
		week: "Week"
		month: "Month"
	getInitialState: ->
		from: moment().subtract(7, 'days').toDate()
		to: new Date()
		display: 'users'
		granularity: 'auto'
	componentDidMount: ->
		@timeline = document.getElementById("timeline")

		if @data.logs
			@update @data.logs
	getMeteorData: ->
		find =
			appId: @props.appId

		if @state.from or @state.to
			find.loggedAt = {}
		if @state.from
			find.loggedAt.$gte = @state.from
		if @state.to
			find.loggedAt.$lte = @state.to

		logs = Logs.find find,
				sort:
					loggedAt: 1
			.fetch()

		@update logs

		logs: logs
	timeline: null
	chart: null
	currentChart: null

	update: (logs) ->
		if not logs
			return

		date = (point) ->
			point.loggedAt

		transform = (map) ->
			map

		reduce = (value) ->
			value

		switch @state.display
			when "logs"
				assign = (map, element) ->
					if not map["Logs"]
						map["Logs"] = 1
					else
						map["Logs"]++
				@lineChart logs, date, assign, transform, reduce

			when "users"
				assign = (map, element) ->
					if not map["Users"]
						map["Users"] = {}
					map["Users"][element.userIdentifier] = 1
					if not map["Devices"]
						map["Devices"] = {}
					map["Devices"][element.device.id] = 1
				reduce = (value) ->
					Object.keys(value).length
				@lineChart logs, date, assign, transform, reduce

			when "views"
				assign = (map, element) ->
					if not map["Views"]
						map["Views"] = 1
					else
						map["Views"]++
				@lineChart logs, date, assign, transform, reduce

			when "uniquePages"
				assign = (map, element) ->
					if element.type in ["connected", "location"]
						if not map["Pages"]
							map["Pages"] = {}
						map["Pages"][element.location] = 1
				reduce = (value) ->
					Object.keys(value).length
				@lineChart logs, date, assign, transform, reduce

			when "logins"
				assign = (map, element) ->
					if element.type in ["login"]
						if not map["Logins"]
							map["Logins"] = 0
						map["Logins"]++
					else if element.type in ["logout"]
						if not map["Logouts"]
							map["Logouts"] = 0
						map["Logouts"]++
				@lineChart logs, date, assign, transform, reduce

			when "devicesPerUser"
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
				@lineChart logs, date, assign, transform, reduce

			when "timeOnline"
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
				@lineChart logs, date, assign, transform, reduce


			when "averageTimeOnline"
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
					"Time online": (time / Object.keys(map["Time online"]).length).toFixed(2)
				@lineChart logs, date, assign, transform, reduce

			when "browsers"
				key = (element) ->
					element.device.browser
				assign = (map, element) ->
					map[element.device.id] = 1
				transform = (map) ->
					Object.keys(map).length
				@pieChart logs, key, assign, transform

			when "browserVersions"
				key = (element) ->
					"#{element.device.browser} #{element.device.browserVersion}"
				assign = (map, element) ->
					map[element.device.id] = 1
				transform = (map) ->
					Object.keys(map).length
				@pieChart logs, key, assign, transform

			when "oses"
				key = (element) ->
					element.device.os
				assign = (map, element) ->
					map[element.device.id] = 1
				transform = (map) ->
					Object.keys(map).length
				@pieChart logs, key, assign, transform

			when "pages"
				key = (element) ->
					element.location
				assign = (map, element) ->
					map[element.device.id] = 1
				transform = (map) ->
					Object.keys(map).length
				@pieChart logs, key, assign, transform

			when "deviceTypes"
				deviceTypes = {}
				for l in logs
					if not deviceTypes[l.device.id]
						deviceTypes[l.device.id] = {}
					deviceTypes[l.device.id][l.deviceType()] = 1

				deviceTypesList = for key, value of deviceTypes
					device: key
					types: value

				key = (element) ->
					Object.keys(element.types).sort().join()
				assign = (map, element) ->
					map[element.device] = 1
				transform = (map) ->
					Object.keys(map).length
				@pieChart deviceTypesList, key, assign, transform

			when "deviceTypeCombinations"
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

				log userDevicesList

				key = (element) ->
					combination = for key, value of element.devices
						Object.keys(value).sort().join()
					combination.sort().join(";")
				assign = (map, element) ->
					if not map.value
						map.value = 1
					else
						map.value++
				transform = (map) ->
					map.value
				@pieChart userDevicesList, key, assign, transform

	pieChart: (data, key, assign, transform) ->
		i = 0
		buckets = {}
		for l in data
			k = key(l)
			if not buckets[k]
				buckets[k] = {}
			assign(buckets[k], l)

		values = []
		for label, value of buckets
			count = transform(value)

			[color, highlight] = @colorPair 1
			values.push
				value: count
				label: label
				color: color
				highlight: highlight

		values.sort (a, b) ->
			a.value <= b.value

		if @currentChart
			@currentChart.destroy()

		ctx = @timeline.getContext("2d")
		@chart = new Chart(ctx)
		@currentChart = @chart.Pie values

	colorPair: (alpha) ->
			color = [Math.floor(Math.random()*256), Math.floor(Math.random()*256), Math.floor(Math.random()*256)]

			lighten = 20

			highlight = [Math.min(color[0] + lighten, 255), Math.min(color[1] + lighten, 255), Math.min(color[2] + lighten, 255)]

			["rgba(#{color[0]},#{color[1]},#{color[2]},1)", "rgba(#{highlight[0]},#{highlight[1]},#{highlight[2]},#{alpha})"]


	getBuckets: ->

		buckets = []

		from = moment(@state.from)
		to = moment(@state.to)

		if @state.granularity is "auto"
			if to.diff(from, 'weeks') > 50
				granularity = 'month'
			else if to.diff(from, 'days') > 50
				granularity = 'week'
			else if to.diff(from, 'hours') > 50
				granularity = 'day'
			else
				granularity = 'hour'
		else
			granularity = @state.granularity

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
	lineChart: (data, date, assign, transform, reduce) ->
		if not data
			return

		if not @timeline
			return

		[labels, buckets, values] = @getBuckets()

		i = 0
		# Discard all points earlier than buckets[0]
		while i < data.length
			current = moment(date(data[i]))
			if current >= buckets[0]
				break
			i++

		values = []
		j = 1
		# Add al points to their respective buckets
		while i < data.length and j < buckets.length
			current = moment(date(data[i]))
			while current > buckets[j] and j < buckets.length
				j++

			if j >= buckets.length
				break

			if not values[j-1]
				values[j-1] = {}
			assign(values[j-1], data[i])

			i++

		datasetsMap = {}
		# Reduce
		for map, i in values
			if map
				map = transform(map)
				for key, value of map
					if not datasetsMap[key]
						datasetsMap[key] = []
					datasetsMap[key][i] = reduce(value)

		if not Object.keys(datasetsMap).length
			datasetsMap["No Data"] = {}

		datasets = []
		for key, data of datasetsMap
			i = 0
			while i < labels.length
				if not data[i]
					data[i] = 0
				i++
			[color, lighter] = @colorPair(0.5)
			datasets.push
				label: key
				data: data
				fillColor: lighter
				strokeColor: color
				pointColor: color
				pointStrokeColor: "white"
				pointHighlightFill: "white"
				pointHighlightStroke: color

		if @currentChart
			@currentChart.destroy()
		ctx = @timeline.getContext("2d")
		@chart = new Chart(ctx)
		@currentChart = @chart.Line
			labels: labels
			datasets: datasets
		,
			multiTooltipTemplate: "<%= datasetLabel %> - <%= value %>"

	render: ->
		<div>
			<div className="col-xs-12">
				<h2>Timeline</h2>
			</div>
			<div className="col-xs-12 col-sm-4">
				<Templates.DateRangeInput id="range" label="Time range" from={@state.from} to={@state.to} onChange={@updateRange('from', 'to')}/>
			</div>
			{
				if false
					<div className="col-xs-12 col-sm-4">
						<Templates.Select id="display" label="Granularity" options={@granularities} value={@state.granularity} onChange={@updateValue('granularity')}/>
					</div>
			}
			<div className="col-xs-12 col-sm-4">
				<Templates.Select id="display" label="Data" options={@displays} value={@state.display} onChange={@updateValue('display')}/>
			</div>
			<div className="col-xs-12">
				<div id="timeline-wrapper">
					<canvas id="timeline"></canvas>
				</div>
			</div>
		</div>

Views.OldTimeline = React.createClass
	mixins: [ReactMeteorData, ReactUtils]
	getInitialState: ->
		from: moment().subtract(30, 'days').toDate()
		to: new Date()
	getMeteorData: ->
		find =
			appId: @props.appId

		if @state.from or @state.to
			find.loggedAt = {}
		if @state.from
			find.loggedAt.$gte = @state.from
		if @state.to
			find.loggedAt.$lte = @state.to

		logs = Logs.find find,
				sort:
					loggedAt: -1
			.fetch()

		@start logs

		logs: logs
	start: (logs) ->
		if not @chart
			return

		if not logs
			logs = @data.logs

		data =
			for l in logs
				date: l.loggedAt
				value: l.connectedDevices.length


		if data.length
			MG.data_graphic
				width: @wrapper.width()
				height: @wrapper.height()
				data: data
				#missing_is_hidden: true
				target: "#timeline"
				xax_start_at_min: true
				chart_type: "point"
				transition_on_update: true
		else
			MG.data_graphic
				width: @wrapper.width()
				height: @wrapper.height()
				data: data
				#missing_is_hidden: true
				target: "#timeline"
				xax_start_at_min: true
				chart_type: "missing-data"
				transition_on_update: true


		###
		data = ['Devices']
		for log in @data.logs
			data.push log.connectedDevices.length + 1
		@chart.load
			columns: [
				data
			]
		###
	componentDidMount: ->
		@chart = $('#timeline')
		@wrapper = $('#timeline-wrapper')

		$(window).resize @start

		###
		@chart = c3.generate
			bindto: '#timeline'
			data:
				columns: [
					['Devices']
				]
		###
		@start()
	render: ->
		<div className="col-xs-12">
			<h2>Timeline</h2>
			<Templates.DateRangeInput id="range" label="Range" from={@state.from} to={@state.to} onChange={@updateRange('from', 'to')}/>
			<div id="timeline-wrapper">
				<div id="timeline"></div>
			</div>
		</div>

Views.Devices = React.createClass
	render: ->
		<div className="col-xs-12">
			<h2>Devices</h2>
			{
				if @props.devices?.length
					<div>
						<DevicesGraph appId={@props.appId}/>
						<Templates.Table headers={["Id", "Browser", "Size, deviceXDPI, logicalXDPI", "Roles", "Connected devices", "Last updated"]}>
							{
								for device, i in @props.devices
									<tr key={i}>
										<td>{device.id}</td>
										<td>{device.browser} {device.browserVersion}</td>
										<td>
											{
												if device.width? or device.height?
													<span>{device.width}x{device.height}, {device.deviceXDPI}, {device.logicalXDPI} </span>
											}
											{
												if device.minWidth != device.maxWidth or device.minHeight != device.maxHeight
													<span>&nbsp;({device.minWidth}-{device.maxWidth}x{device.minHeight}-{device.maxHeight})</span>
											}
										</td>
										<td>
											{
												if device.roles?.length
													<ul>
														{
															for role, i in device.roles
																<li key={i}>{role}</li>
														}
													</ul>
											}
										</td>
										<td>
											{
												if device.connectedDevices?.length
													<ul>
														{
															for connectedDevice, i in device.connectedDevices
																<li key={i}>{connectedDevice}</li>
														}
													</ul>
											}
										</td>
										<td>
											{moment(device.lastUpdatedAt).format('YYYY-MM-DD HH:mm:ss')}
										</td>
									</tr>
							}
						</Templates.Table>
					</div>
				else
					<p>No devices were detected for this app yet.</p>
			}
		</div>

Views.Logs = React.createClass
	render: ->
		<div className="col-xs-12">
			<h2>Logs</h2>
			{
				if @props.logs?.length
					<Templates.Table headers={["Logged at", "Device ID", "Device", "User ID", "Location", "Type", "Comment"]}>
						{
							for l, i in @props.logs
								<tr key={i}>
									<td>{moment(l.loggedAt).format('YYYY-MM-DD HH:mm:ss:SSS')}</td>
									<td>{l.device.id}</td>
									<td>{l.device.os}, {l.device.browser}, {l.device.browserVersion}, {l.deviceType()} ({l.device.width}x{l.device.height}, {l.device.pixelRatio}) </td>
									<td>{l.userIdentifier}</td>
									<td>{l.location}</td>
									<td>{l.type}</td>
									<td>{l.comment}</td>
								</tr>
						}
					</Templates.Table>
				else
					<p>There are no logs for this app yet.</p>
			}
		</div>

DevicesGraph = React.createClass
	mixins: [ReactMeteorData]
	getInitialState: ->
		role: null
	getMeteorData: ->
		devices = Devices.find
					appId: @props.appId
				,
					sort:
						lastUpdatedAt: -1
			.fetch()

		for node in devices
			found = false
			for node2 in @nodes
				if node2.id == node.id
					for key of node
						node2[key] = node[key]
					found = true
					break
			if not found
				@nodes.push(node)

		#TODO: what if a device has been removed? Indeces will be all wrong
		for device, i in devices
			if device.connectedDevices
				for cd in device.connectedDevices
					for device2, j in devices
						if device2.id == cd
							@links.push
								source: i
								target: j
								value: 1

		roles = {}
		for device in devices
			if device.roles
				for role in device.roles
					roles[role] = 1
			if device.connectedDevices
				for cd in device.connectedDevices
					if cd.roles
						for role in cd.roles
							roles[role] = 1

		@start()

		roles: roles
	width: 400
	height: 400
	nodes: []
	links: []
	node: null
	link: null
	ratio: 0.1
	start: ->
		if not @graph
			return

		if not @force
			@force = d3.layout.force()
				.nodes(@nodes)
				.links(@links)
				.charge(-800)
				.size([$(@graph[0]).width(), $(@graph[0]).height()])
				.linkDistance(120)
				.on("tick", @tick)


		@link = @link.data(@force.links())
		@link.enter().append("div")
			.attr("class", "link")

		@link.exit().remove()

		@node = @node.data(@force.nodes())
		n = @node.enter().append("div")
		n.attr("class", "node")
			.call(@force.drag)

		n.append("div")
			.attr("class", (d) -> "browser #{d.browser}")

		@node.exit().remove()

		@force.start()
	tick: ->
		self = @

		@node
			.attr("style", (d) ->
				style = "left: #{d.x - d.width*self.ratio/2}px; top: #{d.y - d.height*self.ratio/2}px; width: #{d.width*self.ratio}px; height: #{d.height*self.ratio}px;"
				if d.roles and self.state.role in d.roles
					style += "background-color: #72E66D; border: 1px solid #027D46;"
				style
			)

		@link.attr("style", (d) ->
			getLineStyle(d.source.x, d.source.y, d.target.x, d.target.y))
	componentDidMount: ->
		@graph = d3.select('#devicesGraph')
		@node = @graph.selectAll(".node")
		@link = @graph.selectAll(".link")

		@start()
	setRole: (role) ->
		self = @
		->
			self.setState
				role: role
			self.start()
	getRoleStyle: (role) ->
		if role is @state.role
			"backgroundColor": "#72E66D"
			color: "white"
		else
			{}
	render: ->
		<div>
			<div className="roles">
				<ul>
					{
						for role of @data.roles
								<li key={role} style={@getRoleStyle(role)}><a onClick={@setRole(role)} >{role}</a></li>
					}
				</ul>
				<div className="clearfix"></div>
			</div>
			<div id="devicesGraph" style={width: "100%", height: "400px"}></div>
		</div>


getLineStyle = (x1, y1, x2, y2) ->

	if (y1 < y2)
		pom = y1
		y1 = y2
		y2 = pom
		pom = x1
		x1 = x2
		x2 = pom

	a = Math.abs(x1-x2)
	b = Math.abs(y1-y2)
	c
	sx = (x1+x2)/2
	sy = (y1+y2)/2
	width = Math.sqrt(a*a + b*b )
	x = sx - width/2
	y = sy

	a = width / 2

	c = Math.abs(sx-x)

	b = Math.sqrt(Math.abs(x1-x)*Math.abs(x1-x)+Math.abs(y1-y)*Math.abs(y1-y) )

	cosb = (b*b - a*a - c*c) / (2*a*c)
	rad = Math.acos(cosb)
	deg = (rad*180)/Math.PI

	'width:'+width+'px;-moz-transform:rotate('+deg+'deg);-webkit-transform:rotate('+deg+'deg);top:'+y+'px;left:'+x+'px;'
