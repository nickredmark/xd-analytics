
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
	views:
		logs: "Events"
		users: "Users"
		devices: "Devices"
		sessions: "Sessions"
		deviceTypes: "Device types"
		browsers: "Browsers"
		browserVersions: "Browser versions"
		oses: "Operating systems"
		locations: "Unique locations"
	granularities:
		auto: "Auto"
		day: "Day"
		week: "Week"
		month: "Month"
		global: "Global"
	logTypes:
		view: "View"
		login: "Log in"
		logout: "Log out"
	browserViews:
		views: "By views"
		devices: "By devices"
		versions: "By versions"
	userViews:
		views: "By views"
		devices: "By devices"
	deviceCombinationsViews:
		coincident: "Coincident"
		overall: "Overall"
	timeline: null
	chart: null
	currentChart: null
	labels: []

	getInitialState: ->
		from: moment().startOf('day').subtract(7, 'days').toDate()
		to: moment().endOf('day').subtract(1, 'days').toDate()
		granularity: 'auto'

		# Filter lists
		locations: null
		browsers: null
		oses: null
		users: null
		deviceCombinations: null
		deviceTypes: null
		pattern: ""
		patterns: []

		values: {}

		view: "logs"

		views:
			users: "views"
			browsers: "views"
			deviceCombinations: "coincident"

		filters:
			logType: "view"

	addDataset: ->
		label = @views[@state.view]
		parts = for key, value of @state.filters
			"#{key}: #{value}"
		if parts.length
			label += " (#{parts.join(", ")})"
		options = {}
		for key, value of @state.filters
			options[key] = value
		data =
			view: @state.view
			options: options
		@setValueSet label, data
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
	componentDidMount: ->
		@timeline = document.getElementById("timeline")
		@addDataset()
		@loadAllValues()
	setView: (name, value) ->
		self = @
		set = {}
		set.views = @state.views
		set.views[name] = value
		@setState set
		, ->
			self.loadValues name, "#{name}-#{value}"
	loadAllDatasets: ->
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
		@loadAllDatasets()
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
		view = data.view
		options = data.options
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
	loadPattern: (pattern) ->
		@setValueSet "Location pattern: #{pattern}",
			type: "pattern"
			pattern: pattern
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
		@loadAllDatasets()
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
	setBrowserVersion: (browser, browserVersion)->
		filters = @state.filters
		if filters.browser is browser and filters.browserVersion is browserVersion
			delete(filters.browserVersion)
		else
			filters.browser = browser
			filters.browserVersion = browserVersion
		@setState
			filter: filters
	render: ->
		<div>
			<div>
				<div className="col-xs-12">
					<h2>Timeline</h2>
				</div>
				<div className="col-xs-12 col-sm-4">
					<Templates.DateRangeInput id="range" label="Time range" from={@state.from} to={@state.to} ranges={@ranges} onChange={@updateRange("from","to", @loadAllValues)}/>
				</div>
				<div className="col-xs-12 col-sm-4">
					<Templates.Select id="granularity" label="Granularity" options={@granularities} value={@state.granularity} onChange={@updateValue('granularity', @loadAllDatasets)}/>
				</div>
				<div className="col-xs-12 col-sm-4">
					<button className="btn btn-default" onClick={@refresh}>
						Refresh
					</button>
					&nbsp;
					<button className="btn btn-default" onClick={@clearCache}>
						Clear cache
					</button>
				</div>
			</div>
			<div>
				<div className="col-xs-12 col-sm-9">
					<div id="timeline-wrapper">
						<canvas id="timeline" height="50"></canvas>
					</div>
				</div>
				<div className="col-xs-12 col-sm-3">
					<h3>Data</h3>
					{
						if Object.keys(@state.values).length
							<ul>
								{
									for label, data of @state.values
										<li key={label}>
											<a style={{color: data.color[0]}} title={label}>
												{label}
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
			<div>
				<div className="col-xs-12">
					<h3>Select data</h3>
					<button onClick={@addDataset} className="btn btn-primary pull-right">
						Add
					</button>
					<div className="labels">
						{
							for name, label of @views
								<label key={name} className={"#{if @state.view is name then "active"}"} onClick={@setValue('view',name)}>{label}</label>
						}
					</div>
				</div>
			</div>
			<div>
				<div className="col-xs-12">
					<h3>Filter data</h3>
				</div>
			</div>
			<div>
				<div className="col-xs-12 col-sm-3 col-lg-2">
					<h4>Event types</h4>
					<ul className="activables">
						{
							for logType, label of @logTypes
								<li key={logType}>
									<a onClick={@toggleDictValue("filters", "logType", logType)} className={if @state.filters.logType is logType then "active"}>{label}</a>
								</li>
						}
					</ul>
					<h4>Device types</h4>
					{
						if @state.deviceTypes
							<ul className="activables">
								{
									for deviceType, i in @state.deviceTypes
										<li key={i}>
											<a onClick={@toggleDictValue("filters", "deviceType", deviceType._id)} className={if @state.filters.deviceType is deviceType._id then "active"}>
												{deviceType._id or "undefined"} ({deviceType.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
					<h4>Number of devices</h4>
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
										active = false
										if @state.views.deviceCombinations is "overall"
											field = "deviceCount"
										else
											field = "coincidentDeviceCount"
										if @state.filters[field] is deviceCount._id
											active = true
										<li key={i} >
											<a onClick={@toggleDictValue("filters", field, deviceCount._id)} className={if active then "active"}>
												{deviceCount._id or "undefined"} ({deviceCount.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
				</div>
				<div className="col-xs-12 col-sm-3 col-lg-2">
					<h4>Browsers</h4>
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
										<li key={i} >
											<Templates.Dropdown>
												<a onClick={@toggleDictValue("filters", "browser", browser._id)} className={if @state.filters.browser is browser._id then "active"}>
													{browser._id or "undefined"} ({browser.count})
												</a>
												<ul>
													{
														for version, j in browser.versions
															<li key={j}>
																<a onClick={@wrap(@setBrowserVersion,browser._id, version.version)} className={if @state.filters.browser is browser._id and @state.filters.browserVersion is version.version then "active"}>
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
					<h4>Operating systems</h4>
					{
						if @state.oses
							<ul className="activables">
								{
									for os, i in @state.oses
										<li key={i} >
											<a onClick={@toggleDictValue("filters", "os", os._id)} className={if @state.filters.os is os._id then "active"}>
												{os._id or "undefined"} ({os.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
				</div>
				<div className="col-xs-12 col-sm-3 col-lg-2">
					<h4>Locations</h4>
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
								<li key={i}>
									<a onClick={@toggleDictValue("filters", "locationPattern", pattern)} className={if @state.filters.locationPattern is pattern then "active"}>
										{pattern}
									</a>
								</li>
						}
					</ul>
					{
						if @state.locations
							<ul className="activables">
								{
									for location, i in @state.locations
										<li key={i}>
											<a onClick={@toggleDictValue("filters", "location", location._id)} className={if @state.filters.location is location._id then "active"} title={location._id}>
												{cut(location._id,25)} ({location.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
				</div>
				<div className="col-xs-12 col-sm-3 col-lg-2">
					<h4>Users</h4>
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
										<li key={user._id}>
											<Templates.Dropdown>
												<a onClick={@toggleDictValue("filters", "user", user._id)} className={if @state.filters.user is user._id then "active"} title={user._id}>
													{cut(user._id,20) or "undefined"} ({user.count})
												</a>

												<ul className="activables">
													{
														for device, j in user.devices
															<li key={j}>
																<a onClick={@toggleDictValue("filters", "device", device.id)} className={if @state.filters.device is device.id then "active"} title={device.id}>
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
