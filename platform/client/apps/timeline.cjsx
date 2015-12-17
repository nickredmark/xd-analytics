
Views.Timeline = React.createClass
	mixins: [ReactUtils]
	ranges:
		Today: [
			moment().format(Constants.dateFormat)
			moment().format(Constants.dateFormat)
		]
		"Last 2 Days": [
			moment().subtract(2, 'days').format(Constants.dateFormat)
			moment().subtract(1, 'day').format(Constants.dateFormat)
		]
		"Last 7 Days": [
			moment().subtract(7, 'days').format(Constants.dateFormat)
			moment().subtract(1, 'days').format(Constants.dateFormat)
		]
		"Last month": [
			moment().subtract(1, 'month').format(Constants.dateFormat)
			moment().subtract(1, 'days').format(Constants.dateFormat)
		]
		"Last 3 months": [
			moment().subtract(3, "months").format(Constants.dateFormat)
			moment().subtract(1, 'days').format(Constants.dateFormat)
		]
		"Last 6 months": [
			moment().subtract(6, "months").format(Constants.dateFormat)
			moment().subtract(1, 'days').format(Constants.dateFormat)
		]
	displays:
		general: "General"
		timeOnline: "Time online"
		timeOnlineByDeviceType: "Time online by device type"
		averageTimeOnline: "Average time online"
		deviceTypeCombinations: "Device type combinations"
	data:
		users: "Users"
		devices: "Devices"
		sessions: "Sessions"
		logs: "Logs"
		views: "Views"
		uniqueViews: "Unique views"
		logins: "Logins"
		logouts: "Logouts"
		deviceTypes: "Device types"
	granularities:
		auto: "Auto"
		day: "Day"
		week: "Week"
		month: "Month"
		global: "Global"
	browserViews:
		views: "By views"
		devices: "By devices"
		versions: "By versions"
	userViews:
		views: "By views"
		devices: "By devices"
	deviceCombinationsViews:
		overall: "Overall"
		coincident: "Coincident"
	timeline: null
	chart: null
	currentChart: null
	labels: []

	getInitialState: ->
		from: moment().startOf('day').subtract(7, 'days').toDate()
		to: moment().endOf('day').subtract(1, 'days').toDate()
		granularity: 'auto'
		display: 'general'

		locations: null
		browsers: null
		oses: null
		users: null
		deviceCombinations: null
		deviceTypes: null

		patterns: []

		values: {}

		views:
			users: "views"
			browsers: "views"
			deviceCombinations: "overall"

		pattern: ""
	componentDidMount: ->
		@timeline = document.getElementById("timeline")
		@loadGlobalValue "users"
		@loadAllValues()
	setView: (name, value) ->
		self = @
		set = {}
		set.views = @state.views
		set.views[name] = value
		@setState set
		, ->
			self.loadValues name, "#{name}-#{value}"
	loadAllValueSets: ->
		self = @
		values = @state.values
		for label, data of values
			delete(data.values)
		@setState
			values: values
		, ->
			self.lineChart()
			for label, data of self.state.values
				self.loadValueSet label
	loadAllValues: ->
		log "Load all values"
		@loadAllValueSets()
		@loadValues "deviceTypes", "device-types"
		@loadValues "deviceCombinations", "deviceCombinations-#{@state.views.deviceCombinations}"
		@loadValues "browsers", "browsers-#{@state.views.users}"
		@loadValues "oses"
		@loadValues "locations"
		@loadValues "users", "users-#{@state.views.users}"
	loadValues: (type, view) ->
		if !view
			view = type
		self = @
		set = {}
		set[type] = null
		self.setState set, ->
			Meteor.call 'getAggregatedValues', self.props.appId, view, self.state.from, self.state.to, {}, handleResult null, (r) ->
				set = {}
				set[type] = r
				self.setState set
	setValueSet: (label, data) ->
		self = @
		values = @state.values
		data.color = colorPair 0.5
		if values[label]
			delete(values[label])
			@setState
				values: values
			, @lineChart
		else
			values[label] = data
			@setState
				values: values
			, @wrap(@loadValueSet, label)
	deleteValue: (label) ->
		self = @
		values = @state.values
		delete(values[label])
		@setState
			values: values
		, ->
			self.lineChart()
	loadValueSet: (label) ->
		data = @state.values[label]
		options = {}
		switch data.type
			when "global"
				view = data.name
			when "pattern"
				view = "location-pattern"
				options = {pattern: data.pattern}
			when "browser"
				view = "browser"
				options = {browser: data.browser}
			when "browser-version"
				view = "browser-version"
				options = {browser: data.browser, version: data.version}
			when "os"
				view = "os"
				options = {os: data.os}
			when "user"
				view = "user"
				options = {user: data.user}
			when "device"
				view = "device"
				options = {device: data.device}
			when "location"
				view = "location"
				options = {location: data.location}
			when "device-count-overall"
				view = "device-count-overall"
				options = {deviceCount: data.deviceCount}
			when "device-count-coincident"
				view = "device-count-coincident"
				options = {deviceCount: data.deviceCount}
			when "device-type"
				view = "device-type"
				options = {deviceType: data.deviceType}
			else
				throw new Error("unknown data type in loadValueSet")
		self = @
		Meteor.call 'getAnalyticsValues', @props.appId, view, @state.from, @state.to, options, @state.granularity, handleResult null, (r) ->
			[labels, values] = r
			self.labels = labels
			allValues = self.state.values
			if allValues[label]?
				allValues[label].values = values
				self.setState
					values: allValues
				, ->
					self.lineChart()
	addPattern: ->
		pattern = @state.pattern
		patterns = @state.patterns
		patterns.push pattern
		@setState
			patterns: patterns
			pattern: ""
		, ->
			@loadPattern pattern
	loadPattern: (pattern) ->
		@setValueSet "Location pattern: #{pattern}",
			type: "pattern"
			pattern: pattern
	loadGlobalValue: (name) ->
		@setValueSet @data[name],
			type: "global"
			name: name
	loadBrowser: (browser) ->
		@setValueSet "Browser: #{browser}",
			type: "browser"
			browser: browser
	loadBrowserVersion: (browser, version) ->
		label = "Browser: #{browser} #{version}"
		@setValueSet label,
			type: "browser-version"
			browser: browser
			version: version
	loadOS: (os) ->
		label = "OS: #{os}"
		@setValueSet label,
			type: "os"
			os: os
	loadDeviceCount: (type, deviceCount) ->
		if type is "overall"
			type = "device-count-overall"
			if deviceCount is 1
				label = "1 device overall"
			else
				label = "#{deviceCount} devices overall"
		else
			type = "device-count-coincident"
			if deviceCount is 1
				label = "1 device"
			else
				label = "#{deviceCount} devices"
		@setValueSet label,
			type: type
			deviceCount: deviceCount
	loadDeviceType: (deviceType) ->
		label = "#{deviceType} devices"
		@setValueSet label,
			type: "device-type"
			deviceType: deviceType
	loadUser: (user) ->
		label = "User: #{user}"
		@setValueSet label,
			type: "user"
			user: user
	loadDevice: (device) ->
		label = "Device: #{device}"
		@setValueSet label,
			type: "device"
			device: device
	loadLocation: (location) ->
		label = "Location: #{location}"
		@setValueSet label,
			type: "location"
			location: location
	refresh: ->
		@loadAllValues()
	view: (state) ->
		state = state or @state
		state.display
	pieChart: (buckets) ->

		colors = colorPairSeries Object.keys(buckets).length, 1

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

	barChart: (labels, values) ->
		colors = colorPairSeries Object.keys(values).length, 0.5

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
				highlightFill: lighter
				highlightStroke: color

			j++

		if @currentChart
			@currentChart.destroy()
		ctx = @timeline.getContext("2d")

		@chart = new Chart(ctx)
		@currentChart = @chart.Bar
			labels: labels
			datasets: datasets
		,
			multiTooltipTemplate: "<%= datasetLabel %> - <%= value %>"
	lineChart: ->
		log @state.values
		labels = @labels
		datasets = []
		if Object.keys(@state.values).length
			for label, data of @state.values
				[color, lighter] = data.color

				dataset =
					label: label
					data: data.values
					fillColor: lighter
					strokeColor: color
					pointColor: color
					pointStrokeColor: "white"
					pointHighlightStroke: color

				datasets.push dataset
		else
			datasets.push
				label: "No data"

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
	clearCache: ->
		Meteor.call 'clearCache', @props.appId, handleResult "Cache cleared"
	render: ->
		<div>
			<div className="row">
				<div className="col-xs-12">
					<h2>Timeline</h2>
				</div>
				<div className="col-xs-12">
					<div className="pull-right">
						<button className="btn btn-default" onClick={@refresh}>
							Refresh
						</button>
						&nbsp;
						<button className="btn btn-default" onClick={@clearCache}>
							Clear cache
						</button>
					</div>
				</div>
				<div className="col-xs-12 col-sm-4">
					<Templates.DateRangeInput id="range" label="Time range" from={@state.from} to={@state.to} ranges={@ranges} onChange={@updateRange("from","to", @loadAllValues)}/>
				</div>
				<div className="col-xs-12 col-sm-4">
					<Templates.Select id="display" label="Granularity" options={@granularities} value={@state.granularity} onChange={@updateValue('granularity', @loadAllValueSets)}/>
				</div>
				<div className="col-xs-12 col-sm-4">
					<Templates.Select id="display" label="Data" options={@displays} value={@state.display} onChange={@updateValue('display')}/>
				</div>
			</div>
			<div className="row">
				<div className="col-xs-12 col-sm-9">
					<div id="timeline-wrapper">
						<canvas id="timeline"></canvas>
					</div>
				</div>
				<div className="col-xs-12 col-sm-3">
					<h3>Filters</h3>
					{
						if @state.filters
							<ul>
								{
									for label, data of @state.filters
										<li key={label}>
											<a>{label}</a>
											&nbsp;
											<button className="btn btn-danger btn-xs" onClick={@wrap(@deleteFilter,label)}>
												<i className="fa fa-remove"></i>
											</button>
										</li>
								}
							</ul>
						else
							<p>No filters selected.</p>
					}
					<h3>Data</h3>
					{
						if Object.keys(@state.values).length
							<ul>
								{
									for label, data of @state.values
										<li key={label}>
											<a style={{color: data.color[0]}} title={label}>
												{cut(label, 25)}
											</a>
											&nbsp;
											<button className="btn btn-danger btn-xs" onClick={@wrap(@deleteValue,label)}>
												<i className="fa fa-remove"></i>
											</button>
										</li>
								}
							</ul>
						else
							<p>No data selected.</p>
					}
				</div>
			</div>
			<div className="row">
				<div className="col-xs-12 col-sm-3">
					<h3>Global data</h3>
					<ul className="activables">
						{
							for name, label of @data
								valuesLabel = @data[name]
								active = @state.values[valuesLabel]
								<li key={name}>
									<a className={if active then "active"} onClick={@wrap(@loadGlobalValue, name)}>
										{label}
									</a>
								</li>
						}
					</ul>
					<h3>Device types</h3>
					{
						if @state.deviceTypes
							<ul className="activables">
								{
									for deviceType, i in @state.deviceTypes
										label = "#{deviceType._id} devices"
										<li key={i}>
											<a onClick={@wrap(@loadDeviceType, deviceType._id)} className={if @state.values[label] then "active"}>
												{deviceType._id or "undefined"} ({deviceType.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
					<h3>Number of devices</h3>
					<div className="labels">
						{
							for name, label of @deviceCombinationsViews
								<label key={name} onClick={@wrap(@setView, 'deviceCombinations', name)} className={if @state.views.deviceCombinations is name then "active"}>{label}</label>
						}
					</div>
					{
						if @state.deviceCombinations
							<ul className="activables">
								{
									for deviceCount, i in @state.deviceCombinations
										if @state.views.deviceCombinations is "overall"
											if deviceCount._id is 1
												label = "1 device overall"
											else
												label = "#{deviceCount._id} devices overall"
										else
											if deviceCount._id is 1
												label = "1 device"
											else
												label = "#{deviceCount._id} devices"
										<li key={i} >
											<a onClick={@wrap(@loadDeviceCount, @state.views.deviceCombinations, deviceCount._id)} className={if @state.values[label] then "active"}>
												{deviceCount._id or "undefined"} ({deviceCount.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
				</div>
				<div className="col-xs-12 col-sm-3">
					<h3>Browsers</h3>
					<div className="labels">
						{
							for name, label of @browserViews
								<label key={name} onClick={@wrap(@setView, 'browsers', name)} className={if @state.views.browsers is name then "active"}>{label}</label>
						}
					</div>
					{
						if @state.browsers
							<ul className="activables">
								{
									for browser, i in @state.browsers
										label = "Browser: #{browser._id}"
										<li key={i} >
											<Templates.Dropdown>
												<a onClick={@wrap(@loadBrowser, browser._id)} className={if @state.values[label] then "active"}>
													{browser._id or "undefined"} ({browser.count})
												</a>
												<ul>
													{
														for version, j in browser.versions
															label = "Browser: #{browser._id} #{version.version}"
															<li key={j}>
																<a onClick={@wrap(@loadBrowserVersion, browser._id, version.version)} className={if @state.values[label] then "active"}>
																	{version.version or "undefined"}
																	({version.count})
																</a>
															</li>
													}
												</ul>
											</Templates.Dropdown>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
					<h3>Operating systems</h3>
					{
						if @state.oses
							<ul className="activables">
								{
									for os, i in @state.oses
										label = "OS: #{os._id}"
										<li key={i} >
											<a onClick={@wrap(@loadOS, os._id)} className={if @state.values[label] then "active"}>
												{os._id or "undefined"} ({os.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
				</div>
				<div className="col-xs-12 col-sm-3">
					<h3>Locations</h3>
					<div className="form-group">
						<div className="input-group">
							<input type="text" className="form-control" value={@state.pattern} onChange={@updateValue('pattern')} onKeyDown={@onEnter(@addPattern)} placeholder="Add a location (pattern)"/>
							<span className="input-group-btn">
								<button className="btn btn-primary" onClick={@addPattern}>
									<i className="fa fa-plus"></i>
								</button>
							</span>
						</div>
					</div>
					<ul className="activables">
						{
							for pattern, i in @state.patterns
								label = "Location pattern: #{pattern}"
								<li key={i}>
									<Templates.PatternView loadPattern={@loadPattern} pattern={pattern}
									active={@state.values[label]}/>
								</li>
						}
					</ul>
					{
						if @state.locations
							<ul className="activables">
								{
									for location, i in @state.locations
										label = "Location: #{location._id}"
										<li key={i}>
											<a onClick={@wrap(@loadLocation, location._id)} className={if @state.values[label] then "active"} title={location._id}>
												{cut(location._id,25)} ({location.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
				</div>
				<div className="col-xs-12 col-sm-3">
					<h3>Users</h3>
					<div className="labels">
						{
							for name, label of @userViews
								<label key={name} onClick={@wrap(@setView, "users", name)} className={if @state.views.users is name then "active"}>{label}</label>
						}
					</div>
					{
						if @state.users
							<ul className="activables">
								{
									for user, i in @state.users
										label = "User: #{user._id}"
										<li key={user._id}>
											<Templates.Dropdown>
												<a onClick={@wrap(@loadUser, user._id)} className={if @state.values[label] then "active"} title={user._id}>
													{cut(user._id,20) or "undefined"} ({user.count})
												</a>

												<ul className="activables">
													{
														for device, j in user.devices
															label = "Device: #{device.id}"
															<li key={j}>
																<a onClick={@wrap(@loadDevice, device.id)} className={if @state.values[label] then "active"} title={device.id}>
																	{cut(device.id,20) or "undefined"} ({device.count})
																</a>
															</li>
													}
												</ul>
											</Templates.Dropdown>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
				</div>
			</div>
		</div>

colorPair = (alpha) ->
		color = [Math.floor(Math.random()*256), Math.floor(Math.random()*256), Math.floor(Math.random()*256)]

		lighten = 20

		highlight = [Math.min(color[0] + lighten, 255), Math.min(color[1] + lighten, 255), Math.min(color[2] + lighten, 255)]

		[rgba(color), rgba(highlight, alpha)]

colorPairSeries = (amount, alpha) ->

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
		colors[i] = [rgba(color), rgba(highlight, alpha)]
		i++

	colors

rgba = (color, alpha) ->
	if !alpha?
		alpha = 1
	"rgba(#{Math.floor(color[0])},#{Math.floor(color[1])},#{Math.floor(color[2])},#{alpha})"

cut = (string, length) ->
	if string.length < length
		string
	else
		"#{string[0...length/2]}...#{string[-length/2..]}"

Templates.DataView = React.createClass
	render: ->
		label = @props.label
		data = @props.data
		<Templates.Dropdown>
			<a style={{color: data.color[0]}} title={label}>
				{cut(label, 30)}
			</a>
			<div>
				<button className="btn btn-danger btn-xs" onClick={@props.onRemove}>
					Remove
				</button>
			</div>
		</Templates.Dropdown>

Templates.PatternView = React.createClass
	mixins: [ReactUtils]
	getInitialState: ->
		users: null
	loadUsers: ->
		Meteor.call 'getAggregatedValues', @props.appId, "users", @props.from, @props.to, {}, handleResult null, (r) ->
			@setState
				users: r
	render: ->
		pattern = @props.pattern
		<Templates.Dropdown>
			<a onClick={@wrap(@props.loadPattern, pattern)} className={if @props.active then "active"}>
				{pattern}
			</a>
			<ul className="activables">
				<li>
					<Templates.Dropdown onOpen={@loadUsers}>
						<a>Users</a>
						{
							if @state.users
								<ul>
									{
										for user in @state.users
											label = "User visits for user #{user._id} and pattern #{pattern}"
											<li key={user._id}>
												<a>
													{user}
												</a>
											</li>
									}
								</ul>
							else
								<Templates.Loading/>
						}
					</Templates.Dropdown>
				</li>
				<li>
					<a>Devices</a>
				</li>
			</ul>
		</Templates.Dropdown>
