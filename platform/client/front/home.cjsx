Templates.Home = React.createClass
	mixins: [ReactMeteorData]
	getMeteorData: ->
		user: Meteor.user()
	render: ->
		<article className="container">
			<div className="row">
				<div className="col-xs-12">
					<h1 className="page-header">Welcome to the XD-Analytics Framework</h1>
					<p>With this framework you can analyse your Cross-Device applications.</p>
				</div>
			</div>
			<div className="row">
				<div className="col-xs-12">
					{
						if @data.user
							<div className="text-center">
								<a href="/apps" className="btn btn-primary btn-lg">Manage your apps</a>
							</div>
						else
							<div className="text-center">
								<a href="/register" className="btn btn-primary btn-lg">Register now</a>
								<p>Already have an account? <a href="/login">Log in</a></p>
							</div>
					}
				</div>
			</div>
		</article>
