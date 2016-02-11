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
			<div>
				{
					if @data.ready
						<Views.Timeline appId={@props.appId}/>
					else
						<Templates.Loading/>
				}
			</div>
		</article>
