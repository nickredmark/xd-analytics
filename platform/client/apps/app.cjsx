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
	modes:
		global: "Global"
		user: "User"
		device: "Device"
	chartType:
		'global-users': 'line'
		'global-usersByDeviceType': 'line'
		'global-timeOnline': 'line'
		'global-timeOnlineByDeviceType': 'line'
		'global-averageTimeOnline': 'line'
		'global-devicesPerUser': 'line'
		'global-logs': 'line'
		'global-views': 'line'
		'global-uniquePages': 'line'
		'global-logins': 'line'
		'global-browsers': 'pie'
		'global-browserVersions': 'pie'
		'global-oses': 'pie'
		'global-pages': 'pie'
		'global-deviceTypes': 'pie'
		'global-deviceTypeCombinations': 'pie'
		'user-logs': 'line'
		'device-logs': 'line'
	displays:
		global:
			users: "Users and devices"
			usersByDeviceType: "Users by device type"
			timeOnline: "Time online"
			timeOnlineByDeviceType: "Time online by device type"
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
		user:
			logs: "Logs"
		device:
			logs: "Logs"
	granularities:
		auto: "Auto"
		day: "Day"
		week: "Week"
		month: "Month"
	getInitialState: ->
		from: moment().subtract(7, 'days').toDate()
		to: new Date()
		mode: 'global'
		display:
			global: 'users'
			user: 'logs'
			device: 'logs'
		granularity: 'auto'
		user: null
		device: null
	componentDidMount: ->
		@timeline = document.getElementById("timeline")
		@load()
	load: ->
		self = @
		if @timeline
			switch @chartType[@view()]
				when "line"
					Meteor.call 'getAnalyticsValues', @props.appId, @view(), @state.from, @state.to, @state.granularity, (e, r) ->
						checkError e
						[labels, values] = r
						self.lineChart labels, values
				when "pie"
					Meteor.call 'getAnalyticsValue', @props.appId, @view(), @state.from, @state.to, @state.granularity, (e, r) ->
						checkError e
						self.pieChart r
	getMeteorData: ->

		###
		if allLogs
			usersMap = {}
			for l in allLogs
				if l.userIdentifier
					if not usersMap[l.userIdentifier]
						usersMap[l.userIdentifier] =
							devices: {}
					usersMap[l.userIdentifier].devices[l.device.id] = 1

			users = for id, data of usersMap
				id: id
				data: data
			users.sort (u1, u2) ->
				Object.keys(u1.data.devices).length <= Object.keys(u2.data.devices).length

		allLogs: allLogs
		logs: logs
		users: users
		###

		{}

	timeline: null
	chart: null
	currentChart: null

	view: ->
		"#{@state.mode}-#{@state.display[@state.mode]}"
	pieChart: (buckets) ->

		colors = @colorPairSeries Object.keys(buckets).length, 1

		i = 0
		values = []
		for label, value of buckets
			[color, highlight] = colors[i]
			values.push
				value: value
				label: label
				color: color
				highlight: highlight

			i++

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

	colorPairSeries: (amount, alpha) ->

		colors = []
		i = 0

		base = [Math.random()*100, Math.random()*100, Math.random()*100]

		lighten = 20

		max = 255 - 40

		min = Math.max base[0], base[1], base[2]

		gap = (max - min) / amount

		while i < amount
			color = [base[0] + i*gap, base[1] + i*gap, base[2] + i*gap]
			highlight = [Math.min(color[0] + lighten, 255), Math.min(color[1] + lighten, 255), Math.min(color[2] + lighten, 255)]
			colors[i] = ["rgba(#{Math.floor(color[0])},#{Math.floor(color[1])},#{Math.floor(color[2])},1)", "rgba(#{Math.floor(highlight[0])},#{Math.floor(highlight[1])},#{Math.floor(highlight[2])},#{alpha})"]
			i++

		colors

	lineChart: (labels, values) ->

		colors = @colorPairSeries Object.keys(values).length, 0.5

		j = 0
		datasets = []
		for key, data of values
			i = 0
			while i < labels.length
				if not data[i]
					data[i] = 0
				i++
			[color, lighter] = colors[j]
			datasets.push
				label: key
				data: data
				fillColor: lighter
				strokeColor: color
				pointColor: color
				pointStrokeColor: "white"
				pointHighlightFill: "white"
				pointHighlightStroke: color

			j++


		if @currentChart
			@currentChart.destroy()
		ctx = @timeline.getContext("2d")

		@chart = new Chart(ctx)
		@currentChart = @chart.Line
			labels: labels
			datasets: datasets
		,
			multiTooltipTemplate: "<%= datasetLabel %> - <%= value %>"
			bezierCurve: false

	getStyle: ->
		display: (if @state.mode is "user" and not @state.user then "none" else "block")
	render: ->
		@load()
		<div>
			<div className="col-xs-12">
				<h2>Timeline</h2>
			</div>
			<div className="col-xs-12 col-sm-6">
				<Templates.DateRangeInput id="range" label="Time range" from={@state.from} to={@state.to} onChange={@updateRange('from', 'to')}/>
				<Templates.Select id="display" label="Granularity" options={@granularities} value={@state.granularity} onChange={@updateValue('granularity')}/>
			</div>
			<div className="col-xs-12 col-sm-6">
				<Templates.Select id="mode" label="Mode" options={@modes} value={@state.mode} onChange={@updateValue('mode')}/>
				<Templates.Select id="display" label="Data" options={@displays[@state.mode]} value={@state.display[@state.mode]} onChange={@updateDictValue('display', @state.mode)}/>
			</div>
			<div className="col-xs-12">
				<div id="timeline-wrapper">
					<canvas id="timeline" style={@getStyle()}></canvas>
				</div>
				{
					if @state.mode is "user"
						<Templates.Table headers={["User", "Devices"]}>
							{
								for user, i in @data.users
									<tr key={i}>
										<td>
											<a onClick={@setValue('user', user.id)} style={{fontWeight: (if user.id is @state.user then "bold" else "normal")}}>{user.id}</a>
										</td>
										<td>
											{
												for device of user.data.devices

													<span key={device}>{device} </span>
											}
										</td>
									</tr>
							}
						</Templates.Table>
				}
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
