Templates.Apps = React.createClass
	mixins: [ReactMeteorData]
	getInitialState: ->
		name: ""
	getMeteorData: ->
		handle = Meteor.subscribe 'apps'
		ready: handle.ready()
		apps: Apps.find().fetch()
	createApp: (e) ->
		e.preventDefault()
		Apps.insert
			name: @state.name
			description: @state.description
		, handleResult("App created")
	updateName: (e) ->
		@setState
			name: e.currentTarget.value
	updateDescription: (e) ->
		@setState
			description: e.currentTarget.value
	render: ->
		<article className="container">
			<div className="row">
				<div className="col-xs-12">
					<h1>Apps</h1>
					<p>Here you can manage your apps.</p>
				</div>
				<div className="col-xs-12 col-md-4">
					<h2>Create an app</h2>
					<form onSubmit={@createApp}>
						<div className="form-group">
							<label htmlFor="name">Name</label>
							<input id="name" value={@state.name} onChange={@updateName} placeholder="E.g. XD-Blog" className="form-control" />
						</div>
						<div className="form-group">
							<label htmlFor="description">Description</label>
							<textarea id="content" name="content" placeholder="E.g. My awesome cross-device blog" rows="5" className="form-control" onChange={@updateDescription}>
								{@state.description}
							</textarea>
						</div>
						<button type="submit" className="btn btn-primary">Create</button>
					</form>
				</div>
				<div className="col-xs-12 col-md-6">
					<h2>Your apps</h2>
					{
						if @data.apps
							<ul>
								{
									for app, i in @data.apps
										<li key={i}>
											<a href={"/apps/#{app._id}"}>{app.name}</a>
											<span style={{color: "gray"}}> &mdash; ({app._id}, {app.apiKey})</span>
										</li>
								}
							</ul>
						else if @data.ready
							<p>No apps found.</p>
						else
							<Templates.Loading />
					}
				</div>
			</div>
		</article>
