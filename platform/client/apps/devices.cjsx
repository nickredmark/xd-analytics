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


@DevicesGraph = React.createClass
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
