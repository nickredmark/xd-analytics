

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
		timeOnline: "Time online"
		averageTimeOnline: "Average time online"
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
	logTypes:
		view: "View"
		connected: "Connected"
		location: "Location"
		login: "Log in"
		logout: "Log out"
		update: "Update"
		online: "Online"
		"user-detected": "User detected"
	browserViews:
		views: "views"
		devices: "devices"
		versions: "versions"
	userViews:
		combinedViews: "combined views"
		combinedTimeOnline: "combined time online"
		combinedDevices: "combined devices"
		views: "views"
		timeOnline: "time online"
		devices: "devices"
	locationViews:
		combinedViews: "combined views"
		views: "views"
	deviceCombinationViews:
		users: "users"
		views: "views"
	timeline: null
	chart: null
	currentChart: null
	labels: []
	deviceTypes: ["sm", "md", "lg", "xl"]

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
		deviceTypeCombinations: null
		pattern: ""
		patterns: []

		values: {}

		view: "logs"

		views:
			users: "combinedViews"
			browsers: "views"
			locations: "combinedViews"
			deviceCombinations: "users"

		filters:
			logType: "view"

	filterValueLabel: (key, value) ->
		switch key
			when "deviceType"
				value = @deviceTypes[value-1]
			when "deviceTypeCombination"
				combination = for type in value
					@deviceTypes[type-1]
				value = combination.join("-")
		value

	currentSelectionLabel: ->
		label = @views[@state.view]
		parts = []
		for key, value of @state.filters
			value = @filterValueLabel key, value
			parts.push "#{key}: #{value}"
		if parts.length
			label += " (#{parts.join(", ")})"

		label
	addDataset: ->
		options = {}
		for key, value of @state.filters
			options[key] = value
		data =
			view: @state.view
			options: options
		@setValueSet @currentSelectionLabel(), data
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
		@loadValues "deviceTypes"
		@loadValues "deviceCombinations", "deviceCombinations-#{@state.views.deviceCombinations}"
		@loadValues "deviceTypeCombinations"
		@loadValues "browsers", "browsers-#{@state.views.browsers}"
		@loadValues "oses"
		@loadValues "locations", "locations-#{@state.views.locations}"
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
			multiTooltipTemplate: (valuesObject) ->
				"#{cut(valuesObject.datasetLabel, 30)} - #{valuesObject.value}"
			bezierCurve: false
	clearCache: ->
		Meteor.call 'clearCache', @props.appId, handleResult "Cache cleared"
	setBrowser: (browser) ->
		filters = @state.filters
		if filters.browser is browser
			delete(filters.browser)
		else
			filters.browser = browser
		delete(filters.browserVersion)
		@setState
			filters: filters
	setBrowserVersion: (browser, browserVersion)->
		filters = @state.filters
		if filters.browser is browser and filters.browserVersion is browserVersion
			delete(filters.browserVersion)
		else
			filters.browser = browser
			filters.browserVersion = browserVersion
		@setState
			filters: filters
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
						<canvas id="timeline" height="80"></canvas>
					</div>
				</div>
				<div className="col-xs-12 col-sm-3">
					<h3>Data</h3>
					<h4>Current</h4>
					{
						if Object.keys(@state.values).length
							<ul>
								{
									for label, data of @state.values
										<li key={label}>
											{
												if data.values
													total = 0
													for value in data.values
														total += value
													if data.view is "averageTimeOnline"
														total /= data.values.length
													<span style={{color: data.color[0]}}>
														{condFixed(total)}
														&nbsp;
													</span>
												else
													<span>
														<Templates.Spinner/>
														&nbsp;
													</span>
											}
											<span style={{color: data.color[0]}} title={label}>
												{label}
											</span>
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
					<h4>Selection</h4>
					<span>{@views[@state.view]}</span>
					<ul>
						{
							for key, value of @state.filters
								<li key={key}>
									<span>{key}: {@filterValueLabel(key, value)}</span>
									&nbsp;
									<button onClick={@unsetDictValue("filters", key)} className="btn btn-danger btn-xs">
										<i className="fa fa-remove"></i>
									</button>
								</li>
						}
					</ul>
					{
						if @state.values[@currentSelectionLabel()]
							<button onClick={@addDataset} className="btn btn-primary btn-md">
								Remove from data
							</button>
						else
							<button onClick={@addDataset} className="btn btn-primary btn-md">
								Add to data
							</button>
					}
				</div>
			</div>
			<div>
				<div className="col-xs-12">
					<h3>Select</h3>
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
					<h3>Filter</h3>
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
				</div>
				<div className="col-xs-12 col-sm-3 col-lg-2">
					<h3>Devices</h3>
					<h4>Types</h4>
					{
						if @state.deviceTypes
							<ul className="activables">
								{
									for deviceType, i in @state.deviceTypes
										<li key={i}>
											<a onClick={@toggleDictValue("filters", "deviceType", deviceType._id)} className={if @state.filters.deviceType is deviceType._id then "active"}>
												{@deviceTypes[deviceType._id-1] or "undefined"} ({deviceType.count} devices)
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
					<h4>Amount</h4>
					<div className="labels">
						Sort by
						{
							for name, label of @deviceCombinationViews
								<label key={name} onClick={@wrap(@setView, 'deviceCombinations', name)} className={if @state.views.deviceCombinations is name then "active"}>{label}</label>
						}
					</div>
					{
						if @state.deviceCombinations
							<ul className="activables">
								{
									for deviceCount, i in @state.deviceCombinations
										active = false
										if @state.filters.deviceCount is deviceCount._id
											active = true
										<li key={i} >
											<a onClick={@toggleDictValue("filters", "deviceCount", deviceCount._id)} className={if active then "active"}>
												{deviceCount._id or "undefined"} ({deviceCount.count})
											</a>
										</li>
								}
							</ul>
						else
							<Templates.Loading/>
					}
					<h4>Combinations</h4>
					{
						if @state.deviceTypeCombinations
							if @state.filters.deviceTypeCombination
								activeCombination = for type in @state.filters.deviceTypeCombination
									@deviceTypes[type-1]
								activeLabel = activeCombination.join(", ")
							<ul className="activables">
								{
									for deviceTypeCombination, i in @state.deviceTypeCombinations
										combination = for type in deviceTypeCombination._id
											@deviceTypes[type-1]
										label = combination.join(", ")
										<li key={i}>
											<a className={if label is activeLabel then "active"} onClick={@toggleDictValue("filters", "deviceTypeCombination", deviceTypeCombination._id)}>
												{label or "undefined"} ({deviceTypeCombination.count} users)
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
						sort by
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
												<a onClick={@wrap(@setBrowser,browser._id)} className={if @state.filters.browser is browser._id then "active"}>
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
												{os._id or "undefined"} ({os.count} devices)
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
					<div className="labels">
						sort by
						{
							for name, label of @locationViews
								<label key={name} onClick={@wrap(@setView, "locations", name)} className={if @state.views.locations is name then "active"}>{label}</label>
						}
					</div>
					{
						if @state.locations
							<ul className="activables">
								{
									for location, i in @state.locations
										active = @state.filters.location is location._id
										<li key={i}>
											<a onClick={@toggleDictValue("filters", "location", location._id)} className={if  active then "active"} title={location._id}>
												{if active then location._id else cut(location._id,25)} ({location.count} views)
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
						sort by
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
										active = @state.filters.user is user._id
										switch @state.views.users
											when "timeOnline", "combinedTimeOnline"
												count = formatInterval user.count
											else
												count = user.count
										<li key={user._id}>
											<Templates.Dropdown>
												<a onClick={@toggleDictValue("filters", "user", user._id)} className={if active then "active"} title={user._id}>
													{if active then user._id else cut(user._id,20) or "undefined"} ({count})
												</a>

												{
													if user.devices
														<ul className="activables">
															{
																for device, j in user.devices
																	active = @state.filters.device is device.id
																	switch @state.views.users
																		when "timeOnline", "combinedTimeOnline"
																			count = formatInterval device.count
																		else
																			count = device.count
																	<li key={j}>
																		<a onClick={@toggleDictValue("filters", "device", device.id)} className={if active then "active"} title={device.id}>
																			{if active then device.id else cut(device.id,20) or "undefined"} ({count})
																		</a>
																	</li>
															}
														</ul>
												}
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

formatInterval = (ms) ->
	if ms < 1000
		return "#{ms} ms"
	ms /= 1000

	if ms < 60
		return "#{ms.toFixed(1)} s"
	ms /= 60

	if ms < 60
		return "#{ms.toFixed(1)} m"
	ms /= 60

	if ms < 24
		return "#{ms.toFixed(1)} h"
	ms /= 24

	if ms < 365
		return "#{ms.toFixed(1)} d"

	ms /= 365
	return "#{ms.toFixed(1)} y"

condFixed = (n) ->
	if Math.floor(n) isnt n
		n.toFixed(1)
	else
		n
