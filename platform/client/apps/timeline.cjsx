Views.Timeline = React.createClass
	mixins: [ReactUtils]
	modes:
		global: "Global"
		user: "User"
		device: "Device"
	displays:
		global:
			general: "General"
			timeOnline: "Time online"
			timeOnlineByDeviceType: "Time online by device type"
			averageTimeOnline: "Average time online"
			devicesPerUser: "Users by number of devices"
			uniquePages: "Unique page views"
			deviceTypes: "Device types"
			deviceTypeCombinations: "Device type combinations"
	data:
		users: "Users"
		devices: "Devices"
		logs: "Logs"
		views: "Views"
		logins: "Logins"
		logouts: "Logouts"
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
	timeline: null
	chart: null
	currentChart: null
	labels: []
	values: {}
	getInitialState: ->
		from: moment().subtract(6, 'days').toDate()
		to: new Date()
		granularity: 'auto'
		mode: 'global'
		display:
			global: 'general'
		data:
			users: true

		visibleData: {}
		visibleView: null
		visibleFrom: null
		visibleTo: null
		visibleGranularity: null

		activeUsers: {}
		activeDevices: {}
		activeBrowsers: {}
		activeBrowserVersions: {}
		activeLocations: {}
		activeOSes: {}

		locations: null
		browsers: null
		oses: null
		users: null

		userView: "views"
		browserView: "views"

		locationSubstrings: null

		pattern: ""
		patterns: []
	componentDidMount: ->
		@timeline = document.getElementById("timeline")
		@loadAllValues()
	#componentDidUpdate: (prevProps, prevState) ->
		#if !@visibleStateUpToDate()
			#@load()
	updateVisibleState: ->
		@setState
			visibleView: @view()
			visibleFrom: @state.from
			visibleTo: @state.to
			visibleGranularity: @state.granularity
	visibleStateUpToDate: ->
		visible = @view() == @state.visibleView and @state.from == @state.visibleFrom and @state.to == @state.visibleTo and @state.granularity == @state.visibleGranularity
	loadAllValues: ->
		log "Load all values"
		self = @
		for name, active of @state.data
			@loadValue name
		for name, active of @state.activeLocations
			@loadLocation name
		for name, active of @state.activeBrowsers
			@loadBrowser name
		for name, active of @state.activeOSes
			@loadOS name
		for name, active of @state.activeUsers
			@loadUser name
		for name, active of @state.activeDevices
			@loadDevice name
		@loadBrowsers()
		@loadLocations()
		@loadUsers()
		@loadOSes()
	loadLocations: ->
		self = @
		Meteor.call 'getAggregatedValues', @props.appId, "locations", @state.from, @state.to, handleResult null, (r) ->
			self.setState
				locations: r
	loadUsers: ->
		self = @
		Meteor.call 'getAggregatedValues', @props.appId, "users-#{@state.userView}", @state.from, @state.to, handleResult null, (r) ->
			self.setState
				users: r
	loadOSes: ->
		self = @
		Meteor.call 'getAggregatedValues', @props.appId, "oses", @state.from, @state.to, handleResult null, (r) ->
			self.setState
				oses: r
	loadBrowsers: ->
		self = @
		Meteor.call 'getAggregatedValues', @props.appId, "browsers-#{@state.browserView}", @state.from, @state.to, handleResult null, (r) ->
			self.setState
				browsers: r
	loadValue: (name) ->
		self = @
		if @state.data[name]
			Meteor.call 'getAnalyticsValues', @props.appId, name, @state.from, @state.to, {}, @state.granularity, handleResult null, (r) ->
				[labels, values] = r
				self.labels = labels
				self.values[self.data[name]] = values
				self.lineChart()
		else
			delete(@values[@data[name]])
			self.lineChart()
	loadBrowser: (browser) ->
		self = @
		if @state.activeBrowsers[browser]
			Meteor.call 'getAnalyticsValues', @props.appId, "browser", @state.from, @state.to, {browser: browser}, @state.granularity, handleResult null, (r) ->
				[labels, values] = r
				self.labels = labels
				self.values["Browser: #{browser}"] = values
				self.lineChart()
		else
			delete(@values["Browser: #{browser}"])
			self.lineChart()
	loadBrowserVersion: (browser, version) ->
		key = "#{browser} #{version}"
		self = @
		if @state.activeBrowserVersions[key]
			Meteor.call 'getAnalyticsValues', @props.appId, "browser-version", @state.from, @state.to, {browser: browser, version: version}, @state.granularity, handleResult null, (r) ->
				[labels, values] = r
				self.labels = labels
				self.values["Browser: #{browser} #{version}"] = values
				self.lineChart()
		else
			delete(@values["Browser: #{browser} #{version}"])
			self.lineChart()
	loadOS: (os) ->
		self = @
		if @state.activeOSes[os]
			Meteor.call 'getAnalyticsValues', @props.appId, "os", @state.from, @state.to, {os: os}, @state.granularity, handleResult null, (r) ->
				[labels, values] = r
				self.labels = labels
				self.values["OS: #{os}"] = values
				self.lineChart()
		else
			delete(@values["OS: #{os}"])
			self.lineChart()
	loadUser: (user) ->
		self = @
		if @state.activeUsers[user]
			Meteor.call 'getAnalyticsValues', @props.appId, "user", @state.from, @state.to, {user: user}, @state.granularity, handleResult null, (r) ->
				[labels, values] = r
				self.labels = labels
				self.values["User: #{user}"] = values
				self.lineChart()
		else
			delete(@values["User: #{user}"])
			self.lineChart()
	loadDevice: (device) ->
		self = @
		if @state.activeDevices[device]
			Meteor.call 'getAnalyticsValues', @props.appId, "device", @state.from, @state.to, {device: device}, @state.granularity, handleResult null, (r) ->
				[labels, values] = r
				self.labels = labels
				self.values["Device: #{device}"] = values
				self.lineChart()
		else
			delete(@values["Device: #{device}"])
			self.lineChart()
	loadLocation: (location) ->
		self = @
		if @state.activeLocations[location]
			Meteor.call 'getAnalyticsValues', @props.appId, "location", @state.from, @state.to, {location: location}, @state.granularity, handleResult null, (r) ->
				[labels, values] = r
				self.labels = labels
				self.values["Location: #{location}"] = values
				self.lineChart()
		else
			delete(@values["Location: #{location}"])
			self.lineChart()
	refresh: ->
		@loadAllValues()
	view: (state) ->
		state = state or @state
		"#{state.mode}-#{state.display[state.mode]}"
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
		labels = @labels
		datasets = []
		log @values
		for label, values of @values
			[color, lighter] = colorPair 0.5

			dataset =
				label: label
				data: values
				fillColor: lighter
				strokeColor: color
				pointColor: color
				pointStrokeColor: "white"
				pointHighlightStroke: color

			datasets.push dataset

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
	addPattern: ->
		patterns = @state.patterns
		patterns.push @state.pattern
		@setState
			patterns: patterns
			pattern: ""
	render: ->
		<div>
			<div className="col-xs-12">
				<h2>Timeline</h2>
			</div>
			<div className="col-xs-12">
				<div className="pull-right">
					<button className="btn btn-default" onClick={@refresh}>
						Refresh
					</button>
					{" "}
					<button className="btn btn-default" onClick={@clearCache}>
						Clear cache
					</button>
				</div>
			</div>
			<div className="col-xs-12 col-sm-6">
				<Templates.DateRangeInput id="range" label="Time range" from={@state.from} to={@state.to} onChange={@updateRange("from","to",@loadAllValues)}/>
				<Templates.Select id="display" label="Granularity" options={@granularities} value={@state.granularity} onChange={@updateValue('granularity')}/>
			</div>
			<div className="col-xs-12 col-sm-6">
				<Templates.Select id="mode" label="Mode" options={@modes} value={@state.mode} onChange={@updateValue('mode')}/>
				<Templates.Select id="display" label="Data" options={@displays[@state.mode]} value={@state.display[@state.mode]} onChange={@updateDictValue('display', @state.mode)}/>
			</div>
			<div className="col-xs-12">
				<div className="labels">
					{
						for name, label of @data
							active = @state.data[name]
							<label key={name} className={if active then "active"} onClick={@toggleDictBoolean("data", name, @wrap(@loadValue, name))}>{label}</label>
					}
				</div>
			</div>
			<div className="col-xs-12">
				<div id="timeline-wrapper">
					<canvas id="timeline"></canvas>
				</div>
			</div>
			<div className="col-xs-12 col-sm-3">
				<h3>Locations</h3>
				<div className="form-group">
					<div className="input-group">
						<input key={i} type="text" className="form-control" value={pattern} onChange={@updateDictValue('patterns', i)}/>
						<button className="input-group-addon btn btn-main" onClick={@addPattern}><i className="fa fa-plus"></i></button>
					</div>
				</div>
				{
					if @state.patterns
						<ul>
							{
								for pattern, i in @state.patterns
									<li key={i}>{pattern}</li>
							}
						</ul>
				}
				{
					if @state.locations
						<ul className="activables">
							{
								for location, i in @state.locations
									<li key={i}>
										<a onClick={@toggleDictBoolean("activeLocations", location._id, @wrap(@loadLocation, location._id))} className={if @state.activeLocations[location._id] then "active"} title={location._id}>
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
				<h3>Browsers</h3>
				<div className="labels">
					{
						for name, label of @browserViews
							<label key={name} onClick={@setValue('browserView', name, @loadBrowsers)} className={if @state.browserView is name then "active"}>{label}</label>
					}
				</div>
				{
					if @state.browsers
						<ul className="activables">
							{
								for browser, i in @state.browsers
									<li key={i} >
										<Templates.Dropdown>
											<a onClick={@toggleDictBoolean("activeBrowsers", browser._id, @wrap(@loadBrowser, browser._id))} className={if @state.activeBrowsers[browser._id] then "active"}>
												{browser._id or "undefined"} ({browser.count})
											</a>
											<ul>
												{
													for version, j in browser.versions
														key = "#{browser._id} #{version.version}"
														<li key={j}>
															<a onClick={@toggleDictBoolean("activeBrowserVersions", key, @wrap(@loadBrowserVersion, browser._id, version.version))} className={if @state.activeBrowserVersions[key] then "active"}>
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
			</div>
			<div className="col-xs-12 col-sm-3">
				<h3>Operating systems</h3>
				{
					if @state.oses
						<ul className="activables">
							{
								for os, i in @state.oses
									<li key={i} >
										<a onClick={@toggleDictBoolean("activeOSes", os._id, @wrap(@loadOS, os._id))} className={if @state.activeOSes[os._id]then "active"}>
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
				<h3>Users</h3>
				<div className="labels">
					{
						for name, label of @userViews
							<label key={name} onClick={@setValue('userView', name, @loadUsers)} className={if @state.userView is name then "active"}>{label}</label>
					}
				</div>
				{
					if @state.users
						<ul className="activables">
							{
								for user, i in @state.users
									<li key={user._id}>
										<Templates.Dropdown>
											<a onClick={@toggleDictBoolean("activeUsers", user._id, @wrap(@loadUser, user._id))} className={if @state.activeUsers[user._id]then "active"} title={user._id}>
												{cut(user._id,20) or "undefined"} ({user.count})
											</a>

											<ul className="activables">
												{
													for device, j in user.devices
														<li key={j}>
															<a onClick={@toggleDictBoolean("activeDevices", device.id, @wrap(@loadDevice, device.id))} className={if @state.activeDevices[device.id]then "active"} title={device.id}>
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
	if string < length
		string
	else
		"#{string[0...length/2]}...#{string[-length/2..]}"
