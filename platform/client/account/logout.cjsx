Templates.Logout = React.createClass
	mixins: [ReactMeteorData]
	getMeteorData: ->
		user: Meteor.user()
	componentDidMount: ->
		Meteor.logout()
	render: ->
		if Meteor.userId()
			<div className="container">
				<h1 className="page-header">One second</h1>
				<p>You are being logged out...</p>
			</div>
		else
			<div className="container">
				<h1 className="page-header">Goodbye!</h1>
				<p>You have been logged out.</p>
			</div>
