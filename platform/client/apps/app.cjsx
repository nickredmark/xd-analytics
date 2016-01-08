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

		ready: handle.ready()
		app: app
	view: ->
		if @props.view then @props.view else "overview"
	viewUrl: (view) ->
		if view is "overview"
			"/apps/#{@props.appId}"
		else
			"/apps/#{@props.appId}/#{view}"
	render: ->
		<article>
			{
				if @data.ready
					if @data.app
						<div>
							<div className="col-xs-12">
								<h1>{@data.app.name}</h1>
								<p>{@data.app.description}</p>
							</div>
						</div>
					else
						<div>
							<div className="col-xs-12">
								<h1>Not found</h1>
								<p>This app doesn't exist. <a href="/apps">Back to your apps</a>.</p>
							</div>
						</div>
				else
					<div>
						<div className="col-xs-12">
							<h1>Loading App<Templates.Ellipsis/></h1>
						</div>
					</div>
			}
			{
				if not @data.ready or @data.app
					<div>
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
			<div>
				{
					if @data.ready
						switch @view()
							when "overview"
								<Views.Overview app={@data.app}/>
							when "timeline"
								<Views.Timeline appId={@props.appId}/>
							when "devices"
								<Views.Devices appId={@props.appId}/>
							when "logs"
								<Views.Logs/>
					else
						<Templates.Loading/>
				}
			</div>
		</article>

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
					{@props.devices?.length}
				</div>
				<div>
					<label>Number of log entries:&nbsp;</label>
					{@props.logs?.length}
				</div>
			</div>
		</div>

Views.Logs = React.createClass
	render: ->
		<div className="col-xs-12">
			<h2>Logs</h2>
			{
				if @props.logs?.length
					<Templates.Table headers={["Logged at", "Device, Session", "Device", "User ID", "Location", "Type", "Comment"]}>
						{
							for l, i in @props.logs
								<tr key={i}>
									<td>{moment(l.loggedAt).format('YYYY-MM-DD HH:mm:ss:SSS')}</td>
									<td>
										{l.device.id}, {l.device.sessionId}
										{
											if l.device.noStorage
												<span>No storage</span>
										}
									</td>
									<td>{l.device.os}, {l.device.browser}, {l.device.browserVersion}, {l.device.type} ({l.device.width}x{l.device.height}, {l.device.pixelRatio}) </td>
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
